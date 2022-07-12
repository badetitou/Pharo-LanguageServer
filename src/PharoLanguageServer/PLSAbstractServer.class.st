Class {
	#name : #PLSAbstractServer,
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
PLSAbstractServer >> cancelRequest: id [
	<jrpc: #'$/cancelRequest' >
	self context messageProcesses
		at: id
		ifPresent: [ :process2 | process2 terminate ]
		ifAbsent: [ ]
]

{ #category : #context }
PLSAbstractServer >> context [
	^ serverContext
]

{ #category : #stopping }
PLSAbstractServer >> defaultPort [
	^ self class defaultPort
]

{ #category : #starting }
PLSAbstractServer >> extractLengthOf: data [
	(data beginsWith: 'Content-Length: ')
		ifTrue:
			[ ^ (data copyFrom: 16 to: (data indexOf: Character cr)) asInteger ]
		ifFalse: [ ^ -1 ]
]

{ #category : #starting }
PLSAbstractServer >> extractRequestFrom: clientSocket [
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

{ #category : #starting }
PLSAbstractServer >> getDatafromPosition: startingPoint fromSocket: clientSocket in: existingData [
	clientSocket receiveDataInto: existingData startingAt: startingPoint
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
		               do: [ :err | err return: err asJRPCResponse ].
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

{ #category : #starting }
PLSAbstractServer >> initialize [
	super initialize.
	messageProcessor := PLSMessageProcessor new.
	self addHandlersFromPragmasIn: self.
	serverContext := PLSContext new.
	data := ''.
	messagesProcesses := Dictionary new.
]

{ #category : #accessing }
PLSAbstractServer >> log: everything [
	everything printString record
]

{ #category : #context }
PLSAbstractServer >> messageProcess: anId	put: aProcess [
	self context messageProcessesAt: anId put: aProcess
]

{ #category : #'lsp - initialization' }
PLSAbstractServer >> onInitializeTrace: trace processId: processId clientInfo: clientInfo rootPath: rootPath workspaceFolders: workspaceFolders capabilities: capabilities rootUri: rootUri [
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
PLSAbstractServer >> sendData: answer2 toClient: clientSocket [
	('Answer: ' , answer2) recordInfo.
	answer2 ifNotEmpty: [ 
		('Answer sent: ' , answer2) recordInfo.
		clientSocket sendData: (String streamContents: [ :contentStream | 
				 self getHeaderFor: answer2 into: contentStream ]).
		clientSocket sendData: answer2 utf8Encoded ]
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
		toClient: socketClient
]

{ #category : #starting }
PLSAbstractServer >> start [
	PLSUIManager withPLSServer: self.
	tcpServer := Socket newTCP.
	tcpServer listenOn: self port backlogSize: 10.
	Stdio stdout nextPutAll: tcpServer port asString asByteArray.
	Stdio stdout flush.
	serverLoop := true.
	(tcpServer waitForAcceptFor: 60)
		ifNotNil: [ :clientSocket | 
			socketClient := clientSocket.
			process := [ [ serverLoop ]
				whileTrue: [ | request |
					request := self extractRequestFrom: clientSocket.
					self log: request.
					self handleRequest: request toClient: clientSocket ] ]
				forkAt: Processor lowIOPriority
				named: 'JRPC TCP connection' ]
]

{ #category : #stopping }
PLSAbstractServer >> stop [

	serverLoop := false.
	tcpServer closeAndDestroy.

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
