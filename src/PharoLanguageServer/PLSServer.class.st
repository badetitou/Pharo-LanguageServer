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
		'envProjectPackages'
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

{ #category : 'pls - env' }
PLSServer >> envClassChildren: aString [
	"A class has two sides, the instance side and the class side"

	self envClassNamed: aString.
	^ {
		  ('side:' , aString).
		  ('side:' , aString , ' class') }
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

{ #category : 'pls - env' }
PLSServer >> envEntity: id [
	"Answer the node of the entity id, completed with its package and Iceberg repository, and its superclass for a class"

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
			entity
				at: #superclass
				put:
					((self envBehaviorNamed: (self envPathOf: id)) superclass
						 ifNotNil: [ :superclass | 'class:' , superclass name ]) ].
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

{ #category : 'pls - env' }
PLSServer >> envMethodChildren: aString [

	self envMethodNamed: aString.
	^ #(  )
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

{ #category : 'pls - env' }
PLSServer >> envProtocolChildren: aString [

	| behaviorAndProtocol path |
	behaviorAndProtocol := self envProtocolNamed: aString.
	path := self envBehaviorPathOf: behaviorAndProtocol key.
	^ (behaviorAndProtocol value methodSelectors collect: [ :selector |
		   'method:' , path , '>>' , selector ]) asArray sort
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

{ #category : 'dap' }
PLSServer >> startDapServer [
	<jrpc: #'dap:startServer'>
	'Start DAP Server.' record.
	^ DAPServer new
		start.
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
