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
	#superclass : #JRPCTCPServer,
	#category : #PharoLanguageServer
}

{ #category : #starting }
PLSServer >> extractLengthOf: data [
	(data beginsWith: 'Content-Length: ')
		ifTrue:
			[ ^ (data copyFrom: 16 to: (data indexOf: Character cr)) asInteger ]
		ifFalse: [ ^ -1 ]
]

{ #category : #starting }
PLSServer >> getDatafromPosition: startingPoint fromSocket: clientSocket in: existingData [
	clientSocket receiveDataInto: existingData startingAt: startingPoint
]

{ #category : #starting }
PLSServer >> initialize [
	super initialize.
	self addHandlersFromPragmasIn: self
]

{ #category : #starting }
PLSServer >> onInitializeTrace: trace processId: processId clientInfo: clientInfo rootPath: rootPath workspaceFolders: workspaceFolders capabilities: capabilities rootUri: rootUri [
	<jrpc: #initialize>
	^ JRPCRequestObject new 
		method: 'initialize';
		params: PLSInitializeResult new asJRPCJSON;
		yourself
]

{ #category : #starting }
PLSServer >> start [
	tcpServer := Socket newTCP.
	tcpServer listenOn: self port backlogSize: 10.
	serverLoop := true.
	process := [ [ serverLoop ]
		whileTrue: [ (tcpServer waitForAcceptFor: 60)
				ifNotNil: [ :clientSocket | 
					[ [ | data buffer length startingPoint |
					data := clientSocket receiveData.
					length := self extractLengthOf: data.
					startingPoint := data indexOf: ${.
					buffer := String new: length.
					startingPoint = 0
						ifTrue: [ self getDatafromPosition: 1 fromSocket: clientSocket in: buffer ]
						ifFalse: [ (data copyFrom: startingPoint to: data size) withIndexDo: [ :each :index | buffer at: index put: each ].
							self
								getDatafromPosition: data size - startingPoint + 2
								fromSocket: clientSocket
								in: buffer].
					clientSocket sendData: (self handleJSON: buffer) ]
						ensure: [ clientSocket closeAndDestroy ] ]
						forkAt: Processor lowIOPriority
						named: 'JRPC TCP connection' ] ] ]
		forkAt: Processor highIOPriority
		named: 'JRPC TCP server'
]

{ #category : #starting }
PLSServer >> textDocumentCompletion: CompletionParams [
	<jrpc: #'textDocument/completion'>
	^ JRPCRequestObject new 
		method: #'textDocument/completion';
		params: PLSCompletionList new asJRPCJSON;
		yourself
]
