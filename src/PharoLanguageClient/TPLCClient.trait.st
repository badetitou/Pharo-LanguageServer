Trait {
	#name : #TPLCClient,
	#instVars : [
		'port',
		'clientInStream',
		'clientOutStream'
	],
	#traits : 'JRPCParser + TPLPCommon',
	#classTraits : 'JRPCParser classTrait + TPLPCommon classTrait',
	#category : #PharoLanguageClient
}

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
	clientOutStream := clientInStream.
	self sendInitialize
]

{ #category : #accessing }
TPLCClient >> initialize [

	super initialize.
	currentId := 0
]

{ #category : #accessing }
TPLCClient >> port [

	^ port
]

{ #category : #accessing }
TPLCClient >> port: anObject [

	port := anObject
]

{ #category : #api }
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
TPLCClient >> sendRequest: aJRPCRequestObject [

	clientOutStream
		<<
			(self convertJRPCJsonableObjectToJSON:
					 aJRPCRequestObject asJRPCJSON);
		flush
]
