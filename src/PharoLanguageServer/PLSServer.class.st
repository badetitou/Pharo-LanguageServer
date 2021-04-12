"
server := PLSServer new
	debugMode: true;
	enableLogging: true.

server start.

server stop.


server messageProcessor 
"
Class {
	#name : #PLSServer,
	#superclass : #JRPCServer,
	#traits : 'JRPCParser',
	#classTraits : 'JRPCParser classTrait',
	#instVars : [
		'port',
		'tcpServer',
		'serverLoop',
		'process',
		'serverContext',
		'data',
		'messagesProcesses',
		'socketClient'
	],
	#category : #PharoLanguageServer
}

{ #category : #defaults }
PLSServer class >> defaultPort [
	^ 4000
]

{ #category : #defaults }
PLSServer class >> reset [
	<script>
	PLSServer
		allInstancesDo: [ :inst | 
			[ inst stop ]
				on: Error
				do: [ Transcript crShow: 'one server not stopped' ] ]
]

{ #category : #lsp }
PLSServer >> cancelRequest: id [
	<jrpc: #'$/cancelRequest' >
	self context messageProcesses
		at: id
		ifPresent: [ :process2 | process2 terminate ]
		ifAbsent: [ ]
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
PLSServer >> commandNotebookPrintIt: line [
	<jrpc: #'command:notebookPrintIt'>
	| compiler answer |
	compiler := self compilerFor: nil.
	answer := [ compiler evaluate: line ] on: Error do: [ :error | error ].
	^ {(#mimetype -> answer plsMimeType).
	(#content -> answer plsPrintString)} asDictionary
]

{ #category : #commands }
PLSServer >> commandPharoLanguageServerVersion [
	<jrpc: #'command:version'>
	^ '1.0.0'
]

{ #category : #commands }
PLSServer >> commandPharoPrintIt: line [
	<jrpc: #'command:printIt'>
	| compiler answer | 
	compiler := self compilerFor: nil.
	answer := compiler evaluate: line.
	^ answer plsPrintString
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
		requestor: (self context compilationBindingsAt: fileURI);
		yourself.
	^ compiler
]

{ #category : #context }
PLSServer >> context [
	^ serverContext
]

{ #category : #stopping }
PLSServer >> defaultPort [
	^ self class defaultPort
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
	(self isTonelDocument: textDocument)
		ifFalse: [ self
				sendData:
					(self
						convertJRPCJsonableObjectToJSON:
							((JRPCNotificationObject method: 'textDocument/publishDiagnostics')
								params:
									((PLSDiagnosticsParamsEngine document: document)
										requestor: (self context compilationBindingsAt: (textDocument at: #uri)))
										computeDiagnostics) asJRPCJSON)
				toClient: socketClient ]
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
										requestor: (self context compilationBindingsAt: (textDocument at: #uri)))
										computeDiagnostics) asJRPCJSON)
				toClient: socketClient ]
]

{ #category : #'lsp - text synchronisation' }
PLSServer >> didSave: textDocument text: text [
	<jrpc: #'textDocument/didSave'>
	"Install the code in the image if the code is part of a tonel file"
	((textDocument at: #uri) endsWith: 'class.st')
		ifTrue: [ (TonelParser parseString: text asByteArray utf8Decoded) do: #load ]
]

{ #category : #'lsp - document symbol' }
PLSServer >> documentSymbol: textDocument [
	<jrpc: #'textDocument/documentSymbol'>
	| document |
	document := self context textItem: (textDocument at: #uri).
	^ document symbols
]

{ #category : #starting }
PLSServer >> extractLengthOf: data [
	(data beginsWith: 'Content-Length: ')
		ifTrue:
			[ ^ (data copyFrom: 16 to: (data indexOf: Character cr)) asInteger ]
		ifFalse: [ ^ -1 ]
]

{ #category : #starting }
PLSServer >> extractRequestFrom: clientSocket [
	| length startingPoint endPoint result |
	"data is the current buffer state"
	data ifEmpty: [ data := clientSocket receiveData ].
	length := self extractLengthOf: data.
	startingPoint := data indexOf: ${.
	endPoint := data findCloseBracesFor: startingPoint.
	result := String new: length.
	"three options"
	"startingPoint and endPoint are found"
	(startingPoint ~= 0 and: [ endPoint ~= 0 ])
		ifTrue: [ result := data copyFrom: startingPoint to: endPoint.
			data := data copyFrom: endPoint + 1 to: data size.
			^ result ].
	startingPoint = 0
		ifTrue:
			[ "none were found" self getDatafromPosition: 1 fromSocket: clientSocket in: result ]
		ifFalse: [ "only startingPoint is found"
			(data copyFrom: startingPoint to: data size)
				withIndexDo: [ :each :index | result at: index put: each ].
			self
				getDatafromPosition: data size - startingPoint + 2
				fromSocket: clientSocket
				in: result ].
	data := ''.
	^ result
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

{ #category : #starting }
PLSServer >> getDatafromPosition: startingPoint fromSocket: clientSocket in: existingData [
	clientSocket receiveDataInto: existingData startingAt: startingPoint
]

{ #category : #starting }
PLSServer >> getHeaderFor: answer into: aStream [
	aStream << 'Content-Length: ' << answer utf8Encoded size asString << String crlf << 'Content-Type: application/vscode-jsonrpc; charset=utf-8'
		<< String crlf << String crlf
]

{ #category : #starting }
PLSServer >> handleRequest: request toClient: clientSocket [
	| jrpcMessage |
	jrpcMessage := [ self parseJSON: request ]
		on: Error
		do: [ :err | err return: err asJRPCResponse ].
	^ self messageProcess: jrpcMessage id
		put:
			([ self
				sendData: (self handleJSON: jrpcMessage)
				toClient: clientSocket.
			self removeMessageProcess: jrpcMessage id ]
				forkAt: Processor lowIOPriority
				named: jrpcMessage method)
]

{ #category : #starting }
PLSServer >> initialize [
	super initialize.
	messageProcessor := PLSMessageProcessor new.
	self addHandlersFromPragmasIn: self.
	serverContext := PLSContext new.
	data := ''.
	messagesProcesses := Dictionary new.
]

{ #category : #'lsp - formatting' }
PLSServer >> isTonelDocument: textDocument [
	^ ((textDocument at: #uri) endsWith: 'class.st') or: [ (textDocument at: #uri) endsWith: 'extension.st' ]
]

{ #category : #context }
PLSServer >> messageProcess: anId	put: aProcess [
	self context messageProcessesAt: anId put: aProcess
]

{ #category : #lsp }
PLSServer >> onInitializeTrace: trace processId: processId clientInfo: clientInfo rootPath: rootPath workspaceFolders: workspaceFolders capabilities: capabilities rootUri: rootUri [
	<jrpc: #initialize>
	^ PLSInitializeResult new
]

{ #category : #starting }
PLSServer >> parseJSON: aJSONString [
	^ self messageProcessor parseSupposedJRPCMessageObjectFromString: aJSONString.
	
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

{ #category : #stopping }
PLSServer >> port [
	^ port ifNil: [ port := self defaultPort ]
]

{ #category : #stopping }
PLSServer >> port: anObject [
	port := anObject
]

{ #category : #context }
PLSServer >> removeMessageProcess: anId [
	self context removeMessageProcess: anId
]

{ #category : #context }
PLSServer >> resetContext [
	serverContext := PLSContext new
]

{ #category : #starting }
PLSServer >> sendData: answer toClient: clientSocket [

	answer
		ifNotEmpty: [ clientSocket
				sendData:
					(String
						streamContents:
							[ :contentStream | self getHeaderFor: answer into: contentStream ]).
			clientSocket sendData: answer utf8Encoded  ]
]

{ #category : #lsp }
PLSServer >> serverInitialized [
	<jrpc: #initialized>
	Transcript crTrace: 'Initialized'
]

{ #category : #lsp }
PLSServer >> serverShutdown [
	<jrpc: #shutdown>
	SmalltalkImage current snapshot: false andQuit: true
]

{ #category : #'lsp - trace' }
PLSServer >> setTrace: setTraceParam [
	<jrpc: #'$/setTrace'>
]

{ #category : #'lsp - trace' }
PLSServer >> setTraceNotification: value [
	<jrpc: #'$/setTraceNotification'>
]

{ #category : #lsp }
PLSServer >> showMessage: aString ofType: aMessageType toClient: aClient [
	"The show message notification is sent from a server to a client to ask the client to display a particular message in the user interface"

	self
		sendData:
			(self convertJRPCJsonableObjectToJSON: (JRPCNotificationObject new
				method: 'window/showMessage';
				params:
					{(#message -> aString).
					(#type -> aMessageType)} asDictionary) asJRPCJSON)
		toClient: aClient
]

{ #category : #starting }
PLSServer >> start [
	tcpServer := Socket newTCP.
	tcpServer listenOn: 0 backlogSize: 10.
	Stdio stdout nextPutAll: tcpServer port asString asByteArray.
	serverLoop := true.
	(tcpServer waitForAcceptFor: 60)
		ifNotNil: [ :clientSocket |
			socketClient := clientSocket.
			process := [ [ serverLoop ]
				whileTrue: [ | request |
					request := self extractRequestFrom: clientSocket.
					self handleRequest: request toClient: clientSocket ] ]
				forkAt: Processor lowIOPriority
				named: 'JRPC TCP connection' ]
]

{ #category : #dap }
PLSServer >> startDapServer [
	<jrpc: #'dap:startServer'>
	^ DAPServer new
		start.
]

{ #category : #stopping }
PLSServer >> stop [
	serverLoop := false.
	tcpServer closeAndDestroy.
	
	"Ensure process finishes."
	process isTerminated
		ifTrue: [ ^ self ].
	process terminate
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
	| hover |
	hover := PLSHover new
		context: self context;
		source: (self context textItem: (textDocument at: #uri)) text;
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
