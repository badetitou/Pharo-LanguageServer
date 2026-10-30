"
I am the server. 
I also include all the pharo language features.

Methods in `lsp` protocol are standard language server protocol feature.

Methods in `pls` protocol are pharo language server feature.
"
Class {
	#name : 'PLSServer',
	#superclass : 'PLSAbstractServer',
	#instVars : [
		'envProjectPackages',
		'envChanges',
		'envChangesMutex',
		'envChangesReady',
		'envFlushProcess',
		'envFirstChangeTime',
		'envLastChangeTime',
		'envOverflow'
	],
	#category : 'PharoLanguageServer',
	#package : 'PharoLanguageServer'
}

{ #category : 'pls - variables' }
PLSServer >> childrenVariables: variableReference in: textDocument [

	<jrpc: #'pls:childrenVariables'>
	| document references currentVariable |
	document := self context textItem: (textDocument at: #uri at: #path).
	references := Stack newFrom: (variableReference substrings: '/').
	currentVariable := document binder bindings at: references pop.
	[ references isEmpty ] whileFalse: [
		| goTo |
		goTo := references pop.
		currentVariable := currentVariable instVarNamed: goTo asSymbol ].
	^ (currentVariable class allInstVarNames collectWithIndex: [ :name :idx |
		   PLSVariable new
			   name: name;
			   value: (currentVariable instVarAt: idx) printString;
			   variableReference: variableReference , '/' , name;
			   isDirectory:
				   (currentVariable instVarAt: idx) class allInstVarNames
					   isNotEmpty;
			   yourself ]) asArray
]

{ #category : 'lsp - code lens' }
PLSServer >> codeLenResolves: range command: command data: aData [
	<jrpc: #'codeLens/resolve'>
	self flag: 'Not use in this version. All is done by codeLensTextDocument:'
]

{ #category : 'commands' }
PLSServer >> commandNotebookPrintIt: line textDocument: textDocumentURI [

	<jrpc: #'command:notebookPrintIt'>
	| compiler answer2 |
	"Use path because #external also uses the fragment number of the cell"
	compiler := self compilerFor: (textDocumentURI at: #path).
	answer2 := [ compiler evaluate: line ]
		           on: Error
		           do: [ :error | 
			           'error' record.
			           error ].
	^ answer2 asPLSCellOutput asJRPCJSON
]

{ #category : 'commands' }
PLSServer >> commandPharoLanguageServerVersion [
	<jrpc: #'command:version'>
	^ '1.0.0'
]

{ #category : 'commands' }
PLSServer >> commandPharoPrintIt: line textDocument: textDocumentURI [
	<jrpc: #'command:printIt'>
	"This textDocumentURI from VSCode is strange"
	| compiler answer2 | 
	compiler := self compilerFor: (textDocumentURI at: #path).
	answer2 := compiler evaluate: line.
	^ answer2 plsPrintString
]

{ #category : 'commands' }
PLSServer >> commandPharoSave [
	<jrpc: #'command:save'>
	SmalltalkImage current snapshot: true andQuit: false.
	^ 'Image saved'
]

{ #category : 'accessing' }
PLSServer >> compilerFor: fileURI [

	| compiler |
	compiler := SmalltalkImage current compiler
		            failBlock: [ nil ];
		            yourself.
	fileURI ifNotNil: [
		compiler requestor: (self context textItem: fileURI) binder ].
	^ compiler
]

{ #category : 'lsp - text synchronisation' }
PLSServer >> didChange: textDocument contentChanges: contentChanges [

	<jrpc: #'textDocument/didChange'>
	| document |
	document := self context
		            textItem: (textDocument at: #uri)
		            ifAbsent: [ self openDocument: textDocument ].
	document version: (textDocument at: #version).
	document text: (contentChanges anyOne at: #text).
	"If diagnostic is not nil, we are in a pull diagnostic context. Else, we are in a push diagnostic context"
	self publishDiagnosticsFor: document
]

{ #category : 'lsp - text synchronisation' }
PLSServer >> didClose: textDocument [

	<jrpc: #'textDocument/didClose'>
	| document |
	document := self context removeItem: (textDocument at: #uri).
	(PLSDocument isTonelDocument: textDocument) ifFalse: [
		self
			sendNotification: 'textDocument/publishDiagnostics'
			params: (PLSPublishDiagnosticsParams new
					 diagnostics: {  };
					 uri: document uri;
					 version: document version;
					 yourself) ]
]

{ #category : 'lsp - text synchronisation' }
PLSServer >> didOpen: textDocument [

	<jrpc: #'textDocument/didOpen'>
	| document |
	document := self openDocument: textDocument.
	"If diagnostic is not nil, we are in a pull diagnostic context. Else, we are in a push diagnostic context"
	self publishDiagnosticsFor: document
]

{ #category : 'lsp - text synchronisation' }
PLSServer >> didSave: textDocument text: text [
	"Install the code in the image if the code is part of a tonel file"

	<jrpc: #'textDocument/didSave'>
	(PLSDocument isTonelDocument: textDocument) ifTrue: [
		(PLSTonelParser parseString: text asByteArray utf8Decoded) do: #load ]
]

{ #category : 'lsp - document symbol' }
PLSServer >> documentSymbol: textDocument [

	<jrpc: #'textDocument/documentSymbol'>
	| document |
	document := self context textItem: (textDocument at: #uri).
	^ document symbols
]

{ #category : 'pls - variables' }
PLSServer >> documentVariables: textDocument [
	<jrpc: #'pls:documentVariables'>
	| document |
	document := self context
		textItem: (textDocument at: #uri at: #path).
	^ (document binder bindings associations
		collect: [ :assoc |
			  PLSVariable new
				name: assoc key printString;
				value: assoc value printString;
				variableReference: assoc key;
				isDirectory: assoc value class allInstVarNames isNotEmpty;
				yourself ]
		as: Array) asJRPCJSON
]

{ #category : 'pls - env changes' }
PLSServer >> envAnnouncementSelectors [
	"Answer the system announcements that change the environment model, with the method that records each of them"

	^ {
		  (PackageAdded -> #envPackageAdded:).
		  (PackageRemoved -> #envPackageRemoved:).
		  (PackageRenamed -> #envPackageRenamed:).
		  (PackageTagAdded -> #envTagAdded:).
		  (PackageTagRemoved -> #envTagRemoved:).
		  (PackageTagRenamed -> #envTagRenamed:).
		  (ClassAdded -> #envClassAdded:).
		  (ClassModifiedClassDefinition -> #envClassChanged:).
		  (ClassCommented -> #envClassChanged:).
		  (ClassParentRenamed -> #envClassChanged:).
		  (ClassRenamed -> #envClassRenamed:).
		  (ClassRepackaged -> #envClassRepackaged:).
		  (ClassRemoved -> #envClassRemoved:).
		  (ProtocolAdded -> #envProtocolAdded:).
		  (ProtocolRemoved -> #envProtocolRemoved:).
		  (ProtocolRenamed -> #envProtocolRenamed:).
		  (MethodAdded -> #envMethodAdded:).
		  (MethodModified -> #envMethodChanged:).
		  (MethodRepackaged -> #envMethodChanged:).
		  (MethodRecategorized -> #envMethodRecategorized:).
		  (MethodRemoved -> #envMethodRemoved:) } asOrderedDictionary
]

{ #category : 'pls - env' }
PLSServer >> envBaselineNamed: aString [

	| baseline |
	baseline := self class environment classNamed: 'BaselineOf' , aString.
	(baseline notNil and: [
			 (baseline inheritsFrom: BaselineOf) and: [
				 baseline includesSelector: #baseline: ] ]) ifFalse: [
		PLSUnknownEntity signal: 'Unknown project: ' , aString printString ].
	^ baseline
]

{ #category : 'pls - env' }
PLSServer >> envBaselines [
	"Answer the Metacello baselines of the image, sorted by name"

	^ (BaselineOf allSubclasses select: [ :baseline |
		   baseline includesSelector: #baseline: ]) sorted: [ :a :b |
		  a name <= b name ]
]

{ #category : 'pls - env' }
PLSServer >> envBehaviorNamed: aString [
	"aString is a class or trait name, followed by ' class' for its class side"

	| class |
	class := self class environment classOrTraitNamed:
		         (aString withoutSuffix: ' class').
	(class isNil or: [ class isClassSide ]) ifTrue: [
		PLSUnknownEntity signal: 'Unknown class: ' , aString printString ].
	^ (aString endsWith: ' class')
		  ifTrue: [ class classSide ]
		  ifFalse: [ class ]
]

{ #category : 'pls - env' }
PLSServer >> envBehaviorPathOf: aBehavior [

	^ aBehavior isClassSide
		  ifTrue: [ aBehavior instanceSide name , ' class' ]
		  ifFalse: [ aBehavior name ]
]

{ #category : 'pls - env changes' }
PLSServer >> envChange: kind id: id [
	"kind is added, changed, removed, renamed or moved"

	^ Dictionary new
		  at: #kind put: kind;
		  at: #id put: id;
		  yourself
]

{ #category : 'pls - env changes' }
PLSServer >> envChangesAreSettled [
	"Pending changes are sent once the system stays quiet for envQuietDelay, or envMaxDelay after the first of them.
	 A flood of changes that overflowed waits for the quiet, so that the client reloads everything once"

	^ envChangesMutex critical: [
			  | now |
			  now := Time millisecondClockValue.
			  now - envLastChangeTime >= self envQuietDelay or: [
				  envOverflow not and: [
					  now - envFirstChangeTime >= self envMaxDelay ] ] ]
]

{ #category : 'pls - env' }
PLSServer >> envChildren: id offset: offset limit: limit [
	"Answer one page of the children of the entity id, as nodes, with the total number of children.
	 offset is zero-based and defaults to 0; limit defaults to all the remaining children"

	<jrpc: #'pls-env:children'>
	| ids start stop |
	ids := self envChildrenIds: id.
	start := (offset ifNil: [ 0 ]) max: 0.
	stop := limit
		        ifNil: [ ids size ]
		        ifNotNil: [ start + limit min: ids size ].
	^ {
		  (#items -> ((start + 1 to: stop)
			    collect: [ :index | self envNode: (ids at: index) ]
			    as: Array)).
		  (#total -> ids size) } asDictionary
]

{ #category : 'pls - env' }
PLSServer >> envChildrenIds: id [
	"Answer the ids of the children of the entity id, in display order"

	^ self
		  perform:
		  ('env' , (self envKindOf: id) capitalized , 'Children:') asSymbol
		  with: (self envPathOf: id)
]

{ #category : 'pls - env changes' }
PLSServer >> envClassAdded: anAnnouncement [

	| class |
	class := anAnnouncement classAffected instanceSide.
	(self envIgnoresBehavior: class) ifTrue: [ ^ self ].
	self envRecord: [
			(self envChange: 'added' id: (self envClassIdOf: class))
				at: #parent
				put:
					(self envClassParentIdIn: class package tag: class packageTag);
				at: #version put: (self envVersionOfClass: class);
				yourself ]
]

{ #category : 'pls - env changes' }
PLSServer >> envClassChanged: anAnnouncement [

	| class |
	class := anAnnouncement classAffected instanceSide.
	(self envIgnoresBehavior: class) ifTrue: [ ^ self ].
	self envRecord: [
			(self envChange: 'changed' id: (self envClassIdOf: class))
				at: #version put: (self envVersionOfClass: class);
				yourself ]
]

{ #category : 'pls - env' }
PLSServer >> envClassChildren: aString [
	"A class has two sides, the instance side and the class side"

	self envClassNamed: aString.
	^ {
		  ('side:' , aString).
		  ('side:' , aString , ' class') }
]

{ #category : 'pls - env changes' }
PLSServer >> envClassIdOf: aClass [

	^ 'class:' , aClass instanceSide name
]

{ #category : 'pls - env' }
PLSServer >> envClassNamed: aString [
	"Answer the class or trait named aString. Its class side is not a class entity but a side"

	(aString endsWith: ' class') ifTrue: [
		PLSUnknownEntity signal: 'Unknown class: ' , aString printString ].
	^ self envBehaviorNamed: aString
]

{ #category : 'pls - env' }
PLSServer >> envClassNode: aString [

	| class |
	class := self envClassNamed: aString.
	^ Dictionary new
		  at: #name put: class name;
		  at: #parent put: (class packageTag isRoot
				   ifTrue: [ 'package:' , class package name ]
				   ifFalse: [
					   'tag:' , class package name , '/' , class packageTag name ]);
		  at: #hasChildren put: true;
		  at: #flags put: {
				  (#abstract -> class isAbstract).
				  (#test -> (class includesBehavior: TestCase)).
				  (#deprecated -> class isDeprecated).
				  (#trait -> class isTrait) } asDictionary;
		  yourself
]

{ #category : 'pls - env changes' }
PLSServer >> envClassParentIdIn: aPackage tag: aTag [

	^ (aTag isNil or: [ aTag isRoot ])
		  ifTrue: [ 'package:' , aPackage name ]
		  ifFalse: [ 'tag:' , aPackage name , '/' , aTag name ]
]

{ #category : 'pls - env changes' }
PLSServer >> envClassRemoved: anAnnouncement [
	"A removed class is already renamed AnObsolete..."

	| class |
	class := anAnnouncement classRemoved instanceSide.
	(self envIgnoresBehavior: class) ifTrue: [ ^ self ].
	self envRecord: [
			(self
				 envChange: 'removed'
				 id: 'class:' , (class name withoutPrefix: 'AnObsolete'))
				at: #parent put: (class package ifNotNil: [ :package |
							 self envClassParentIdIn: package tag: class packageTag ]);
				yourself ]
]

{ #category : 'pls - env changes' }
PLSServer >> envClassRenamed: anAnnouncement [
	"The ids of the sides, protocols and methods of the class change with it"

	(self envIgnoresBehavior: anAnnouncement classRenamed) ifTrue: [
		^ self ].
	self envRecord: [
			(self envChange: 'renamed' id: 'class:' , anAnnouncement newName)
				at: #oldId put: 'class:' , anAnnouncement oldName;
				yourself ]
]

{ #category : 'pls - env changes' }
PLSServer >> envClassRepackaged: anAnnouncement [

	| class |
	class := anAnnouncement classRepackaged instanceSide.
	(self envIgnoresBehavior: class) ifTrue: [ ^ self ].
	self envRecord: [
			(self envChange: 'moved' id: (self envClassIdOf: class))
				at: #parent put: (self
						 envClassParentIdIn: anAnnouncement newPackage
						 tag: anAnnouncement newTag);
				at: #oldParent put: (self
						 envClassParentIdIn: anAnnouncement oldPackage
						 tag: anAnnouncement oldTag);
				yourself ]
]

{ #category : 'pls - env' }
PLSServer >> envEntity: id [
	"Answer the node of the entity id, completed with its package and Iceberg repository, its superclass for a class,
	 and the version of a class or method, which changes with its source"

	<jrpc: #'pls-env:entity'>
	| entity packageName |
	entity := self envNode: id.
	packageName := self envPackageNameOf: id.
	entity
		at: #package
		put: (packageName ifNotNil: [ 'package:' , packageName ]).
	entity at: #repository put: (packageName ifNotNil: [
				 (IceRepository registry
					  detect: [ :repository |
						  repository workingCopy includesPackageNamed: packageName ]
					  ifNone: [ nil ]) ifNotNil: [ :repository | repository name ] ]).
	(entity at: #kind) = 'class' ifTrue: [
			| class |
			class := self envClassNamed: (self envPathOf: id).
			entity
				at: #superclass
				put: (class superclass ifNotNil: [ :superclass |
						 'class:' , superclass name ]).
			entity at: #version put: (self envVersionOfClass: class) ].
	(entity at: #kind) = 'method' ifTrue: [
			entity
				at: #version
				put:
				(self envVersionOfMethod:
					 (self envMethodNamed: (self envPathOf: id))) ].
	^ entity
]

{ #category : 'pls - env' }
PLSServer >> envExtensionsChildren: aString [

	^ ((self envPackageNamed: aString) extensionMethods collect: [
			   :method |
			   'method:' , (self envBehaviorPathOf: method methodClass) , '>>'
			   , method selector ]) asArray sort
]

{ #category : 'pls - env' }
PLSServer >> envExtensionsNode: aString [
	"The extensions of a package gather the methods it adds to classes of other packages"

	| package |
	package := self envPackageNamed: aString.
	^ Dictionary new
		  at: #name put: 'Extensions';
		  at: #parent put: 'package:' , package name;
		  at: #hasChildren put: package extensionMethods notEmpty;
		  at: #flags put: Dictionary new;
		  yourself
]

{ #category : 'pls - env changes' }
PLSServer >> envFlushChanges [
	"Send the pending changes to the client in one pls-env/didChange notification"

	| mutex changes reset |
	mutex := envChangesMutex ifNil: [ ^ self ].
	mutex critical: [
			changes := envChanges values asArray.
			reset := envOverflow.
			envChanges := OrderedDictionary new.
			envOverflow := false.
			envFirstChangeTime := nil ].
	(changes isEmpty and: [ reset not ]) ifTrue: [ ^ self ].
	clientOutStream ifNil: [ ^ self ].
	self sendNotification: 'pls-env/didChange' params: {
			(#changes -> changes).
			(#reset -> reset) } asDictionary
]

{ #category : 'pls - env changes' }
PLSServer >> envFlushLoop [

	[
		envChangesReady wait.
		[
			(Delay forMilliseconds: 20) wait.
			self envChangesAreSettled ] whileFalse.
		self envFlushChanges ] repeat
]

{ #category : 'pls - env changes' }
PLSServer >> envIgnoresBehavior: aBehavior [
	"Anonymous classes, such as those of tests and tools, are not part of the environment"

	^ aBehavior instanceSide isAnonymous
]

{ #category : 'pls - env' }
PLSServer >> envKindOf: id [
	"Answer the kind of the entity id, the part before its first colon"

	| kind |
	kind := id copyUpTo: $:.
	(#( 'project' 'package' 'tag' 'extensions' 'class' 'side' 'protocol'
	    'method' ) includes: kind) ifFalse: [
		PLSUnknownEntity signal: 'Unknown entity: ' , id printString ].
	^ kind
]

{ #category : 'pls - env changes' }
PLSServer >> envMaxChanges [

	^ 1000
]

{ #category : 'pls - env changes' }
PLSServer >> envMaxDelay [
	"Milliseconds"

	^ 500
]

{ #category : 'pls - env changes' }
PLSServer >> envMethodAdded: anAnnouncement [

	| method |
	method := anAnnouncement method.
	(self envIgnoresBehavior: method methodClass) ifTrue: [ ^ self ].
	self envRecord: [
			(self envChange: 'added' id: (self envMethodIdOf: method))
				at: #parent
				put:
					(self
						 envProtocolIdIn: method methodClass
						 named: method protocolName);
				at: #version put: (self envVersionOfMethod: method);
				yourself ]
]

{ #category : 'pls - env changes' }
PLSServer >> envMethodChanged: anAnnouncement [

	| method |
	method := anAnnouncement method.
	(self envIgnoresBehavior: method methodClass) ifTrue: [ ^ self ].
	self envRecord: [
			(self envChange: 'changed' id: (self envMethodIdOf: method))
				at: #version put: (self envVersionOfMethod: method);
				yourself ]
]

{ #category : 'pls - env' }
PLSServer >> envMethodChildren: aString [

	self envMethodNamed: aString.
	^ #(  )
]

{ #category : 'pls - env changes' }
PLSServer >> envMethodIdOf: aMethod [

	^ 'method:' , (self envBehaviorPathOf: aMethod methodClass) , '>>'
	  , aMethod selector
]

{ #category : 'pls - env' }
PLSServer >> envMethodNamed: aString [
	"aString is 'Behavior>>selector'. Class names hold no '>', so the first '>>' ends the behavior even for a selector such as >>"

	| index |
	index := aString indexOfSubCollection: '>>'.
	index = 0 ifTrue: [
		PLSUnknownEntity signal: 'Unknown method: ' , aString printString ].
	^ (self envBehaviorNamed: (aString first: index - 1))
		  compiledMethodAt: (aString allButFirst: index + 1) asSymbol
		  ifAbsent: [
		  PLSUnknownEntity signal: 'Unknown method: ' , aString printString ]
]

{ #category : 'pls - env' }
PLSServer >> envMethodNode: aString [

	| method |
	method := self envMethodNamed: aString.
	^ Dictionary new
		  at: #name put: method selector;
		  at: #parent
		  put:
			  'protocol:' , (self envBehaviorPathOf: method methodClass) , '>>'
			  , method protocolName;
		  at: #hasChildren put: false;
		  at: #flags put: {
				  (#abstract -> method isAbstract).
				  (#extension -> method isExtension).
				  (#override -> method isOverriding).
				  (#test -> method isTestMethod).
				  (#deprecated -> method isDeprecated).
				  (#fromTrait -> method isFromTrait) } asDictionary;
		  yourself
]

{ #category : 'pls - env changes' }
PLSServer >> envMethodRecategorized: anAnnouncement [

	| method |
	method := anAnnouncement method.
	(self envIgnoresBehavior: method methodClass) ifTrue: [ ^ self ].
	self envRecord: [
			(self envChange: 'moved' id: (self envMethodIdOf: method))
				at: #parent
				put:
					(self
						 envProtocolIdIn: method methodClass
						 named: method protocolName);
				at: #oldParent put: (self
						 envProtocolIdIn: method methodClass
						 named: anAnnouncement oldProtocol name);
				yourself ]
]

{ #category : 'pls - env changes' }
PLSServer >> envMethodRemoved: anAnnouncement [

	| behavior |
	behavior := anAnnouncement methodClass.
	(self envIgnoresBehavior: behavior) ifTrue: [ ^ self ].
	self envRecord: [
			(self
				 envChange: 'removed'
				 id: 'method:' , (self envBehaviorPathOf: behavior) , '>>'
					 , anAnnouncement selector)
				at: #parent
				put: (anAnnouncement protocol ifNotNil: [ :protocol |
							 self envProtocolIdIn: behavior named: protocol name ]);
				yourself ]
]

{ #category : 'pls - env' }
PLSServer >> envNode: id [
	"Answer the node of the entity id: its id, kind, name, parent, flags and whether it has children"

	| kind |
	kind := self envKindOf: id.
	^ (self
		   perform: ('env' , kind capitalized , 'Node:') asSymbol
		   with: (self envPathOf: id))
		  at: #id put: id;
		  at: #kind put: kind;
		  yourself
]

{ #category : 'pls - env changes' }
PLSServer >> envPackageAdded: anAnnouncement [

	self envRecord: [
			(self
				 envChange: 'added'
				 id: 'package:' , anAnnouncement package name)
				at: #parent
				put:
					(self envProjectIdOfPackageNamed: anAnnouncement package name);
				yourself ]
]

{ #category : 'pls - env' }
PLSServer >> envPackageChildren: aString [
	"Answer the tags of the package, then the classes outside any tag, then its extensions if any"

	| package |
	package := self envPackageNamed: aString.
	^ ((package tags reject: [ :tag | tag isRoot ]) collect: [ :tag |
		   'tag:' , aString , '/' , tag name ]) asArray sort
	  , ((package tags detect: [ :tag | tag isRoot ] ifNone: [ nil ])
			   ifNil: [ #(  ) ]
			   ifNotNil: [ :root |
					   (root classes collect: [ :class | 'class:' , class name ])
						   asArray sort ]) , (package extensionMethods
		   ifEmpty: [ #(  ) ]
		   ifNotEmpty: [ { ('extensions:' , aString) } ])
]

{ #category : 'pls - env' }
PLSServer >> envPackageNameOf: id [
	"Answer the name of the package that holds the entity id, or nil for a project.
	 An extension protocol belongs to the package of its methods"

	| kind path |
	kind := self envKindOf: id.
	path := self envPathOf: id.
	kind = 'project' ifTrue: [ ^ nil ].
	kind = 'package' | (kind = 'extensions') ifTrue: [
		^ (self envPackageNamed: path) name ].
	kind = 'tag' ifTrue: [ ^ (self envTagNamed: path) package name ].
	kind = 'method' ifTrue: [ ^ (self envMethodNamed: path) package name ].
	kind = 'protocol' ifTrue: [
			| behaviorAndProtocol |
			behaviorAndProtocol := self envProtocolNamed: path.
			^ behaviorAndProtocol value methodSelectors
				  ifEmpty: [ behaviorAndProtocol key package name ]
				  ifNotEmpty: [ :selectors |
					  (behaviorAndProtocol key >> selectors anyOne) package name ] ].
	^ (self envBehaviorNamed: path) package name
]

{ #category : 'pls - env' }
PLSServer >> envPackageNamed: aString [

	^ self packageOrganizer
		  packageNamed: aString
		  ifAbsent: [
		  PLSUnknownEntity signal: 'Unknown package: ' , aString printString ]
]

{ #category : 'pls - env' }
PLSServer >> envPackageNamesOfBaseline: aBaseline [
	"Answer the names of the packages declared by aBaseline, its own package included, loaded or not.
	 Reading a spec is slow, so the answer is cached until #baseline: is recompiled"

	| specMethod entry |
	envProjectPackages ifNil: [ envProjectPackages := Dictionary new ].
	specMethod := aBaseline >> #baseline:.
	entry := envProjectPackages at: aBaseline name ifAbsent: [ nil ].
	(entry isNil or: [ entry key ~~ specMethod ]) ifTrue: [
			entry := specMethod
			         ->
				         (([ aBaseline project version packages collect: #name ]
					           on: Error
					           do: [ #(  ) ]) asSet
					          add: aBaseline package name;
					          yourself).
			envProjectPackages at: aBaseline name put: entry ].
	^ entry value
]

{ #category : 'pls - env' }
PLSServer >> envPackageNode: aString [

	| package |
	package := self envPackageNamed: aString.
	^ Dictionary new
		  at: #name put: package name;
		  at: #parent put: (self envProjectIdOfPackageNamed: package name);
		  at: #hasChildren put: (package definedClasses notEmpty or: [
					   package extensionMethods notEmpty ]);
		  at: #flags put: { (#test -> package isTestPackage) } asDictionary;
		  yourself
]

{ #category : 'pls - env changes' }
PLSServer >> envPackageRemoved: anAnnouncement [

	self envRecord: [
		self
			envChange: 'removed'
			id: 'package:' , anAnnouncement package name ]
]

{ #category : 'pls - env changes' }
PLSServer >> envPackageRenamed: anAnnouncement [

	self envRecord: [
			(self envChange: 'renamed' id: 'package:' , anAnnouncement newName)
				at: #oldId put: 'package:' , anAnnouncement oldName;
				yourself ]
]

{ #category : 'pls - env' }
PLSServer >> envPathOf: id [
	"Answer the path of the entity id, the part after its first colon"

	^ id allButFirst: (id indexOf: $:)
]

{ #category : 'pls - env' }
PLSServer >> envProjectChildren: aString [
	"Answer the loaded packages of the project. The volatile project holds those of no baseline"

	| names |
	names := aString = '*'
		         ifTrue: [
				         | declared |
				         declared := Set new.
				         self envBaselines do: [ :baseline |
					         declared addAll:
						         (self envPackageNamesOfBaseline: baseline) ].
				         (self packageOrganizer packages collect: #name) reject: [
					         :name | declared includes: name ] ]
		         ifFalse: [
				         (self envPackageNamesOfBaseline:
					          (self envBaselineNamed: aString)) select: [ :name |
					         self packageOrganizer hasPackage: name ] ].
	^ names asArray sort collect: [ :name | 'package:' , name ]
]

{ #category : 'pls - env' }
PLSServer >> envProjectIdOfPackageNamed: aString [
	"Answer the project of the package: the first baseline by name that declares it, or else the volatile project"

	^ 'project:' , ((self envBaselines
		    detect: [ :baseline |
			    (self envPackageNamesOfBaseline: baseline) includes: aString ]
		    ifNone: [ ^ 'project:*' ]) name withoutPrefix: 'BaselineOf')
]

{ #category : 'pls - env' }
PLSServer >> envProjectNode: aString [
	"aString is the name of a baseline without its BaselineOf prefix, or * for the volatile project"

	aString = '*' ifFalse: [ self envBaselineNamed: aString ].
	^ Dictionary new
		  at: #name put: (aString = '*'
				   ifTrue: [ 'Volatile' ]
				   ifFalse: [ aString ]);
		  at: #parent put: nil;
		  at: #hasChildren put: true;
		  at: #flags put: { (#volatile -> (aString = '*')) } asDictionary;
		  yourself
]

{ #category : 'pls - env' }
PLSServer >> envProjects [
	"Answer the nodes of the projects of the image: one per Metacello baseline, then the volatile project that gathers the packages of no baseline"

	<jrpc: #'pls-env:projects'>
	^ (self envBaselines collect: [ :baseline |
		   'project:' , (baseline name withoutPrefix: 'BaselineOf') ])
		  asArray , { 'project:*' } collect: [ :id | self envNode: id ]
]

{ #category : 'pls - env changes' }
PLSServer >> envProtocolAdded: anAnnouncement [

	| behavior |
	behavior := anAnnouncement classReorganized.
	(self envIgnoresBehavior: behavior) ifTrue: [ ^ self ].
	self envRecord: [
			(self
				 envChange: 'added'
				 id:
					 (self
						  envProtocolIdIn: behavior
						  named: anAnnouncement protocol name))
				at: #parent put: 'side:' , (self envBehaviorPathOf: behavior);
				yourself ]
]

{ #category : 'pls - env' }
PLSServer >> envProtocolChildren: aString [

	| behaviorAndProtocol path |
	behaviorAndProtocol := self envProtocolNamed: aString.
	path := self envBehaviorPathOf: behaviorAndProtocol key.
	^ (behaviorAndProtocol value methodSelectors collect: [ :selector |
		   'method:' , path , '>>' , selector ]) asArray sort
]

{ #category : 'pls - env changes' }
PLSServer >> envProtocolIdIn: aBehavior named: aString [

	^ 'protocol:' , (self envBehaviorPathOf: aBehavior) , '>>' , aString
]

{ #category : 'pls - env' }
PLSServer >> envProtocolNamed: aString [
	"aString is 'Behavior>>protocol'. Answer the behavior -> the protocol"

	| index behavior |
	index := aString indexOfSubCollection: '>>'.
	index = 0 ifTrue: [
		PLSUnknownEntity signal: 'Unknown protocol: ' , aString printString ].
	behavior := self envBehaviorNamed: (aString first: index - 1).
	^ behavior -> (behavior
		   protocolNamed: (aString allButFirst: index + 1)
		   ifAbsent: [
		   PLSUnknownEntity signal: 'Unknown protocol: ' , aString printString ])
]

{ #category : 'pls - env' }
PLSServer >> envProtocolNode: aString [

	| behaviorAndProtocol |
	behaviorAndProtocol := self envProtocolNamed: aString.
	^ Dictionary new
		  at: #name put: behaviorAndProtocol value name;
		  at: #parent
		  put: 'side:' , (self envBehaviorPathOf: behaviorAndProtocol key);
		  at: #hasChildren
		  put: behaviorAndProtocol value methodSelectors notEmpty;
		  at: #flags
		  put:
			  { (#extension -> behaviorAndProtocol value isExtensionProtocol) }
				  asDictionary;
		  yourself
]

{ #category : 'pls - env changes' }
PLSServer >> envProtocolRemoved: anAnnouncement [

	| behavior |
	behavior := anAnnouncement classReorganized.
	(self envIgnoresBehavior: behavior) ifTrue: [ ^ self ].
	self envRecord: [
			self
				envChange: 'removed'
				id:
				(self
					 envProtocolIdIn: behavior
					 named: anAnnouncement protocol name) ]
]

{ #category : 'pls - env changes' }
PLSServer >> envProtocolRenamed: anAnnouncement [

	| behavior |
	behavior := anAnnouncement classReorganized.
	(self envIgnoresBehavior: behavior) ifTrue: [ ^ self ].
	self envRecord: [
			(self
				 envChange: 'renamed'
				 id:
					 (self
						  envProtocolIdIn: behavior
						  named: anAnnouncement newProtocol name))
				at: #oldId
				put:
					(self
						 envProtocolIdIn: behavior
						 named: anAnnouncement oldProtocol name);
				yourself ]
]

{ #category : 'pls - env changes' }
PLSServer >> envQuietDelay [
	"Milliseconds"

	^ 100
]

{ #category : 'pls - env changes' }
PLSServer >> envRecord: aBlock [
	"Add the change built by aBlock to the pending ones. A change replaces a pending change of the same kind on the same entity.
	 Past envMaxChanges pending changes, they are dropped and the client is told to reload everything.
	 aBlock runs in the process that changed the system, so its errors are ignored rather than break that change"

	| mutex change |
	mutex := envChangesMutex ifNil: [ ^ self ].
	envOverflow ifFalse: [
			change := [ aBlock value ]
				          on: Error
				          do: [ ^ self ] ].
	mutex critical: [
			| now |
			now := Time millisecondClockValue.
			envLastChangeTime := now.
			envFirstChangeTime ifNil: [
					envFirstChangeTime := now.
					envChangesReady signal ].
			(envOverflow or: [ change isNil ]) ifFalse: [
					| key |
					key := (change at: #kind) , ' ' , (change at: #id).
					envChanges removeKey: key ifAbsent: [ ].
					envChanges at: key put: change.
					envChanges size > self envMaxChanges ifTrue: [
							envOverflow := true.
							envChanges := OrderedDictionary new ] ] ]
]

{ #category : 'pls - env' }
PLSServer >> envSideChildren: aString [

	^ ((self envBehaviorNamed: aString) protocols collect: [ :protocol |
		   'protocol:' , aString , '>>' , protocol name ]) asArray sort
]

{ #category : 'pls - env' }
PLSServer >> envSideNode: aString [

	| behavior |
	behavior := self envBehaviorNamed: aString.
	^ Dictionary new
		  at: #name put: (behavior isClassSide
				   ifTrue: [ 'class side' ]
				   ifFalse: [ 'instance side' ]);
		  at: #parent put: 'class:' , behavior instanceSide name;
		  at: #hasChildren put: behavior protocols notEmpty;
		  at: #flags put: Dictionary new;
		  yourself
]

{ #category : 'pls - env changes' }
PLSServer >> envSubscribe [
	"Listen to the changes of the system, and send them to the client in pls-env/didChange notifications.
	 The changes are recorded in the process that made them, so recording one never signals an error into it"

	self envUnsubscribe.
	envChanges := OrderedDictionary new.
	envChangesMutex := Mutex new.
	envChangesReady := Semaphore new.
	envOverflow := false.
	envFirstChangeTime := nil.
	self envAnnouncementSelectors keysAndValuesDo: [
			:announcement
			:selector |
			SystemAnnouncer uniqueInstance
				when: announcement
				do: [ :each |
						[ self perform: selector with: each ]
							on: Error
							do: [ :error | error return: nil ] ]
				for: self ].
	envFlushProcess := [ self envFlushLoop ]
		                   forkAt: Processor userBackgroundPriority
		                   named: 'PLS environment changes'
]

{ #category : 'pls - env changes' }
PLSServer >> envTagAdded: anAnnouncement [

	anAnnouncement tag isRoot ifTrue: [ ^ self ].
	self envRecord: [
			(self
				 envChange: 'added'
				 id:
					 'tag:' , anAnnouncement package name , '/'
					 , anAnnouncement tag name)
				at: #parent put: 'package:' , anAnnouncement package name;
				yourself ]
]

{ #category : 'pls - env' }
PLSServer >> envTagChildren: aString [

	^ ((self envTagNamed: aString) classes collect: [ :class |
		   'class:' , class name ]) asArray sort
]

{ #category : 'pls - env' }
PLSServer >> envTagNamed: aString [
	"aString is 'Package/Tag'"

	| package |
	package := self envPackageNamed: (aString copyUpTo: $/).
	^ package tags
		  detect: [ :tag |
		  tag isRoot not and: [ tag name = (aString copyAfter: $/) ] ]
		  ifNone: [ PLSUnknownEntity signal: 'Unknown tag: ' , aString printString ]
]

{ #category : 'pls - env' }
PLSServer >> envTagNode: aString [

	| tag |
	tag := self envTagNamed: aString.
	^ Dictionary new
		  at: #name put: tag name;
		  at: #parent put: 'package:' , tag package name;
		  at: #hasChildren put: tag classes notEmpty;
		  at: #flags put: Dictionary new;
		  yourself
]

{ #category : 'pls - env changes' }
PLSServer >> envTagRemoved: anAnnouncement [

	anAnnouncement tag isRoot ifTrue: [ ^ self ].
	self envRecord: [
			self
				envChange: 'removed'
				id:
				'tag:' , anAnnouncement package name , '/'
				, anAnnouncement tag name ]
]

{ #category : 'pls - env changes' }
PLSServer >> envTagRenamed: anAnnouncement [

	self envRecord: [
			(self
				 envChange: 'renamed'
				 id:
					 'tag:' , anAnnouncement package name , '/'
					 , anAnnouncement newName)
				at: #oldId
				put:
					'tag:' , anAnnouncement package name , '/'
					, anAnnouncement oldName;
				yourself ]
]

{ #category : 'pls - env changes' }
PLSServer >> envUnsubscribe [

	SystemAnnouncer uniqueInstance unsubscribe: self.
	envFlushProcess ifNotNil: [ :flushProcess | flushProcess terminate ].
	envFlushProcess := nil.
	envChangesMutex := nil
]

{ #category : 'pls - env changes' }
PLSServer >> envVersionOfClass: aClass [
	"Answer a hash of the definition and comment of the class, which changes whenever they do"

	| class |
	class := aClass instanceSide.
	^ (SHA1 hashMessage:
		   class definitionString , class classSide definitionString
		   , class comment asString) hex
]

{ #category : 'pls - env changes' }
PLSServer >> envVersionOfMethod: aMethod [
	"Answer a hash of the source of the method, which changes whenever it does"

	^ (SHA1 hashMessage: aMethod sourceCode) hex
]

{ #category : 'lsp - formatting' }
PLSServer >> formatTextDocument: textDocument withOptions: options [

	<jrpc: #'textDocument/formatting'>
	| codeSource formatter lines endPosition |
	codeSource := (self context textItem: (textDocument at: #uri)) text.
	lines := codeSource lines.
	endPosition := PLSPosition new
		               line: lines size;
		               character: lines last size;
		               yourself.
	formatter := (PLSDocument isTonelDocument: textDocument)
		             ifFalse: [ PLSFormater new sourceCode: codeSource ]
		             ifTrue: [ PLSTonelFormater new sourceCode: codeSource ].
	^ { (PLSTextEdit new
		   newText: formatter formated;
		   range: (PLSRange new
				    start: (PLSPosition new
						     line: 0;
						     character: 0;
						     yourself);
				    end: endPosition;
				    yourself)) }
]

{ #category : 'pls - ice' }
PLSServer >> iceAddPackageToRepository: aRepositoryName packageName: packageName [

	<jrpc: #'pls-ice:addPackage'>
	| normalizedPackage repository workingCopy |
	normalizedPackage := packageName ifNil: [ '' ].
	normalizedPackage := normalizedPackage trimBoth.
	normalizedPackage ifEmpty: [ self error: 'Package name cannot be empty.' ].

	repository := self iceRepositoryNamed: aRepositoryName.
	self plsCreatePackage: normalizedPackage.
	workingCopy := repository workingCopy.
	(workingCopy includesPackageNamed: normalizedPackage) ifTrue: [
		^ 'Package ' , normalizedPackage , ' is already managed by ' , repository name ].

	workingCopy addPackageNamed: normalizedPackage.
	^ 'Package ' , normalizedPackage , ' added to ' , repository name
]

{ #category : 'pls - ice' }
PLSServer >> iceClassDefinitionNamed: className inPackageVersion: packageVersion [

	| definitions |
	packageVersion ifNil: [ ^ nil ].
	definitions := self iceDefinitionsInPackageVersion: packageVersion.
	^ definitions
		  detect: [ :definition | 
			  self
				  iceDefinition: definition
				  matchesClassName: className ]
		  ifNone: [ nil ]
]

{ #category : 'pls - ice' }
PLSServer >> iceDefinition: definition matchesClassName: className [

	| definitionName |
	definition ifNil: [ ^ false ].
	(definition respondsTo: #isClassDefinition) ifTrue: [ 
		(definition isClassDefinition not) ifTrue: [ ^ false ] ].
	(definition respondsTo: #name) ifFalse: [ ^ false ].
	definitionName := [ definition name asString ] on: Error do: [ nil ].
	^ definitionName = className
]

{ #category : 'pls - ice' }
PLSServer >> iceDefinitionsInPackageVersion: packageVersion [

	| snapshot |
	(packageVersion respondsTo: #definitions) ifTrue: [ 
		^ [ packageVersion definitions ] on: Error do: [ #() ] ].
	(packageVersion respondsTo: #snapshot) ifTrue: [ 
		snapshot := [ packageVersion snapshot ] on: Error do: [ nil ].
		snapshot ifNotNil: [ 
			(snapshot respondsTo: #definitions) ifTrue: [ 
				^ [ snapshot definitions ] on: Error do: [ #() ] ] ] ].
	^ #()
]

{ #category : 'pls - ice' }
PLSServer >> iceDiffLeavesOf: aDiff [

	| tree |
	tree := (aDiff respondsTo: #tree)
		        ifTrue: [ aDiff tree ]
		        ifFalse: [ ^ #() ].
	^ tree allChildren select: [ :node | node children isEmpty ]
]

{ #category : 'pls - ice' }
PLSServer >> iceOriginalContent: uri [

	"Return the original (reference commit) content for a pharoImage URI."
	<jrpc: #'pls-ice:originalContent'>
	| baseUri uriSegments packageName classFileName className repository source |
	baseUri := uri copyUpTo: $?.
	uriSegments := baseUri substrings: '/'.
	uriSegments size < 3 ifTrue: [ ^ '' ].
	packageName := uriSegments at: uriSegments size - 1.
	classFileName := uriSegments last.
	className := classFileName withoutSuffix: '.class.st'.
	repository := self iceRepositoryContainingClassUri: baseUri.
	source := repository
		          ifNil: [ nil ]
		          ifNotNil: [ 
			          self
				          iceOriginalContentFromRepository: repository
				          packageName: packageName
				          className: className ].
	^ source
]

{ #category : 'pls - ice' }
PLSServer >> iceOriginalContentFromRepository: repository packageName: packageName className: className [

	| workingCopy packageVersion source snapshot writer referenceCommit |
	workingCopy := repository workingCopy.
	referenceCommit := [ workingCopy referenceCommit ]
		                   on: Error
		                   do: [ nil ].
	referenceCommit ifNil: [ ^ '' ].
	packageVersion := self
		                  icePackageVersionIn: referenceCommit
		                  forPackageNamed: packageName
		                  className: className.
	snapshot := packageVersion mcSnapshot.
	writer := TonelWriter new snapshot: snapshot.
	source := String streamContents: [ :aStream |
		          writer
			          writeClass:
			          (snapshot
				           classDefinitionNamed: className
				           ifAbsent: [ '' ])
			          on: aStream ].
	^ source
]

{ #category : 'pls - ice' }
PLSServer >> iceOriginalResource: uri [
	"Return a virtual pharoImage URI for the reference version; never use the local filesystem."

	<jrpc: #'pls-ice:originalResource'>
	^ (uri copyUpTo: $?) , '?iceOriginal=1'
]

{ #category : 'pls - ice' }
PLSServer >> icePackageVersionIn: workingCopy forPackageNamed: packageName className: className [

	^ workingCopy versionFor: packageName asPackage
]

{ #category : 'pls - ice' }
PLSServer >> iceRepositories [

	<jrpc: #'pls-ice:repositories'>
	^ (IceRepository registry collect: [ :repository | 
		   { 
			   (#name -> repository name).
			   (#valid -> repository isValid) } asDictionary ]) asArray
]

{ #category : 'pls - ice' }
PLSServer >> iceRepository: aRepositoryName [

	<jrpc: #'pls-ice:repository'>
	| repoOfInterest set |
	repoOfInterest := IceRepository registry detect: [ :repository | 
		                  repository name = aRepositoryName ].
	set := (repoOfInterest workingCopy diffToReferenceCommit tree
		        allChildren
		        select: [ :a | a children isEmpty ]
		        thenCollect: [ :a | a definition actualClass ]) asSet.
	^ (set collect: #plsURIString) asArray
]

{ #category : 'pls - ice' }
PLSServer >> iceRepositoryChangesFor: aRepositoryName [

	| repository diff leaves changes seenUris |
	repository := self iceRepositoryNamed: aRepositoryName.
	diff := repository workingCopy diffToReferenceCommit.
	leaves := self iceDiffLeavesOf: diff.
	changes := OrderedCollection new.
	seenUris := Set new.
	leaves do: [ :leaf | 
		| definition targetClass status uri |
		definition := leaf definition.
		(definition respondsTo: #actualClass) ifTrue: [ 
			targetClass := definition actualClass.
			targetClass ifNotNil: [ 
				uri := targetClass plsURIString.
				(seenUris includes: uri) ifFalse: [ 
					seenUris add: uri.
					status := self iceStatusForDiffLeaf: leaf.
					changes add: { 
							#uri -> uri.
							#status -> status } asDictionary ] ] ] ].
	^ changes asArray
]

{ #category : 'pls - ice' }
PLSServer >> iceRepositoryCommit: aRepositoryName message: message [

	<jrpc: #'pls-ice:commit'>
	| repository workingCopy diff |
	repository := self iceRepositoryNamed: aRepositoryName.
	workingCopy := repository workingCopy.
	diff := workingCopy diffToReferenceCommit.
	(self iceDiffLeavesOf: diff) ifEmpty: [
		^ 'Nothing to commit in ' , repository name ].

	workingCopy commitChanges: diff withMessage: message force: false.
	^ 'Committed ' , repository name
]

{ #category : 'pls - ice' }
PLSServer >> iceRepositoryContainingClassUri: classUri [

	^ IceRepository registry
		  detect: [ :repository |
				  [
					  repository isValid and: [
							  (self iceRepositoryChangesFor: repository name) anySatisfy: [
								  :change | (change at: #uri) = classUri ] ] ]
					  on: Error
					  do: [ false ] ]
		  ifNone: [ nil ]
]

{ #category : 'pls - ice' }
PLSServer >> iceRepositoryNamed: aRepositoryName [

	^ IceRepository registry
		  detect: [ :repository | repository name = aRepositoryName ]
		  ifNone: [
		  self error: 'Iceberg repository not found: ' , aRepositoryName ]
]

{ #category : 'pls - ice' }
PLSServer >> iceRepositoryPackages: aRepositoryName [

	<jrpc: #'pls-ice:repositoryPackages'>
	| repository workingCopy |
	repository := self iceRepositoryNamed: aRepositoryName.
	workingCopy := repository workingCopy.
	^ (workingCopy packages collect: [:iceP | iceP package ]) asArray
]

{ #category : 'pls - ice' }
PLSServer >> iceRepositoryPush: aRepositoryName [

	<jrpc: #'pls-ice:push'>
	| repository |
	repository := self iceRepositoryNamed: aRepositoryName.
	(repository respondsTo: #push) ifTrue: [
		repository push.
		^ 'Pushed ' , repository name ].

	^ self error: 'Iceberg push API not available in this image.'
]

{ #category : 'pls - ice' }
PLSServer >> iceRepositoryStatus: aRepositoryName [

	<jrpc: #'pls-ice:repositoryStatus'>
	^ {
		  (#stagedChanges -> #(  ) asArray).
		  (#changes -> (self iceRepositoryChangesFor: aRepositoryName)) }
		  asDictionary
]

{ #category : 'pls - ice' }
PLSServer >> iceSourceFromDefinition: definition [

	| source |
	definition ifNil: [ ^ nil ].
	#(contents sourceString sourceCode source tonelString)
		do: [ :selector | 
			(definition respondsTo: selector) ifTrue: [ 
				source := [ definition perform: selector ]
					          on: Error
					          do: [ nil ].
				source ifNotNil: [ 
					source isString ifTrue: [ ^ source ].
					(source respondsTo: #utf8Decoded) ifTrue: [ ^ source utf8Decoded ].
					(source respondsTo: #asString) ifTrue: [ ^ source asString ] ] ] ].
	(definition respondsTo: #actualClass) ifTrue: [ 
		| currentClass |
		currentClass := definition actualClass.
		currentClass ifNotNil: [ ^ self iceSourceFromImageClassNamed: currentClass name ] ].
	^ nil
]

{ #category : 'pls - ice' }
PLSServer >> iceSourceFromImageClassNamed: className [

	| targetClass |
	targetClass := self class environment
		               at: className asSymbol
		               ifAbsent: [ ^ '' ].
	^ String streamContents: [ :stream |
		  TonelWriter exportClass: targetClass on: stream ]
]

{ #category : 'pls - ice' }
PLSServer >> iceStatusForDiffLeaf: aDiffLeaf [

	| className |
	(aDiffLeaf respondsTo: #isAddition) ifTrue: [
		aDiffLeaf isAddition ifTrue: [ ^ 'added' ] ].
	(aDiffLeaf respondsTo: #isRemoval) ifTrue: [
		aDiffLeaf isRemoval ifTrue: [ ^ 'deleted' ] ].
	(aDiffLeaf respondsTo: #isConflict) ifTrue: [
		aDiffLeaf isConflict ifTrue: [ ^ 'conflicted' ] ].
	className := aDiffLeaf class name asString asLowercase.
	(className includesSubstring: 'add') ifTrue: [ ^ 'added' ].
	((className includesSubstring: 'remove') or: [
		 className includesSubstring: 'delete' ]) ifTrue: [ ^ 'deleted' ].
	(className includesSubstring: 'conflict') ifTrue: [ ^ 'conflicted' ].
	^ 'modified'
]

{ #category : 'pls - env changes' }
PLSServer >> isSubscribedToEnvironmentChanges [

	^ envChangesMutex notNil
]

{ #category : 'lsp - initialization' }
PLSServer >> onInitializeTrace: trace processId: processId locale: locale clientInfo: clientInfo rootPath: rootPath workspaceFolders: workspaceFolders capabilities: capabilities rootUri: rootUri [

	<jrpc: #initialize>
	self context clientContext: (PLPInitializeParams new
			 trace: trace;
			 processId: processId;
			 locale: locale;
			 clientInfo: clientInfo;
			 rootPath: rootPath;
			 workspaceFolders: workspaceFolders;
			 capabilities: (PLPClientCapabilities from: capabilities);
			 rootUri: rootUri;
			 yourself).
	trace ifNotNil: [ self context traceValue: trace ].
	^ PLSInitializeResult new
]

{ #category : 'lsp - text synchronisation' }
PLSServer >> openDocument: textDocument [
	"Register the document sent by the client and answer it"

	| document |
	document := self context
		            textItem: (textDocument at: #uri)
		            put: (PLSDocument from: textDocument).
	document server: self.
	^ document
]

{ #category : 'pls' }
PLSServer >> plsCreateClass: className packageName: packageName superclassName: superclassName instanceVariables: instanceVariables [

	<jrpc: #'pls:createClass'>
	| normalizedClassName normalizedPackageName normalizedSuperclassName normalizedInstanceVariables superclass existingClass createdClass |
	normalizedClassName := className ifNil: [ '' ].
	normalizedClassName := normalizedClassName trimBoth.
	normalizedClassName ifEmpty: [
		self error: 'Class name cannot be empty.' ].

	normalizedPackageName := packageName ifNil: [ '' ].
	normalizedPackageName := normalizedPackageName trimBoth.
	normalizedPackageName ifEmpty: [
		self error: 'Package name cannot be empty.' ].

	normalizedSuperclassName := superclassName ifNil: [ 'Object' ].
	normalizedSuperclassName := normalizedSuperclassName trimBoth.
	normalizedSuperclassName ifEmpty: [
		normalizedSuperclassName := 'Object' ].

	normalizedInstanceVariables := instanceVariables ifNil: [ '' ].
	normalizedInstanceVariables := normalizedInstanceVariables trimBoth.

	self plsCreatePackage: normalizedPackageName.
	existingClass := self class environment
		                 at: normalizedClassName asSymbol
		                 ifAbsent: [ nil ].
	existingClass ifNotNil: [
		^ 'Class ' , normalizedClassName , ' already exists.' ].

	superclass := self class environment
		              at: normalizedSuperclassName asSymbol
		              ifAbsent: [
		              self error:
			              'Superclass not found: ' , normalizedSuperclassName ].
	createdClass := superclass classInstaller make: [ :builder |
		                builder
			                superclass: superclass;
			                name: normalizedClassName asSymbol;
			                slotsFromString: normalizedInstanceVariables;
			                sharedVariablesFromString: '';
			                package: normalizedPackageName;
			                environment: superclass environment ].
	^ 'Class ' , createdClass name , ' created in package '
	  , normalizedPackageName
]

{ #category : 'pls' }
PLSServer >> plsCreatePackage: packageName [

	<jrpc: #'pls:createPackage'>
	| normalizedPackageName wasExisting |
	normalizedPackageName := packageName ifNil: [ '' ].
	normalizedPackageName := normalizedPackageName trimBoth.
	normalizedPackageName ifEmpty: [
		self error: 'Package name cannot be empty.' ].
	wasExisting := self packageOrganizer hasPackage:
		               normalizedPackageName.
	self packageOrganizer ensurePackage: normalizedPackageName.
	^ wasExisting
		  ifTrue: [ 'Package ' , normalizedPackageName , ' already exists.' ]
		  ifFalse: [ 'Package ' , normalizedPackageName , ' created.' ]
]

{ #category : 'pls' }
PLSServer >> plsExecuteClass: class test: testMethod [
	<jrpc: #'pls:executeClassTest'>
	| result |
	result := (self class environment at: class asSymbol)
		run: testMethod asSymbol.
	^ result printString
	"{(#failures -> (result failures collect: #printString as: Array)).
	(#errors -> (result errors collect: #printString as: Array)).
	(#skipped -> (result skipped collect: #printString as: Array)).
	(#passed -> (result passed collect: #printString as: Array))}
		asDictionary"
]

{ #category : 'pls' }
PLSServer >> plsExecuteClassTests: className [
	<jrpc: #'pls:executeClassTests'>
	| result |
	result := (self class environment at: className asSymbol) suite run.
	^ result printString
	"{(#failures -> (result failures collect: #printString as: Array)).
	(#errors -> (result errors collect: #printString as: Array)).
	(#skipped -> (result skipped collect: #printString as: Array)).
	(#passed -> (result passed collect: #printString as: Array))}
		asDictionary"
]

{ #category : 'pls' }
PLSServer >> plsGetClassContent: class [

	<jrpc: #'pls:classContent'>
	| className |
	className := ((class substrings: '/') last withoutSuffix: '.st')
		             withoutSuffix: '.class'.
	^ String streamContents: [ :stream |
		  TonelWriter
			  exportClass: (self class environment at: className asSymbol)
			  on: stream ]
]

{ #category : 'pls' }
PLSServer >> plsGetClasses: package [
	<jrpc: #'pls:classes'>
	^ [ package asPackage classes
		collect: [ :class | package , '/' , class name , '.class.st' ]
		as: Array ]
		on: Error
		do: [ {} asArray ]
]

{ #category : 'pls' }
PLSServer >> plsGetPackages [
	<jrpc: #'pls:packages'>
	^ (self packageOrganizer packages collect: #name)
		asArray
]

{ #category : 'pls - gtk' }
PLSServer >> plsGtkInspectIt: line textDocument: textDocumentURI [

	"| compiler inspector |
	compiler := self compilerFor: nil.
	inspector := (PLSApplication current new: StInspector).
	inspector model: (StInspectorModel on: ([ compiler evaluate: line ] on: Exception do: [ :error | error ])).
	inspector openWithSpec."

	<jrpc: #'pls-gtk:inspectIt'>
	| app compiler answer2 |
	compiler := self compilerFor: (textDocumentURI at: #path).
	answer2 := [ compiler evaluate: line ] on: Exception do: [ :error | 'error' record. error ].
	[ 
	app := SpApplication new
		       useBackend: #Gtk;
		       yourself.

	(StInspectorPresenter onObject: answer2)
		application: app;
		open ]
		on: Error
		do: [ :err | ^ err message printString ].
	'opened with spec' record.
	^ 'ok'
]

{ #category : 'pls - developer' }
PLSServer >> plsOpenLog [

	<jrpc: #'pls-developer:openLog'>
	(TinyLogger default ensureMoreFileLoggerNamed: 'LSP.log') open.
	^ 'success'
]

{ #category : 'pls - developer' }
PLSServer >> plsResetLog [

	<jrpc: #'pls-developer:clearLog'>
	(TinyLogger default ensureMoreFileLoggerNamed: 'LSP.log') clearLog.
	^ 'success'
]

{ #category : 'pls - tests' }
PLSServer >> plsTestExecuteTest: aTestURI [

	<jrpc: #'pls:test-execute-test'>
	| className result |
	className := ((aTestURI at: #path) substrings: '/') last
		             withoutSuffix: '.class.st'.
	result := (self class environment at: className asSymbol) run:
		          (aTestURI at: #fragment) asSymbol.
	^ {
		  (#failures -> (result failures collect: #printString as: Array)).
		  (#errors -> (result errors collect: #printString as: Array)).
		  (#skipped -> (result skipped collect: #printString as: Array)).
		  (#passed -> (result passed collect: #printString as: Array)) }
		  asDictionary
]

{ #category : 'pls - tests' }
PLSServer >> plsTestInClass: aClassURI [

	<jrpc: #'pls:test-in-class'>
	| className |
	className := ((aClassURI at: #path) substrings: '/') last
		             withoutSuffix: '.class.st'.
		
	^ (self class environment at: className asSymbol) suite tests
		  collect: [ :test | (aClassURI at: #external) , '#' , test selector ]
		  as: Array
]

{ #category : 'pls - tests' }
PLSServer >> plsTestInPackage: aPackageURI [

	<jrpc: #'pls:test-in-package'>
	^ [
	  (((aPackageURI at: #path) withoutPrefix: '/') asPackage classes select: [ :class |
		   (class name endsWith: 'Tests') or: [ class name endsWith: 'Test' ] ])
		  collect: [ :class | class plsURIString ]
		  as: Array ]
		  on: Error
		  do: [ {  } asArray ]
]

{ #category : 'pls - tests' }
PLSServer >> plsTestPackages [

	<jrpc: #'pls:test-packages'>
	^ (TestCase allSubclasses
		   reject: #isAbstract
		   thenCollect: [ :class | class package ]) asSet
		  collect: [ :package | package plsURIString ]
		  as: Array

	"'pharoImage://' , class package name , '/' , class name
			   , '.class.st'"
]

{ #category : 'lsp - text synchronisation' }
PLSServer >> publishDiagnosticsFor: document [

	self context clientContext capabilities textDocument ifNotNil: [ :td |
		td diagnostic ifNil: [ self sendDiagnosticsforDocument: document ] ]
]

{ #category : 'lsp - initialization' }
PLSServer >> serverInitialized [
	"The client is ready for notifications: start sending it the changes of the environment"

	super serverInitialized.
	self envSubscribe
]

{ #category : 'dap' }
PLSServer >> startDapServer [
	<jrpc: #'dap:startServer'>
	'Start DAP Server.' record.
	^ DAPServer new
		start.
]

{ #category : 'starting' }
PLSServer >> stop [

	self envUnsubscribe.
	super stop
]

{ #category : 'lsp - completion' }
PLSServer >> textDocumentCompletionWithContext: context position: position textDocument: textDocument [

	<jrpc: #'textDocument/completion'>
	| completionList completionTool |
	completionTool := PLSCompletion new
		                  source:
			                  (self context textItem: (textDocument at: #uri))
				                  text;
		                  position: position;
		                  yourself.
	(PLSDocument isTonelDocument: textDocument) ifTrue: [
			completionTool sourceClass: (([
					  PLSTonelParser parseString:
						  (self context textItem: (textDocument at: #uri)) text ]
					  on: Error
					  do: [ ^ {  } ]) detect: #isClassDefinition) actualClass ].
	completionList := PLSCompletionList new.
	completionList completionItems: completionTool entries asArray.
	^ completionList
]

{ #category : 'lsp - hover' }
PLSServer >> textDocumentHoverWithPosition: position textDocument: textDocument [
	<jrpc: #'textDocument/hover'>
	| hover document |
	document := (self context textItem: (textDocument at: #uri)). 
	hover := PLSHover new
		context: self context;
		source: document;
		position: position;
		yourself.
	^ { #contents -> hover contents } asDictionary
]

{ #category : 'lsp - completion' }
PLSServer >> textDocumentInlineCompletionWithContext: context position: position textDocument: textDocument [

	<jrpc: #'textDocument/inlineCompletion'>
	| internalTextDocument api answer userPosition result |
	internalTextDocument := self context textItem:
		                        (textDocument at: #uri).
	userPosition := internalTextDocument text plsToPosition: position.
	api := LLMAPI fim.
	api host: 'api.mistral.ai'.

	api payload
		temperature: 0.2;
		model: 'codestral-2501';
		top_p: 1;
		max_tokens: 250;
		prompt: (internalTextDocument text copyFrom: 1 to: userPosition).
	userPosition = internalTextDocument text size ifFalse: [
		api payload suffix: (internalTextDocument text
				 copyFrom: userPosition
				 to: internalTextDocument text size) ].

	result := api performRequest.
	answer := result choices anyOne message content.

	^ (PLSInlineCompletionList new
		   items: { (PLSInlineCompletionItem new insertText:
					    (self postDealAnswer: answer)) };
		   yourself) asJRPCJSON
]

{ #category : 'lsp - signature help' }
PLSServer >> textDocumentSignatureHelpWithPosition: position textDocument: textDocument anContext: context [
	<jrpc: #'textDocument/signatureHelp'>
	| text positionChar selector node |
	text := (self context textItem: (textDocument at: #uri)) text.
	positionChar := text plsToPosition: position.
	node := (RBParser parseFaultyExpression: text)
		bestNodeFor: (Interval from: positionChar to: positionChar).
	"Node can be nil with this piece of code: `true :` (the ':' is not correctly parsed, so node becomes nil)"
	selector := (node isNotNil and: [ node isMessage ])
		ifTrue: [ node selector ]
		ifFalse: [ '' ].
	^ PLSSignatureHelp new
		signatures:
			((SystemNavigation new allImplementorsOf: selector)
				collect: [ :implementor | 
					PLSSignatureInformation new
						label: implementor printString;
						documentation: implementor compiledMethod comment;
						parameters:
							(implementor argumentNames
								collect: [ :name | 
									PLSParameterInformation new
										label: name;
										yourself ]
								as: Array);
						yourself ]
				as: Array);
		yourself
]

{ #category : 'lsp - type definition' }
PLSServer >> typeDefinitionAt: position in: textDocument [

	<jrpc: #'textDocument/typeDefinition'>
	| document canBeClass aClass |
	document := self context textItem: (textDocument at: #uri).
	canBeClass := document nodeAt: position.
	canBeClass ifNil: [ ^ {  } ].
	((canBeClass isKindOf: RBProgramNode) not or: [ 
		 canBeClass isVariable not ]) ifTrue: [ ^ {  } ].
	aClass := self class environment
		          at: canBeClass name asSymbol
		          ifAbsent: [ ^ {  } ].
	aClass isClass ifFalse: [ ^ {  } ].
	^ PLSLocation new
		  uri: aClass plsURIString;
		  range: (PLSRange
				   start: (PLSPosition line: 0 character: 0)
				   end: (PLSPosition line: 0 character: 0));
		  yourself
]
