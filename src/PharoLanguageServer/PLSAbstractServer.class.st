"
I am the base of the Pharo language server: I read JSON-RPC messages from the client and answer them.

Each incoming message is handled in its own process (see `handleRequest:toClient:`).

Messaging rules:
- A `<jrpc:>` handler answers its result; `handleRequest:toClient:` sends the response. A handler never writes the response itself.
- A handler, or any other code, that must push something to the client uses `sendNotification:params:` or `sendRequest:params:`.
- `sendMessage:` is the single entry point writing to the client. It writes each message as one framed block while holding `outputMutex`, so messages sent from concurrent processes are never interleaved.
"
Class {
	#name : 'PLSAbstractServer',
	#superclass : 'JRPCServer',
	#traits : 'JRPCParser + TPLPCommon',
	#classTraits : 'JRPCParser classTrait + TPLPCommon classTrait',
	#instVars : [
		'port',
		'process',
		'serverContext',
		'messagesProcesses',
		'clientInStream',
		'clientOutStream',
		'outputMutex'
	],
	#category : 'PharoLanguageServer',
	#package : 'PharoLanguageServer'
}

{ #category : 'defaults' }
PLSAbstractServer class >> defaultPort [

	^ 0
]

{ #category : 'class initialization' }
PLSAbstractServer class >> reset [
	"Stop the language servers of the image, and the MCP servers they started, including the ones a saved image restarted by itself"

	<script>
	PLSServer allInstancesDo: [ :inst |
			[ inst stop ]
				on: Error
				do: [ ] ].
	self environment
		at: #PLSMCPEndpoint
		ifPresent: [ :endpointClass | endpointClass stopAll ]
]

{ #category : 'lsp - workspace' }
PLSAbstractServer >> applyWorkspaceEdit: workspaceEdit withLabel: aLabel [

	self
		sendRequest: 'workspace/applyEdit'
		params: (PLSApplyWorkspaceEditParams new
				 label: aLabel;
				 edit: workspaceEdit;
				 yourself)
]

{ #category : 'lsp - initialization' }
PLSAbstractServer >> cancelRequest: id [

	<jrpc: #'$/cancelRequest' >
	self context messageProcesses
		at: id
		ifPresent: [ :process2 |
			process2 terminate.
			self context messageProcesses removeKey: id ]
		ifAbsent: [  ]
]

{ #category : 'accessing' }
PLSAbstractServer >> clientOutStream [

	^ clientOutStream
]

{ #category : 'accessing' }
PLSAbstractServer >> clientOutStream: anObject [

	clientOutStream := anObject
]

{ #category : 'lsp - code action' }
PLSAbstractServer >> codeActionForDocument: textDocument atRange: range withContext: context [

	<jrpc: #'textDocument/codeAction'>

]

{ #category : 'lsp - code lens' }
PLSAbstractServer >> codeLensTextDocument: textDocument [

	<jrpc: #'textDocument/codeLens'>
	^ (self context textItem: (textDocument at: #uri)) codeLens
]

{ #category : 'plp - debug' }
PLSAbstractServer >> configDebugMode: debugMode [

	<jrpc: #'pls:updateDebugMode'>
	self debugMode: debugMode.
	self answerLoopPriority: Processor lowestPriority.
	process ifNotNil: [ :aProcess |
		aProcess priority: self answerLoopPriority ].
	^ debugMode
]

{ #category : 'context' }
PLSAbstractServer >> context [
	^ serverContext
]

{ #category : 'stopping' }
PLSAbstractServer >> defaultPort [
	^ self class defaultPort
]

{ #category : 'lsp - diagnostics' }
PLSAbstractServer >> documentDiagnosticFor: textDocument withIdentifier: identifier andPreviousResult: previousResultId [

	<jrpc: #'textDocument/diagnostic'>
	| diagnosticsReport document |
	diagnosticsReport := PLSFullDocumentDiagnosticsReport new.
	document := self context textItem: (textDocument at: #uri).

	^ (diagnosticsReport
		   items: document diagnostics asArray;
		   yourself) asJRPCJSON
]

{ #category : 'starting' }
PLSAbstractServer >> getHeaderFor: answer into: aStream [
	aStream << 'Content-Length: ' << answer utf8Encoded size asString << String crlf << 'Content-Type: application/vscode-jsonrpc; charset=utf-8'
		<< String crlf << String crlf
]

{ #category : 'starting' }
PLSAbstractServer >> handleRequest: request toClient: clientSocket [

	| jrpcMessage |
	jrpcMessage := [ self parseJSON: request ]
		               on: Error
		               do: [ :err |
			               self debugMode
				               ifTrue: [ err pass ]
				               ifFalse: [ err return: err asJRPCResponse ] ].
	jrpcMessage id ifNotNil: [
		currentId := currentId max: jrpcMessage id asInteger ].
	^ self messageProcess: jrpcMessage id put: ([
		   self
			   sendData: (self handleJSON: jrpcMessage)
			   toClient: clientSocket.
		   [ self removeMessageProcess: jrpcMessage id ]
			   on: KeyNotFound
			   do: [  ] ]
			   forkAt: self answerLoopPriority
			   named: jrpcMessage id printString)
]

{ #category : 'initialization' }
PLSAbstractServer >> initialize [

	super initialize.
	messageProcessor := PLSMessageProcessor new.
	self addHandlersFromPragmasIn: self.
	self debugMode: false.
	serverContext := PLSContext for: self.
	withStdIO := false.
	messagesProcesses := Dictionary new.
	outputMutex := Mutex new.
	answerLoop := true.
	answerLoopPriority := Processor lowIOPriority.
	currentId := 0
]

{ #category : 'starting' }
PLSAbstractServer >> initializeStreams [

	| tcpServer |
	withStdIO ifTrue: [ 
		clientInStream := Stdio stdin.
		clientOutStream := Stdio stdout.
		^ self ].
	tcpServer := Socket newTCP.
	tcpServer listenOn: self port backlogSize: 10.
	self port: tcpServer port.
	Stdio stdout nextPutAll: tcpServer port asString asByteArray.
	Stdio stdout flush.
	answerLoop := true.
	(tcpServer waitForAcceptFor: 60) ifNotNil: [ :clientSocket | 
		clientInStream := SocketStream on: clientSocket.
		clientOutStream := clientInStream.
		self
			logMessage: 'Client connected to Server using socket'
			ofType: PLSMessageType info ]
]

{ #category : 'lsp - trace' }
PLSAbstractServer >> log: aString [

	self logTrace: aString withAdditionnalInformation: ''
]

{ #category : 'lsp - message' }
PLSAbstractServer >> logMessage: aString ofType: messageType [
	"The show message notification is sent from a server to a client to ask the client to display a particular message in the user interface"

	self
		sendNotification: 'window/logMessage'
		params: (PLSLogMessage message: aString type: messageType)
]

{ #category : 'lsp - trace' }
PLSAbstractServer >> logTrace: aString withAdditionnalInformation: verboseString [
	"A notification to log the trace of the server’s execution."

	| trace |
	self context traceValue = PLSTraceValue off ifTrue: [ ^ self ].
	trace := PLSLogTraceParams new.
	trace message: aString.
	self context traceValue = PLSTraceValue verbose ifTrue: [
		trace verbose: verboseString ].
	self sendNotification: '$/logTrace' params: trace
]

{ #category : 'context' }
PLSAbstractServer >> messageProcess: anId	put: aProcess [
	self context messageProcessesAt: anId put: aProcess
]

{ #category : 'plp - base protocol' }
PLSAbstractServer >> notifyMethod: aMethodString arguments: arguments [

	self sendNotification: aMethodString params: arguments
]

{ #category : 'lsp - initialization' }
PLSAbstractServer >> onInitializeTrace: trace processId: processId locale: locale clientInfo: clientInfo rootPath: rootPath workspaceFolders: workspaceFolders capabilities: capabilities rootUri: rootUri initializationOptions: initializationOptions [

	<jrpc: #initialize>
	self subclassResponsibility
]

{ #category : 'starting' }
PLSAbstractServer >> parseJSON: aJSONString [
	^ self messageProcessor parseSupposedJRPCMessageObjectFromString: aJSONString.
	
]

{ #category : 'stopping' }
PLSAbstractServer >> port [
	^ port ifNil: [ port := self defaultPort ]
]

{ #category : 'stopping' }
PLSAbstractServer >> port: anObject [
	port := anObject
]

{ #category : 'lsp - completion' }
PLSAbstractServer >> postDealAnswer: answer [
	"a utility method to remove markdown notation. Helpfull for some server that uses AI behind the scene"

	(answer beginsWith: '```') ifTrue: [
		| lines realAnswer |
		lines := answer lines.
		realAnswer := String streamContents: [ :str |
			              lines
				              from: 2
				              to: lines size - 1
				              do: [ :line | str << line ] ].
		^ realAnswer trimBoth ].
	^ answer trimBoth
]

{ #category : 'context' }
PLSAbstractServer >> removeMessageProcess: anId [
	self context removeMessageProcess: anId
]

{ #category : 'context' }
PLSAbstractServer >> resetContext [
	serverContext := PLSContext for: self
]

{ #category : 'starting' }
PLSAbstractServer >> sendData: answer2 toClient: stream [
	"Write answer2 as one framed message. Use sendMessage: rather than calling me directly"

	| message |
	answer2 ifEmpty: [ ^ self ].
	message := ByteArray streamContents: [ :bytes |
		           bytes nextPutAll:
			           (String streamContents: [ :header |
				            self getHeaderFor: answer2 into: header ]) asByteArray.
		           bytes nextPutAll: answer2 utf8Encoded ].
	outputMutex critical: [
		stream nextPutAll: message.
		stream flush ]
]

{ #category : 'lsp - diagnostics' }
PLSAbstractServer >> sendDiagnosticsforDocument: document [

	self
		sendNotification: 'textDocument/publishDiagnostics'
		params: (PLSPublishDiagnosticsParams new
				 diagnostics: document diagnostics;
				 uri: document uri;
				 version: document version;
				 yourself)
]

{ #category : 'messaging' }
PLSAbstractServer >> sendMessage: aJRPCObject [
	"Single entry point to write a message (response, notification or request) to the client"

	self
		sendData:
		(self convertJRPCJsonableObjectToJSON: aJRPCObject asJRPCJSON)
		toClient: clientOutStream
]

{ #category : 'messaging' }
PLSAbstractServer >> sendNotification: aMethodString params: params [

	self sendMessage:
		((JRPCNotificationObject method: aMethodString) params: params)
]

{ #category : 'messaging' }
PLSAbstractServer >> sendRequest: aMethodString params: params [
	"Send a request to the client and answer its id"

	| id |
	id := self nextId.
	self sendMessage:
		((JRPCRequestObject id: id method: aMethodString) params: params).
	^ id
]

{ #category : 'lsp - telemetry' }
PLSAbstractServer >> sendTelemetry: anObject [
	"anObject must be an array or a dictionary (after asJRPCJSON)"
	self sendNotification: 'telemetry/event' params: anObject
]

{ #category : 'lsp - initialization' }
PLSAbstractServer >> serverExit [

	<jrpc: #exit>
	SmalltalkImage current snapshot: false andQuit: true
]

{ #category : 'lsp - initialization' }
PLSAbstractServer >> serverInitialized [

	<jrpc: #initialized>
	self logTrace: 'initialized' withAdditionnalInformation: ''
]

{ #category : 'lsp - initialization' }
PLSAbstractServer >> serverShutdown [

	<jrpc: #shutdown>
	self serverExit.
	^ nil
]

{ #category : 'lsp - trace' }
PLSAbstractServer >> setTrace: value [

	<jrpc: #'$/setTrace' >
	self context traceValue: value
]

{ #category : 'lsp - show document' }
PLSAbstractServer >> showDocument: documentURI external: aBooleanOrNil withFocus: focusBooleanOrNil atRange: aPLSRangeOrNil [
	
	self
		sendRequest: 'window/showDocument'
		params: (PLSShowDocument new
				 uri: documentURI;
				 external: aBooleanOrNil;
				 takeFocus: focusBooleanOrNil;
				 selection: aPLSRangeOrNil;
				 yourself)
]

{ #category : 'lsp - message' }
PLSAbstractServer >> showMessage: aString ofType: messageType [
	"The show message notification is sent from a server to a client to ask the client to display a particular message in the user interface"

	self
		sendNotification: 'window/showMessage'
		params: (PLSShowMessage message: aString type: messageType)
]

{ #category : 'starting' }
PLSAbstractServer >> start [

	self debugMode ifFalse: [ PLSUIManager withPLSServer: self ].
	self initializeStreams.
	currentId := 0.
	self startAnswerLoop
]

{ #category : 'stopping' }
PLSAbstractServer >> stop [

	answerLoop := false.
	clientInStream ifNotNil: [ clientInStream close ].
	clientOutStream ifNotNil: [ clientOutStream close ].

	"Ensure process finishes."
	process ifNotNil: [
		process isTerminated ifTrue: [ ^ self ].
		process terminate ]
]

{ #category : 'lsp - successResponse' }
PLSAbstractServer >> successJRPCResponse: aJRPCResponse [
	"I handle generic SuccessJRPCResponse after I send message"

	
]

{ #category : 'lsp - completion' }
PLSAbstractServer >> textDocumentCompletionWithContext: context position: position textDocument: textDocument [
	<jrpc: #'textDocument/completion'>
	self subclassResponsibility 
]

{ #category : 'lsp - hover' }
PLSAbstractServer >> textDocumentHoverWithPosition: position textDocument: textDocument [
	<jrpc: #'textDocument/hover'>
	self subclassResponsibility
]

{ #category : 'lsp - completion' }
PLSAbstractServer >> textDocumentInlineCompletionWithContext: context position: position textDocument: textDocument [

	<jrpc: #'textDocument/inlineCompletion'>
	self subclassResponsibility
]

{ #category : 'lsp - text synchronisation' }
PLSAbstractServer >> willSave: textDocument reason: reason [
	<jrpc: #'textDocument/willSave'>
	1h
]

{ #category : 'lsp - text synchronisation' }
PLSAbstractServer >> willSaveUntil: textDocument reason: reason [
	<jrpc: #'textDocument/willSaveWaitUntil'>
	1h
]
