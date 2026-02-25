"
I am the server. 
I also include all the pharo language features.

Methods in `lsp` protocol are standard language server protocol feature.

Methods in `pls` protocol are pharo language server feature.
"
Class {
	#name : 'PLSServer',
	#superclass : 'PLSAbstractServer',
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
		           on: Exception
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
		            ifAbsent: [
			            self didOpen: textDocument.
			            self context textItem: (textDocument at: #uri) ].
	document version: (textDocument at: #version).
	document text: (contentChanges anyOne at: #text).
	"If diagnostic is not nil, we are in a pull diagnostic context. Else, we are in a push diagnostic context"
	self context clientContext capabilities textDocument ifNotNil: [ :td |
		td diagnostic ifNil: [
			self
				sendData: (self convertJRPCJsonableObjectToJSON:
						 ((JRPCNotificationObject method:
							   'textDocument/publishDiagnostics') params:
							  document diagnostics) asJRPCJSON)
				toClient: clientOutStream ] ]
]

{ #category : 'lsp - text synchronisation' }
PLSServer >> didClose: textDocument [
	<jrpc: #'textDocument/didClose'>
	| document |
	document := self context removeItem: (textDocument at: #uri).
	(self isTonelDocument: textDocument)
		ifFalse: [ self
				sendData:
					(self
						convertJRPCJsonableObjectToJSON:
							((JRPCNotificationObject method: 'textDocument/publishDiagnostics')
								params:
									(PLSPublishDiagnosticsParams new
										diagnostics: {};
										uri: document uri;
										version: document version;
										yourself)) asJRPCJSON)
				toClient: clientOutStream ]
]

{ #category : 'lsp - text synchronisation' }
PLSServer >> didOpen: textDocument [

	<jrpc: #'textDocument/didOpen'>
	| document |
	document := self context
		            textItem: (textDocument at: #uri)
		            put: (PLSDocument from: textDocument).
	document server: self.
	(self isTonelDocument: textDocument) ifFalse: [
		| diagnostics |
		diagnostics := ((PLSDiagnosticsParamsEngine document: document)
			                requestor: document binder) computeDiagnostics.

		self
			sendData: (self convertJRPCJsonableObjectToJSON:
					 ((JRPCNotificationObject method:
						   'textDocument/publishDiagnostics') params:
						  (PLSPublishDiagnosticsParams new
							   diagnostics: diagnostics asArray;
							   uri: document uri;
							   version: document version;
							   yourself) asJRPCJSON) asJRPCJSON)
			toClient: clientOutStream ]
]

{ #category : 'lsp - text synchronisation' }
PLSServer >> didSave: textDocument text: text [
	<jrpc: #'textDocument/didSave'>
	"Install the code in the image if the code is part of a tonel file"
	((textDocument at: #uri) endsWith: 'class.st')
		ifTrue: [ (PLSTonelParser parseString: text asByteArray utf8Decoded) do: #load ]
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
	formatter := (self isTonelDocument: textDocument)
		ifFalse: [ PLSFormater new sourceCode: codeSource ]
		ifTrue: [ PLSTonelFormater new sourceCode: codeSource ].
	^ {(PLSTextEdit new
		newText: formatter formated;
		range:
			(PLSRange new
				start:
					(PLSPosition new
						line: 0;
						character: 0;
						yourself);
				end: endPosition;
				yourself))}
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
PLSServer >> iceOriginalFileForPackage: packageName classFileName: classFileName [

	| foundFile |
	foundFile := nil.
	IceRepository registry do: [ :repository |
		| location directInRoot directInSrc |
		foundFile ifNil: [ 
			(repository respondsTo: #location) ifTrue: [ 
				location := repository location.
				location ifNotNil: [ 
					directInRoot := location / packageName / classFileName.
					directInRoot exists ifTrue: [ foundFile := directInRoot ].
					foundFile ifNil: [ 
						directInSrc := location / 'src' / packageName / classFileName.
						directInSrc exists ifTrue: [ foundFile := directInSrc ] ].
					(foundFile isNil and: [ location respondsTo: #allChildren ]) ifTrue: [ 
						foundFile := location allChildren
							             detect: [ :fileReference | 
								             fileReference isFile and: [ 
									             fileReference basename = classFileName and: [ 
										             fileReference parent basename = packageName ] ] ]
							             ifNone: [ nil ] ] ] ] ] ].
	^ foundFile
]

{ #category : 'pls - ice' }
PLSServer >> iceOriginalResource: uri [ 

	<jrpc: #'pls-ice:originalResource'>
	| uriSegments packageName classFileName originalFile normalizedPath |
	uriSegments := uri substrings: '/'.
	uriSegments size < 3 ifTrue: [ ^ uri ].
	packageName := uriSegments at: uriSegments size - 1.
	classFileName := uriSegments last.
	originalFile := self
		                iceOriginalFileForPackage: packageName
		                classFileName: classFileName.
	originalFile ifNil: [ ^ uri ].
	normalizedPath := originalFile pathString copyReplaceAll: '\' with: '/'.
	(normalizedPath beginsWith: '/') ifFalse: [ normalizedPath := '/' , normalizedPath ].
	^ 'file://' , normalizedPath
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
	(self iceDiffLeavesOf: diff) ifEmpty: [ ^ 'Nothing to commit in ' , repository name ].

	(workingCopy respondsTo: #commitChanges:withMessage:force:) ifTrue: [ 
		workingCopy
			commitChanges: diff
			withMessage: message
			force: false.
		^ 'Committed ' , repository name ].

	(workingCopy respondsTo: #commitChanges:withMessage:) ifTrue: [ 
		workingCopy
			commitChanges: diff
			withMessage: message.
		^ 'Committed ' , repository name ].

	(workingCopy respondsTo: #commitWithMessage:) ifTrue: [ 
		workingCopy commitWithMessage: message.
		^ 'Committed ' , repository name ].

	(repository respondsTo: #commitWithMessage:) ifTrue: [ 
		repository commitWithMessage: message.
		^ 'Committed ' , repository name ].

	^ self error: 'Iceberg commit API not available in this image.'
]

{ #category : 'pls - ice' }
PLSServer >> iceRepositoryNamed: aRepositoryName [ 

	^ IceRepository registry
		  detect: [ :repository | repository name = aRepositoryName ]
		  ifNone: [ self error: 'Iceberg repository not found: ' , aRepositoryName ]
]

{ #category : 'pls - ice' }
PLSServer >> iceRepositoryPush: aRepositoryName [ 

	<jrpc: #'pls-ice:push'>
	| repository |
	repository := self iceRepositoryNamed: aRepositoryName.
	(repository respondsTo: #push) ifTrue: [ 
		repository push.
		^ 'Pushed ' , repository name ].

	(repository respondsTo: #pushRemote:) ifTrue: [ 
		| remote |
		remote := self iceRepositoryPushRemoteOf: repository.
		remote
			ifNil: [ ^ self error: 'Unable to determine push remote for repository ' , repository name ]
			ifNotNil: [ 
				repository pushRemote: remote.
				^ 'Pushed ' , repository name ] ].

	^ self error: 'Iceberg push API not available in this image.'
]

{ #category : 'pls - ice' }
PLSServer >> iceRepositoryPushRemoteOf: aRepository [

	(aRepository respondsTo: #pushRemote) ifTrue: [ ^ aRepository pushRemote ].
	(aRepository respondsTo: #upstreamRemote) ifTrue: [ ^ aRepository upstreamRemote ].
	(aRepository respondsTo: #origin) ifTrue: [ ^ aRepository origin ].
	(aRepository respondsTo: #remotes) ifTrue: [ 
		| remotes |
		remotes := aRepository remotes.
		(remotes respondsTo: #detect:ifNone:) ifTrue: [ 
			^ remotes
				  detect: [ :remote | 
					  (remote respondsTo: #name)
						  and: [ remote name asString = 'origin' ] ]
				  ifNone: [ remotes ifEmpty: [ nil ] ifNotEmpty: [ remotes anyOne ] ] ] ].
	^ nil
]

{ #category : 'pls - ice' }
PLSServer >> iceRepositoryStatus: aRepositoryName [

	<jrpc: #'pls-ice:repositoryStatus'>
	^ { 
		  (#stagedChanges -> (#() asArray)).
		  (#changes -> (self iceRepositoryChangesFor: aRepositoryName)) } asDictionary
]

{ #category : 'pls - ice' }
PLSServer >> iceStatusForDiffLeaf: aDiffLeaf [

	| className |
	(aDiffLeaf respondsTo: #isAddition) ifTrue: [
		aDiffLeaf isAddition ifTrue: [ ^ 'added' ] ].
	(aDiffLeaf respondsTo: #isDeletion) ifTrue: [
		aDiffLeaf isDeletion ifTrue: [ ^ 'deleted' ] ].
	(aDiffLeaf respondsTo: #isRemoval) ifTrue: [
		aDiffLeaf isRemoval ifTrue: [ ^ 'deleted' ] ].
	(aDiffLeaf respondsTo: #isConflict) ifTrue: [
		aDiffLeaf isConflict ifTrue: [ ^ 'conflicted' ] ].
	className := aDiffLeaf class name asString asLowercase.
	(className includesSubstring: 'add') ifTrue: [ ^ 'added' ].
	((className includesSubstring: 'remove') or: [ className includesSubstring: 'delete' ])
		ifTrue: [ ^ 'deleted' ].
	(className includesSubstring: 'conflict') ifTrue: [ ^ 'conflicted' ].
	^ 'modified'
]

{ #category : 'lsp - formatting' }
PLSServer >> isTonelDocument: textDocument [
	^ ((textDocument at: #uri) endsWith: 'class.st') or: [ (textDocument at: #uri) endsWith: 'extension.st' ]
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
	(self isTonelDocument: textDocument) ifTrue: [ 
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
