"
I am the server. 
I also include all the pharo language features.

Methods in `lsp` protocol are standard language server protocol feature.

Methods in `pls` protocol are pharo language server feature.
"
Class {
	#name : #PLSServer,
	#superclass : #PLSAbstractServer,
	#category : #PharoLanguageServer
}

{ #category : #'pls - variables' }
PLSServer >> childrenVariables: variableReference in: textDocument [
	<jrpc: #'pls:childrenVariables'>
	| document references currentVariable |
	document := self context
		textItem: (textDocument at: #uri at: #path).
	references := Stack newFrom: (variableReference substrings: '/').
	currentVariable := document binder compilationBindings
		at: references pop.
	[ references isEmpty ]
		whileFalse: [ | goTo |
			goTo := references pop.
			currentVariable := currentVariable instVarNamed: goTo asSymbol ].
	^ (currentVariable class allInstVarNames
		collectWithIndex: [ :name :idx | 
			PLSVariable new
				name: name;
				value: (currentVariable instVarAt: idx) printString;
				variableReference: variableReference , '/' , name;
				isDirectory: (currentVariable instVarAt: idx) class allInstVarNames isNotEmpty;
				yourself ]) asArray
]

{ #category : #'lsp - code lens' }
PLSServer >> codeLenResolves: range command: command data: aData [
	<jrpc: #'codeLens/resolve'>
	self flag: 'Not use in this version. All is done by codeLensTextDocument:'
]

{ #category : #'lsp - code lens' }
PLSServer >> codeLensTextDocument: textDocument [
	<jrpc: #'textDocument/codeLens'>
	^ (self context textItem: (textDocument at: #uri)) codeLens
]

{ #category : #commands }
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

{ #category : #commands }
PLSServer >> commandPharoLanguageServerVersion [
	<jrpc: #'command:version'>
	^ '1.0.0'
]

{ #category : #commands }
PLSServer >> commandPharoPrintIt: line textDocument: textDocumentURI [
	<jrpc: #'command:printIt'>
	"This textDocumentURI from VSCode is strange"
	| compiler answer2 | 
	compiler := self compilerFor: (textDocumentURI at: #path).
	answer2 := compiler evaluate: line.
	^ answer2 plsPrintString
]

{ #category : #commands }
PLSServer >> commandPharoSave [
	<jrpc: #'command:save'>
	SmalltalkImage current snapshot: true andQuit: false.
	^ 'Image saved'
]

{ #category : #accessing }
PLSServer >> compilerFor: fileURI [

	| compiler |
	compiler := SmalltalkImage current compiler
		            failBlock: [ nil ];
		            yourself.
	fileURI ifNotNil: [ 
		compiler requestor: (self context textItem: fileURI) binder ].
	^ compiler
]

{ #category : #'lsp - text synchronisation' }
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
	self
		sendData: (self convertJRPCJsonableObjectToJSON:
				 ((JRPCNotificationObject method:
					   'textDocument/publishDiagnostics') params:
					  document diagnostics) asJRPCJSON)
		toClient: clientOutStream
]

{ #category : #'lsp - text synchronisation' }
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

{ #category : #'lsp - text synchronisation' }
PLSServer >> didOpen: textDocument [
	<jrpc: #'textDocument/didOpen'>
	| document |
	document := self context
		textItem: (textDocument at: #uri)
		put: (PLSDocument from: textDocument).
	(self isTonelDocument: textDocument)
		ifFalse: [ self
				sendData:
					(self
						convertJRPCJsonableObjectToJSON:
							((JRPCNotificationObject method: 'textDocument/publishDiagnostics')
								params:
									((PLSDiagnosticsParamsEngine document: document)
										requestor: document binder)
										computeDiagnostics) asJRPCJSON)
				toClient: clientOutStream ]
]

{ #category : #'lsp - text synchronisation' }
PLSServer >> didSave: textDocument text: text [
	<jrpc: #'textDocument/didSave'>
	"Install the code in the image if the code is part of a tonel file"
	((textDocument at: #uri) endsWith: 'class.st')
		ifTrue: [ (PLSTonelParser parseString: text asByteArray utf8Decoded) do: #load ]
]

{ #category : #'lsp - document symbol' }
PLSServer >> documentSymbol: textDocument [
	<jrpc: #'textDocument/documentSymbol'>
	| document |
	document := self context textItem: (textDocument at: #uri).
	^ document symbols
]

{ #category : #'pls - variables' }
PLSServer >> documentVariables: textDocument [
	<jrpc: #'pls:documentVariables'>
	| document |
	document := self context
		textItem: (textDocument at: #uri at: #path).
	^ (document binder compilationBindings associations
		collect: [ :assoc |
			  PLSVariable new
				name: assoc key printString;
				value: assoc value printString;
				variableReference: assoc key;
				isDirectory: assoc value class allInstVarNames isNotEmpty;
				yourself ]
		as: Array) asJRPCJSON
]

{ #category : #'lsp - formatting' }
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

{ #category : #'pls - ice' }
PLSServer >> iceRepositories [

	<jrpc: #'pls-ice:repositories'>
	^ (IceRepository registry collect: [ :repository | 
		   { 
			   (#name -> repository name).
			   (#valid -> repository isValid) } asDictionary ]) asArray
]

{ #category : #'pls - ice' }
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

{ #category : #'lsp - formatting' }
PLSServer >> isTonelDocument: textDocument [
	^ ((textDocument at: #uri) endsWith: 'class.st') or: [ (textDocument at: #uri) endsWith: 'extension.st' ]
]

{ #category : #'lsp - completion' }
PLSServer >> oldTextDocumentInlineCompletionWithContext: context position: position textDocument: textDocument [

	"<jrpc: #'textDocument/inlineCompletion'>"
	| internalTextDocument api answer |
	(HFAPI apiKey isNil or: [ HFAPI apiKey isEmpty ])
		ifTrue: [ answer := 'Set a HuggingFace API KEY in the settings' ]
		ifFalse: [
			[
			internalTextDocument := self context textItem:
				                        (textDocument at: #uri).
			api := HFAPI new.
			api model: HFCodeLlama13bModel new.
			api return_full_text: false.
			api max_new_tokens: 50.
			api max_time: 2.
			answer := api query:
				          'Complete the following code.
Be creative! Only give me the code without any explanation. Do not add comment in the code.
```st
' , internalTextDocument text , '
```' ]
				on: HFAPIError
				do: [ answer := 'HuggingFace rate limit' ] ].
	^ (PLSInlineCompletionList new
		   items: { (PLSInlineCompletionItem new insertText: answer) };
		   yourself) asJRPCJSON
]

{ #category : #'lsp - initialization' }
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
	^ PLSInitializeResult new
]

{ #category : #pls }
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

{ #category : #pls }
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

{ #category : #pls }
PLSServer >> plsGetClassContent: class [
	<jrpc: #'pls:classContent'>
	| className |
	className := ((class substrings: '/' )last  withoutSuffix: '.st') withoutSuffix: '.class'.
	^ String
		streamContents:
			[ :stream | TonelWriter exportClass: (self class environment at: className asSymbol) on: stream ]
]

{ #category : #pls }
PLSServer >> plsGetClasses: package [
	<jrpc: #'pls:classes'>
	^ [ package asPackage classes
		collect: [ :class | package , '/' , class name , '.class.st' ]
		as: Array ]
		on: Error
		do: [ {} asArray ]
]

{ #category : #pls }
PLSServer >> plsGetPackages [
	<jrpc: #'pls:packages'>
	^ (RPackageOrganizer default packages collect: #name)
		asArray
]

{ #category : #'pls - gtk' }
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

	(StInspector onObject: answer2)
		application: app;
		openWithSpec ]
		on: Error
		do: [ :err | ^ err message printString ].
	'opened with spec' record.
	^ 'ok'
]

{ #category : #'pls - developer' }
PLSServer >> plsOpenLog [

	<jrpc: #'pls-developer:openLog'>
	(TinyLogger default ensureMoreFileLoggerNamed: 'LSP.log') open.
	^ 'success'
]

{ #category : #'pls - developer' }
PLSServer >> plsResetLog [

	<jrpc: #'pls-developer:clearLog'>
	(TinyLogger default ensureMoreFileLoggerNamed: 'LSP.log') clearLog.
	^ 'success'
]

{ #category : #'lsp - initialization' }
PLSServer >> serverInitialized [

	<jrpc: #initialized>
	Transcript crShow: 'Initialized'
]

{ #category : #'lsp - initialization' }
PLSServer >> serverShutdown [

	<jrpc: #shutdown>
	SmalltalkImage current snapshot: false andQuit: true
]

{ #category : #dap }
PLSServer >> startDapServer [
	<jrpc: #'dap:startServer'>
	'Start DAP Server.' record.
	^ DAPServer new
		start.
]

{ #category : #'lsp - completion' }
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

{ #category : #'lsp - hover' }
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

{ #category : #'lsp - completion' }
PLSServer >> textDocumentInlineCompletionWithContext: context position: position textDocument: textDocument [

	<jrpc: #'textDocument/inlineCompletion'>
	| internalTextDocument api answer |
	(HFAPI apiKey isNil or: [ HFAPI apiKey isEmpty ])
		ifTrue: [ answer := 'Set a HuggingFace API KEY in the settings' ]
		ifFalse: [
			[
			internalTextDocument := self context textItem:
				                        (textDocument at: #uri).
			api := HFAPI new.
			api model: HFCodeLlama13bModel new.
			api return_full_text: false.
			api temperature: 1.
			api max_new_tokens: 50.
			api max_time: 2.
			answer := api query:
				          '<PRE> ' , internalTextDocument text , '
<SUF> <MID>' ]
				on: HFAPIError
				do: [ answer := 'HuggingFace rate limit' ] ].
	^ (PLSInlineCompletionList new
		   items: { (PLSInlineCompletionItem new insertText: answer) };
		   yourself) asJRPCJSON
]

{ #category : #'lsp - signature help' }
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

{ #category : #'lsp - type definition' }
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

{ #category : #'lsp - text synchronisation' }
PLSServer >> willSave: textDocument reason: reason [
	<jrpc: #'textDocument/willSave'>
	1h
]

{ #category : #'lsp - text synchronisation' }
PLSServer >> willSaveUntil: textDocument reason: reason [
	<jrpc: #'textDocument/willSaveWaitUntil'>
	1h
]
