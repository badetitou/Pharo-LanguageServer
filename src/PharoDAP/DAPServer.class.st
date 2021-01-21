Class {
	#name : #DAPServer,
	#superclass : #Object,
	#instVars : [
		'port',
		'tcpServer',
		'serverLoop',
		'process',
		'data',
		'serverContext',
		'messagesProcesses',
		'handlers',
		'debugMode',
		'socketClient',
		'current_seq'
	],
	#category : #PharoDAP
}

{ #category : #'handlers management' }
DAPServer >> addHandler: aDAPHandler [
	handlers add: aDAPHandler
]

{ #category : #'handlers management' }
DAPServer >> addHandlersFromPragmasIn: handlerInstance [
	(Pragma allNamed: #dap: in: handlerInstance class)
		do: [ :pragma | 
			self
				addHandler:
					(DAPHandler new
						receiver: handlerInstance;
						methodName: pragma arguments first;
						messageSelector: pragma methodSelector;
						yourself) ]
]

{ #category : #context }
DAPServer >> context [
	^ serverContext
]

{ #category : #'handlers management' }
DAPServer >> convertDAPJsonableObjectToJSON: aDAPJsonableObject [
	^ String streamContents: [ :stream |
		self convertDAPJsonableObjectToJSON: aDAPJsonableObject asDAPJSON on: stream ]
]

{ #category : #'handlers management' }
DAPServer >> convertDAPJsonableObjectToJSON: aDAPJsonableObject on: stream [
	STONJSON put: aDAPJsonableObject onStream: stream
]

{ #category : #dap }
DAPServer >> dapDisconnect: arguments [
	<dap: #disconnect>
	^ DAPDisconnectResponse new
]

{ #category : #dap }
DAPServer >> dapInitialize: aDAPRequest [
	"Send that I receive  the initialize"

	<dap: #initialize>
	self
		sendMessage:
			(DAPResponse new
				seq: self nextSeq;
				request_seq: aDAPRequest seq;
				command: aDAPRequest command;
				body: DAPInitializeResponse new).
	self sendMessage: DAPInitializedEvent new
]

{ #category : #dap }
DAPServer >> dapLaunch: aDAPLaunchRequest [
	<dap: #launch>
	self
		sendMessage:
			(DAPResponse new
				seq: self nextSeq;
				request_seq: aDAPLaunchRequest seq;
				command: aDAPLaunchRequest command;
				body: DAPLaunchResponse new).
	self sendMessage: DAPTerminatedEvent new
]

{ #category : #dap }
DAPServer >> dapSetExceptionBreakpoints: aDAPSetExceptionBreakpointsRequest [ 
	<dap: #setExceptionBreakpoints>
	self
		sendMessage:
			(DAPResponse new
				seq: self nextSeq;
				request_seq: aDAPSetExceptionBreakpointsRequest  seq;
				command: aDAPSetExceptionBreakpointsRequest  command;
				body: DAPSetExceptionBreakpointsResponse new).
]

{ #category : #accessing }
DAPServer >> debugMode [
	^ debugMode
]

{ #category : #accessing }
DAPServer >> debugMode: anObject [
	debugMode := anObject
]

{ #category : #starting }
DAPServer >> extractLengthOf: aData [
	(aData beginsWith: 'Content-Length: ')
		ifTrue:
			[ ^ (aData copyFrom: 16 to: (aData indexOf: Character cr)) asInteger ]
		ifFalse: [ ^ -1 ]
]

{ #category : #starting }
DAPServer >> extractRequestFrom: clientSocket [
	| length startingPoint endPoint result |
	"data is the current buffer state"
	[ data isEmpty ] whileTrue: [ data := clientSocket receiveData ].
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
DAPServer >> getDatafromPosition: startingPoint fromSocket: clientSocket in: existingData [
	clientSocket receiveDataInto: existingData startingAt: startingPoint
]

{ #category : #starting }
DAPServer >> getHeaderFor: answer into: aStream [
	aStream << 'Content-Length: ' << answer size asString << String crlf
		<< String crlf
]

{ #category : #starting }
DAPServer >> handleRequest: aDAPRequest [
	[ | handler |
	handler := self handlerFor: aDAPRequest.
	handler executeWithArguments: aDAPRequest ]
		on: Error
		do: [ :dapError | 
			self debugMode
				ifTrue: [ dapError pass ]
				ifFalse: [ dapError return: (aDAPRequest convertErrorToResponse: dapError) ] ]
]

{ #category : #starting }
DAPServer >> handleRequest: request toClient: clientSocket [
	| dapMessage |
	dapMessage := [ self parseJSON: request ]
		on: Error
		do: [ :err | err return: err asJRPCResponse ].
	self
		messageProcess: dapMessage seq
		put:
			([ self handleRequest: dapMessage.
			self removeMessageProcess: dapMessage seq ]
				forkAt: Processor lowIOPriority
				named: dapMessage command)
]

{ #category : #'handlers management' }
DAPServer >> handlerFor: aDAPRequest [
	aDAPRequest command isString
		ifFalse: [ JRPCIncorrectJSON signal ].
	^ handlers
		detect: [ :handler | handler methodName = aDAPRequest command ]
		ifNone: [ DAPNonExistentHandler signal: aDAPRequest command ]
]

{ #category : #initialize }
DAPServer >> initialize [
	serverContext := PLSContext new.
	data := ''.
	current_seq := 0.
	debugMode := false.
	messagesProcesses := Dictionary new.
	handlers := OrderedCollection new.
	self addHandlersFromPragmasIn: self.
	
]

{ #category : #context }
DAPServer >> messageProcess: anId	put: aProcess [
	self context messageProcessesAt: anId put: aProcess
]

{ #category : #accessing }
DAPServer >> nextSeq [
	^ current_seq := current_seq + 1
]

{ #category : #starting }
DAPServer >> parseJSON: aJSONString [
	| jsonObject |
	jsonObject := STONJSON fromString: aJSONString.
	^ DAPRequest newFromJSON: jsonObject
]

{ #category : #accessing }
DAPServer >> port [
	^ port
]

{ #category : #accessing }
DAPServer >> port: anObject [
	port := anObject
]

{ #category : #context }
DAPServer >> removeMessageProcess: anId [
	self context removeMessageProcess: anId
]

{ #category : #context }
DAPServer >> resetContext [
	serverContext := PLSContext new
]

{ #category : #starting }
DAPServer >> sendData: answer toClient: clientSocket [
	answer
		ifNotEmpty: [ clientSocket
				sendData:
					(String
						streamContents: [ :contentStream | 
							self getHeaderFor: answer into: contentStream.
							contentStream << answer ]) ]
]

{ #category : #starting }
DAPServer >> sendMessage: aDAPMessage [
	self sendData: (aDAPMessage beConvertedBy: self) toClient: socketClient
]

{ #category : #starting }
DAPServer >> start [
	tcpServer := Socket newTCP.
	tcpServer listenOn: self port backlogSize: 10.
	serverLoop := true.
	(tcpServer waitForAcceptFor: 60)
		ifNotNil: [ :clientSocket | 
			socketClient := clientSocket.
			process := [ [ serverLoop ]
				whileTrue: [ | request |
					request := self extractRequestFrom: clientSocket.
					self handleRequest: request toClient: clientSocket ] ]
				forkAt: Processor lowIOPriority
				named: 'DAP TCP connection' ]
		ifNil: [ DAPError signal: 'DAPServer started but nobody join me' ]
]

{ #category : #stopping }
DAPServer >> stop [
	serverLoop := false.
	tcpServer closeAndDestroy.
	
	"Ensure process finishes."
	process isTerminated
		ifTrue: [ ^ self ].
	process terminate
]
