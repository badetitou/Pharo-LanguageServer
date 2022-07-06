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
		textItem: (textDocument at: #uri at: #external).
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
	| compiler answer2  |
	"Use path because #external also uses the fragment number of the cell"
	compiler := self compilerFor: (textDocumentURI at: #path).
	answer2 := [ compiler evaluate: line ] on: Exception do: [ :error | 'error' record. error ].
	^ {(#mimetype -> answer2 plsMimeType).
	(#content -> answer2 plsPrintString)} asDictionary
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
		            transformDoit;
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
		ifAbsent: [ self didOpen: textDocument.
			textDocument ].
	document version: (textDocument at: #version).
	document text: (contentChanges anyOne at: #text).
	self
		sendData:
			(self
				convertJRPCJsonableObjectToJSON:
					((JRPCNotificationObject method: 'textDocument/publishDiagnostics')
						params: document diagnostics) asJRPCJSON  )
		toClient: socketClient
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
				toClient: socketClient ]
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
				toClient: socketClient ]
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
		textItem: (textDocument at: #uri at: #external).
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

{ #category : #'lsp - formatting' }
PLSServer >> isTonelDocument: textDocument [
	^ ((textDocument at: #uri) endsWith: 'class.st') or: [ (textDocument at: #uri) endsWith: 'extension.st' ]
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
	| app compiler |
	compiler := self compilerFor: (textDocumentURI at: #path).
	answer := [ compiler evaluate: line ] on: Exception do: [ :error | 'error' record. error ].
	[ 
	app := SpApplication new
		       useBackend: #Gtk;
		       yourself.

	(StInspector onObject: answer)
		application: app;
		openWithSpec ]
		on: Error
		do: [ :err | ^ err message printString ].
	'opened with spec' record.
	^ 'ok'
]

{ #category : #'lsp - trace' }
PLSServer >> setTrace: setTraceParam [
	<jrpc: #'$/setTrace'>
]

{ #category : #'lsp - trace' }
PLSServer >> setTraceNotification: value [
	<jrpc: #'$/setTraceNotification'>
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
		source: (self context textItem: (textDocument at: #uri)) text;
		position: position;
		yourself.
	(self isTonelDocument: textDocument)
		ifTrue: [ completionTool
				sourceClass:
					(([ PLSTonelParser
						parseString: (self context textItem: (textDocument at: #uri)) text ]
						on: Error
						do: [ ^ {} ]) detect: #isClassDefinition) actualClass ].
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
	((canBeClass isKindOf: RBProgramNode) not or: [ canBeClass isVariable not ]) ifTrue: [ ^ {  } ].
	aClass := self class environment
		at: canBeClass name asSymbol
		ifAbsent: [ ^ {} ].
	aClass isClass
		ifFalse: [ ^ {} ].
	^ PLSLocation new
		uri:
			'pharoImage://' , aClass package name , '/' , aClass name
				, '.class.st';
		range:
			(PLSRange
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
