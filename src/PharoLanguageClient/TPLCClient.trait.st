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
	data := ''.
	context := PLCContext new
]

{ #category : #'lsp - initialization' }
TPLCClient >> clientInitializeWith: capabilities fromServerInfo: serverInfo [

	<jrpc: #initialize>
	self serverContext: serverInfo
]

{ #category : #'lsp - completion' }
TPLCClient >> clientInlineCompletionFrom: items fromRequest: originRequest [

	<jrpc: #'textDocument/inlineCompletion'>
	self subclassResponsibility
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

{ #category : #accessing }
TPLCClient >> context [

	^ context
]

{ #category : #accessing }
TPLCClient >> context: anObject [

	context := anObject
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

{ #category : #'lsp - text synchronisation' }
TPLCClient >> sendDidChangeTextDocument: textDocumentIdentifier withChanges: contentChanges [

	self answerProcessor cancelRequestBefore: textDocumentIdentifier.

	self notifyMethod: 'textDocument/didChange' arguments: { 
			(#textDocument -> textDocumentIdentifier).
			(#contentChanges -> contentChanges) } asDictionary asJRPCJSON
]

{ #category : #'lsp - text synchronisation' }
TPLCClient >> sendDidOpenTextDocument: textDocumentItem for: aConcreteTextDocument [

	self context
		textItem: textDocumentItem uri
		put: aConcreteTextDocument.
	self
		notifyMethod: 'textDocument/didOpen'
		arguments:
		{ (#textDocument -> textDocumentItem) } asDictionary asJRPCJSON
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

{ #category : #'lsp - completion' }
TPLCClient >> sendTextDocument: textDocumentIdentifier inlineCompletionAt: aPosition [

	self
		callMethod: #'textDocument/inlineCompletion'
		arguments: (PLPInlineCompletionParams new
				 context: (PLPInlineCompletionContext new
						  triggerKind: PLPInlineCompletionTriggerKind automatic;
						  yourself);
				 position: aPosition;
				 textDocument: textDocumentIdentifier;
				 yourself) asJRPCJSON
		withId: self nextId "to fill" "to fill"
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

{ #category : #api }
TPLCClient >> startWithLocalServer [

	"This method is to use with a Local PLSServer"

	| server serverProcess openPort |
	self clientInit.
	server := PLSServer new.
	server debugMode: true.
	server answerLoopPriority: Processor lowIOPriority.
	self answerLoopPriority: Processor lowIOPriority.
	serverProcess := [ server start ]
		                 forkAt: Processor activeProcess priority
		                 named: 'Local PLS server'.

	[ server port = 0 ] whileTrue.
	openPort := server port.
	self port: openPort.
	self start
]

{ #category : #api }
TPLCClient >> stop [

	self stopAnswerLoop
]
