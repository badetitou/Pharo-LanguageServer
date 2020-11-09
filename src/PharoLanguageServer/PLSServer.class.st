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
	#instVars : [
		'port',
		'tcpServer',
		'serverLoop',
		'process',
		'context'
	],
	#category : #PharoLanguageServer
}

{ #category : #defaults }
PLSServer class >> defaultPort [
	^ 4000
]

{ #category : #context }
PLSServer >> context [
	^ context
]

{ #category : #stopping }
PLSServer >> defaultPort [
	^ self class defaultPort
]

{ #category : #'lsp - text synchronisation' }
PLSServer >> didChange: textDocument contentChanges: contentChanges [
	<jrpc: #'textDocument/didChange'>
]

{ #category : #'lsp - text synchronisation' }
PLSServer >> didClose: textDocument [
	<jrpc: #'textDocument/didClose'>
	self context removeItem: ((textDocument at: #textDocument) at: #uri)
]

{ #category : #'lsp - text synchronisation' }
PLSServer >> didOpen: textDocument [
	<jrpc: #'textDocument/didOpen'>
	self context textItem: (textDocument at: #uri) put: textDocument 
]

{ #category : #'lsp - text synchronisation' }
PLSServer >> didSave: textDocument text: text [
	<jrpc: #'textDocument/didSave'>
]

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
PLSServer >> getHeaderFor: answer into: aStream [
	aStream << 'Content-Length: ' << answer size asString << String crlf
		<< String crlf
]

{ #category : #starting }
PLSServer >> initialize [
	super initialize.
	self addHandlersFromPragmasIn: self.
	context := PLSContext new
]

{ #category : #lsp }
PLSServer >> onInitializeTrace: trace processId: processId clientInfo: clientInfo rootPath: rootPath workspaceFolders: workspaceFolders capabilities: capabilities rootUri: rootUri [
	<jrpc: #initialize>
	^ PLSInitializeResult new
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
PLSServer >> resetContext [
	context := PLSContext new
]

{ #category : #starting }
PLSServer >> sendData: answer toClient: clientSocket [
	answer
		ifNotEmpty: [ clientSocket
				sendData:
					(String
						streamContents: [ :contentStream | 
							self getHeaderFor: answer into: contentStream.
							contentStream << answer ]) ]
]

{ #category : #lsp }
PLSServer >> serverInitialized [
	<jrpc: #'initialized'>
	Transcript crShow: 'Initialized'
]

{ #category : #starting }
PLSServer >> start [
	tcpServer := Socket newTCP.
	tcpServer listenOn: self port backlogSize: 10.
	serverLoop := true.
	(tcpServer waitForAcceptFor: 60)
		ifNotNil: [ :clientSocket | 
			process := [ [ serverLoop ]
				whileTrue: [ | data buffer length startingPoint |
					data := clientSocket receiveData.
					length := self extractLengthOf: data.
					startingPoint := data indexOf: ${.
					buffer := String new: length.
					startingPoint = 0
						ifTrue: [ self getDatafromPosition: 1 fromSocket: clientSocket in: buffer ]
						ifFalse: [ (data copyFrom: startingPoint to: data size)
								withIndexDo: [ :each :index | buffer at: index put: each ].
							self
								getDatafromPosition: data size - startingPoint + 2
								fromSocket: clientSocket
								in: buffer ].
					self sendData: (self handleJSON: buffer) toClient: clientSocket ] ]
				forkAt: Processor lowIOPriority
				named: 'JRPC TCP connection' ]
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

{ #category : #lsp }
PLSServer >> textDocumentCompletionWithContext: context position: position textDocument: textDocument [
	<jrpc: #'textDocument/completion'>
	| completionList |
	completionList := PLSCompletionList new.
	completionList
		completionItems:
			{(PLSCompletionItem new
				label: 'TypeScript';
				kind: PLSCompletionItemKind text;
				data: 1;
				yourself).
			(PLSCompletionItem new
				label: 'JavaScript';
				kind: PLSCompletionItemKind text;
				data: 2;
				yourself)}.
	^ completionList
]

{ #category : #'lsp - text synchronisation' }
PLSServer >> willSave: textDocument reason: reason [
	<jrpc: #'textDocument/willSave'>
]

{ #category : #'lsp - text synchronisation' }
PLSServer >> willSaveUntil: textDocument reason: reason [
	<jrpc: #'textDocument/willSaveWaitUntil'>
]
