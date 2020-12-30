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
		'messagesProcesses'
	],
	#category : #PharoLanguageServer
}

{ #category : #defaults }
PLSServer class >> defaultPort [
	^ 4000
]

{ #category : #lsp }
PLSServer >> cancelRequest: id [
	<jrpc: #'$/cancelRequest' >
	self context messageProcesses
		at: id
		ifPresent: [ :process2 | process2 terminate ]
		ifAbsent: [ Error signal ]
]

{ #category : #commands }
PLSServer >> commandPharoLanguageServerVersion [
	<jrpc: #'command:version'>
	^ '1.0.0'
]

{ #category : #commands }
PLSServer >> commandPharoPrintIt: line [
	<jrpc: #'command:printIt'>
	^ (SmalltalkImage current compiler
		source: line readStream;
		context: nil;
		failBlock: [ ^ nil ];
		evaluate) printString
]

{ #category : #commands }
PLSServer >> commandPharoSave [
	<jrpc: #'command:save'>
	SmalltalkImage current snapshot: true andQuit: false.
	^ 'Image saved'
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
	document := self context textItem: (textDocument at: #uri).
	document at: #version put: (textDocument at: #version).
	contentChanges
		do:
			[ :change | change keysAndValuesDo: [ :key :value | document at: key put: value ] ]
]

{ #category : #'lsp - text synchronisation' }
PLSServer >> didClose: textDocument [
	<jrpc: #'textDocument/didClose'>
	self context removeItem: (textDocument at: #uri)
]

{ #category : #'lsp - text synchronisation' }
PLSServer >> didOpen: textDocument [
	<jrpc: #'textDocument/didOpen'>
	self context textItem: (textDocument at: #uri) put: textDocument 
]

{ #category : #'lsp - text synchronisation' }
PLSServer >> didSave: textDocument text: text [
	<jrpc: #'textDocument/didSave'>
	"Install the code in the image if the code is part of a tonel file"
	((textDocument at: #uri) endsWith: 'class.st')
		ifTrue: [ (TonelParser parseString: text) do: #load ]
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
	codeSource := (self context textItem: (textDocument at: #uri))
		at: #text.
	lines := codeSource lines.
	endPosition := PLSPosition new
		line: lines size;
		character: lines last size;
		yourself.
	formatter := PLSFormater new sourceCode: codeSource.
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
	aStream << 'Content-Length: ' << answer size asString << String crlf
		<< String crlf
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
						streamContents: [ :contentStream | 
							self getHeaderFor: answer into: contentStream.
							contentStream << answer ]) ]
]

{ #category : #lsp }
PLSServer >> serverInitialized [
	<jrpc: #initialized>
	Transcript crTrace: 'Initialized'
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
	tcpServer listenOn: self port backlogSize: 10.
	serverLoop := true.
	(tcpServer waitForAcceptFor: 60)
		ifNotNil: [ :clientSocket | 
			process := [ [ serverLoop ]
				whileTrue: [ | request |
					request := self extractRequestFrom: clientSocket.
					self handleRequest: request toClient: clientSocket ] ]
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

{ #category : #'lsp - completion' }
PLSServer >> textDocumentCompletionWithContext: context position: position textDocument: textDocument [
	<jrpc: #'textDocument/completion'>
	| completionList completionEngine |
	completionEngine := PLSCompletion new
		source: ((self context textItem: (textDocument at: #uri)) at: #text);
		position: position;
		yourself.
	completionList := PLSCompletionList new.
	completionList completionItems: completionEngine entries asArray.
	^ completionList
]

{ #category : #'lsp - hover' }
PLSServer >> textDocumentHoverWithPosition: position textDocument: textDocument [
	<jrpc: #'textDocument/hover'>
	| hover |
	hover := PLSHover new
		source: ((self context textItem: (textDocument at: #uri)) at: #text);
		position: position;
		yourself.
	^ { #contents -> hover contents } asDictionary
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
