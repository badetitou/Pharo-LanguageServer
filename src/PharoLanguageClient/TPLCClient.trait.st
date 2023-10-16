"
To use my traits, the easiest way is to use the trait **and** then to perform the `clientInit` method in the initialization method of your class
"
Trait {
	#name : #TPLCClient,
	#instVars : [
		'port',
		'serverContext',
		'answerProcessor',
		'context'
	],
	#traits : 'JRPCParser + TPLPCommon',
	#classTraits : 'JRPCParser classTrait + TPLPCommon classTrait',
	#category : #PharoLanguageClient
}

{ #category : #accessing }
TPLCClient >> answerProcessor [

	^ answerProcessor
]

{ #category : #accessing }
TPLCClient >> answerProcessor: anObject [

	answerProcessor := anObject
]

{ #category : #api }
TPLCClient >> callMethod: aString arguments: anObject withId: anInteger [

	"Call a method which takes arguments."

	^ self sendRequest: (JRPCRequestObject new
			   id: anInteger;
			   method: aString;
			   params: anObject;
			   yourself)
]

{ #category : #api }
TPLCClient >> callMethod: aString withId: anInteger [
	"Call a method which takes no arguments."

	^ self callMethod: aString arguments: nil withId: anInteger
]

{ #category : #accessing }
TPLCClient >> clientInStream [

	^ clientInStream
]

{ #category : #accessing }
TPLCClient >> clientInStream: anObject [

	clientInStream := anObject
]

{ #category : #'plp - answerLoop' }
TPLCClient >> clientInit [

	currentId := 0.
	answerProcessor := PLCAnswerProcessor for: self.
	data := ''
]

{ #category : #'lsp - initialization' }
TPLCClient >> clientInitializeWith: capabilities fromServerInfo: serverInfo [

	<jrpc: #initialize>
	self serverContext: serverInfo
]

{ #category : #accessing }
TPLCClient >> clientOutStream [

	^ clientOutStream
]

{ #category : #accessing }
TPLCClient >> clientOutStream: anObject [

	clientOutStream := anObject
]

{ #category : #api }
TPLCClient >> connect [

	| tcpSocket |
	tcpSocket := Socket newTCP.
	tcpSocket connectTo: NetNameResolver loopBackAddress port: self port.
	clientInStream := SocketStream on: tcpSocket.
	clientOutStream := clientInStream
]

{ #category : #'plp - answerLoop' }
TPLCClient >> handleRequest: request toClient: outputStream [

	self answerProcessor handle: request
]

{ #category : #testing }
TPLCClient >> isClient [
	"Returns true if the trait is used in the context of a client, false in the context of a server."
	^ true
]

{ #category : #api }
TPLCClient >> notifyMethod: aString arguments: anArrayOrString [

	self sendNotification: (JRPCNotificationObject new
			 method: aString;
			 params: anArrayOrString;
			 yourself)
]

{ #category : #accessing }
TPLCClient >> port [

	^ port
]

{ #category : #accessing }
TPLCClient >> port: anObject [

	port := anObject
]

{ #category : #'plp - base protocol' }
TPLCClient >> sendCancelRequest: id [

	self notifyMethod: '$/cancelRequest' arguments: (PLPCancelParams new
			 id: id;
			 yourself) asJRPCJSON.
	self answerProcessor removeHandlerWithId: id
]

{ #category : #'lsp - initialization' }
TPLCClient >> sendInitialize [

	self
		callMethod: 'initialize'
		arguments: (PLPInitializeParams new
				 capabilities: PLPClientCapabilities new;
				 clientInfo: { 
						 (#name -> 'PLCClient').
						 (#version -> 'beta') } asDictionary;
				 processId: nil;
				 yourself) asJRPCJSON
		withId: self nextId
]

{ #category : #api }
TPLCClient >> sendNotification: aJRPCNotificationObject [
	"When a notification is sent to the server, we do not expect an answer."
	[ 
		self sendRequest: aJRPCNotificationObject
	] on: JRPCIncorrectJSON, STONReaderError do: [ "Does nothing on purpose." ]
]

{ #category : #api }
TPLCClient >> sendRequest: aJRPCRequestObject [

	| answer |
	answer := self convertJRPCJsonableObjectToJSON:
		          aJRPCRequestObject asJRPCJSON.
	self answerProcessor addHandlerFor: aJRPCRequestObject.
	self getHeaderFor: answer into: clientOutStream.
	clientOutStream
		nextPutAllFlush: answer;
		flush
]

{ #category : #accessing }
TPLCClient >> serverContext [

	^ serverContext
]

{ #category : #accessing }
TPLCClient >> serverContext: anObject [

	serverContext := anObject
]

{ #category : #api }
TPLCClient >> start [

	self connect.
	answerLoop := true.
	self startAnswerLoop.
	self sendInitialize
]
