Class {
	#name : #PLSAbstractServer,
	#superclass : #JRPCServer,
	#traits : 'JRPCParser',
	#classTraits : 'JRPCParser classTrait',
	#instVars : [
		'port',
		'serverLoop',
		'process',
		'serverContext',
		'data',
		'messagesProcesses',
		'clientInStream',
		'clientOutStream',
		'lastId',
		'withStdIO'
	],
	#category : #PharoLanguageServer
}

{ #category : #defaults }
PLSAbstractServer class >> defaultPort [
	^ 0
]

{ #category : #defaults }
PLSAbstractServer class >> reset [
	<script>
	PLSServer
		allInstancesDo: [ :inst | 
			[ inst stop ]
				on: Error
				do: [ Transcript crShow: 'one server not stopped' ] ]
]

{ #category : #'lsp - initialization' }
PLSAbstractServer >> buildClientContextFromTrace: trace processId: processId locale: locale clientInfo: clientInfo rootPath: rootPath workspaceFolders: workspaceFolders capabilities: capabilities rootUri: rootUri [

	self context clientContext: (PLSClientContext new
			 trace: trace;
			 processId: processId;
			 locale: locale;
			 clientInfo: clientInfo;
			 rootPath: rootPath;
			 workspaceFolders: workspaceFolders;
			 capabilities: capabilities;
			 rootUri: rootUri;
			 yourself)
]

{ #category : #'lsp - initialization' }
PLSAbstractServer >> cancelRequest: id [
	<jrpc: #'$/cancelRequest' >
	self context messageProcesses
		at: id
		ifPresent: [ :process2 | process2 terminate ]
		ifAbsent: [ ]
]

{ #category : #accessing }
PLSAbstractServer >> clientOutStream [

	^ clientOutStream
]

{ #category : #accessing }
PLSAbstractServer >> clientOutStream: anObject [

	clientOutStream := anObject
]

{ #category : #'lsp - code action' }
PLSAbstractServer >> codeActionForDocument: textDocument atRange: range withContext: context [

	<jrpc: #'textDocument/codeAction'>

]

{ #category : #'pls - config' }
PLSAbstractServer >> configDebugMode: debugMode [

	<jrpc: #'pls:updateDebugMode'>
	self debugMode: debugMode.
	^ debugMode
]

{ #category : #context }
PLSAbstractServer >> context [
	^ serverContext
]

{ #category : #stopping }
PLSAbstractServer >> defaultPort [
	^ self class defaultPort
]

{ #category : #'lsp - diagnostics' }
PLSAbstractServer >> documentDiagnosticFor: textDocument withIdentifier: identifier andPreviousResult: previousResultId [
	<jrpc: #'textDocument/diagnostic'>
]

{ #category : #starting }
PLSAbstractServer >> extractLengthOf: data [
	(data beginsWith: 'Content-Length: ')
		ifTrue:
			[ ^ (data copyFrom: 16 to: (data indexOf: Character cr)) asInteger ]
		ifFalse: [ ^ -1 ]
]

{ #category : #starting }
PLSAbstractServer >> extractRequestFrom: stream [

	| length startingPoint endPoint result |
	"data is the current buffer state"
	length := -1.
	[ length = -1 and: [ serverLoop ] ] whileTrue: [ 
		[ data ifEmpty: [ data := (stream next: 25) asString ] ]
			on: ConnectionTimedOut
			do: [ self log: 'timeout but still work' ].
		length := self extractLengthOf: data ].
	startingPoint := data indexOf: ${.
	endPoint := data findCloseBracesFor: startingPoint.
	result := String new: length.
	"three options"
	"startingPoint and endPoint are found"
	(startingPoint ~= 0 and: [ endPoint ~= 0 ]) ifTrue: [ 
		result := data copyFrom: startingPoint to: endPoint.
		data := data copyFrom: endPoint + 1 to: data size.
		^ result ].
	startingPoint = 0
		ifTrue: [ "none were found" 
			self getDatafromPosition: 1 fromSocket: stream in: result ]
		ifFalse: [ "only startingPoint is found"
			(data copyFrom: startingPoint to: data size) withIndexDo: [ 
				:each 
				:index | result at: index put: each ].
			self
				getDatafromPosition: data size - startingPoint + 2
				fromSocket: stream
				in: result ].
	data := ''.
	^ result
]

{ #category : #starting }
PLSAbstractServer >> getDatafromPosition: startingPoint fromSocket: clientSocket in: existingData [
	clientSocket nextInto: existingData startingAt: startingPoint
]

{ #category : #starting }
PLSAbstractServer >> getHeaderFor: answer into: aStream [
	aStream << 'Content-Length: ' << answer utf8Encoded size asString << String crlf << 'Content-Type: application/vscode-jsonrpc; charset=utf-8'
		<< String crlf << String crlf
]

{ #category : #starting }
PLSAbstractServer >> handleRequest: request toClient: clientSocket [

	| jrpcMessage |
	jrpcMessage := [ self parseJSON: request ]
		               on: Error
		               do: [ :err | 
			               self debugMode
				               ifTrue: [ err pass  ]
				               ifFalse: [ err return: err asJRPCResponse ] ].
	jrpcMessage id ifNotNil: [ 
		lastId := lastId max: jrpcMessage id asInteger ].
	^ self messageProcess: jrpcMessage id put: ([ 
		   self
			   sendData: (self handleJSON: jrpcMessage)
			   toClient: clientSocket.
		   [ self removeMessageProcess: jrpcMessage id ]
			   on: KeyNotFound
			   do: [  ] ]
			   forkAt: Processor lowIOPriority
			   named: jrpcMessage id printString)
]

{ #category : #initialization }
PLSAbstractServer >> initialize [

	super initialize.
	messageProcessor := PLSMessageProcessor new.
	self addHandlersFromPragmasIn: self.
	self debugMode: false.
	serverContext := PLSContext new.
	withStdIO := false.
	data := ''.
	messagesProcesses := Dictionary new.
	serverLoop := true.
	lastId := 0
]

{ #category : #starting }
PLSAbstractServer >> initializeStreams [

	| tcpServer |
	withStdIO ifTrue: [ 
		clientInStream := Stdio stdin.
		clientOutStream := Stdio stdout.
		^ self ].
	tcpServer := Socket newTCP.
	tcpServer listenOn: self port backlogSize: 10.
	Stdio stdout nextPutAll: tcpServer port asString asByteArray.
	Stdio stdout flush.
	serverLoop := true.
	(tcpServer waitForAcceptFor: 60) ifNotNil: [ :clientSocket | 
		clientInStream := SocketStream on: clientSocket.
		clientOutStream := clientInStream.
		self
			logMessage: 'Client connected to Server using socket'
			ofType: PLSMessageType info ]
]

{ #category : #accessing }
PLSAbstractServer >> log: everything [
	everything printString record
]

{ #category : #'lsp - message' }
PLSAbstractServer >> logMessage: aString ofType: messageType [
	"The show message notification is sent from a server to a client to ask the client to display a particular message in the user interface"

	self
		sendData:
			(self
				convertJRPCJsonableObjectToJSON:
					((JRPCNotificationObject method: 'window/logMessage')
						params: (PLSLogMessage message: aString type: messageType))
						asJRPCJSON)
		toClient: clientOutStream
]

{ #category : #context }
PLSAbstractServer >> messageProcess: anId	put: aProcess [
	self context messageProcessesAt: anId put: aProcess
]

{ #category : #'lsp - initialization' }
PLSAbstractServer >> onInitializeTrace: trace processId: processId locale: locale clientInfo: clientInfo rootPath: rootPath workspaceFolders: workspaceFolders capabilities: capabilities rootUri: rootUri [
	<jrpc: #initialize>
	self subclassResponsibility.
	
]

{ #category : #starting }
PLSAbstractServer >> parseJSON: aJSONString [
	^ self messageProcessor parseSupposedJRPCMessageObjectFromString: aJSONString.
	
]

{ #category : #stopping }
PLSAbstractServer >> port [
	^ port ifNil: [ port := self defaultPort ]
]

{ #category : #stopping }
PLSAbstractServer >> port: anObject [
	port := anObject
]

{ #category : #context }
PLSAbstractServer >> removeMessageProcess: anId [
	self context removeMessageProcess: anId
]

{ #category : #context }
PLSAbstractServer >> resetContext [
	serverContext := PLSContext new
]

{ #category : #starting }
PLSAbstractServer >> sendData: answer2 toClient: stream [

	answer2 ifEmpty: [ 'No Answser' recordInfo ] ifNotEmpty: [ 
		('Answer sent: ' , answer2) recordInfo.
		self getHeaderFor: answer2 into: stream.
		stream << answer2 utf8Encoded.
		stream flush ]
]

{ #category : #'lsp - initialization' }
PLSAbstractServer >> serverInitialized [
	<jrpc: #initialized>
	self subclassResponsibility
]

{ #category : #'lsp - initialization' }
PLSAbstractServer >> serverShutdown [
	<jrpc: #shutdown>
	self subclassResponsibility
]

{ #category : #'lsp - trace' }
PLSAbstractServer >> setTrace: setTraceParam [
	<jrpc: #'$/setTrace'>
]

{ #category : #'lsp - trace' }
PLSAbstractServer >> setTraceNotification: value [
	<jrpc: #'$/setTraceNotification'>
]

{ #category : #'lsp - show document' }
PLSAbstractServer >> showDocument: documentURI external: aBooleanOrNil withFocus: focusBooleanOrNil atRange: aPLSRangeOrNil [
	
	self
		sendData:
			(self
				convertJRPCJsonableObjectToJSON:
					((JRPCRequestObject id: 400 method: 'window/showDocument')
						params: (PLSShowDocument new 
							uri: documentURI;
							external: aBooleanOrNil;
							takeFocus: focusBooleanOrNil;
							selection: aPLSRangeOrNil;
							yourself
							))
						asJRPCJSON)
		toClient: clientOutStream
]

{ #category : #'lsp - message' }
PLSAbstractServer >> showMessage: aString ofType: messageType [
	"The show message notification is sent from a server to a client to ask the client to display a particular message in the user interface"

	self
		sendData:
			(self
				convertJRPCJsonableObjectToJSON:
					((JRPCNotificationObject method: 'window/showMessage')
						params: (PLSShowMessage message: aString type: messageType))
						asJRPCJSON)
		toClient: clientOutStream
]

{ #category : #starting }
PLSAbstractServer >> start [

	self debugMode ifFalse: [ PLSUIManager withPLSServer: self ].
	self initializeStreams.
	lastId := 0.
	process := [ 
	           [ serverLoop ] whileTrue: [ 
		           | request |
		           request := self extractRequestFrom: clientInStream.
		           ('Request: ' , request) recordDebug.
		           self handleRequest: request toClient: clientOutStream ] ]
		           forkAt: Processor lowIOPriority
		           named: 'JRPC TCP connection'
]

{ #category : #stopping }
PLSAbstractServer >> stop [

	serverLoop := false.
	clientInStream close.
	clientOutStream close

	"Ensure process finishes."
	process ifNotNil: [ 
		process isTerminated ifTrue: [ ^ self ].
		process terminate ]
]

{ #category : #'lsp - completion' }
PLSAbstractServer >> textDocumentCompletionWithContext: context position: position textDocument: textDocument [
	<jrpc: #'textDocument/completion'>
	self subclassResponsibility 
]

{ #category : #'lsp - hover' }
PLSAbstractServer >> textDocumentHoverWithPosition: position textDocument: textDocument [
	<jrpc: #'textDocument/hover'>
	self subclassResponsibility
]

{ #category : #accessing }
PLSAbstractServer >> withStdIO [

	^ withStdIO
]

{ #category : #accessing }
PLSAbstractServer >> withStdIO: anObject [

	withStdIO := anObject
]
