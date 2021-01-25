Class {
	#name : #DAPServer,
	#superclass : #Object,
	#instVars : [
		'tcpServer',
		'serverLoop',
		'process',
		'data',
		'serverContext',
		'messagesProcesses',
		'handlers',
		'debugMode',
		'socketClient',
		'current_seq',
		'compiler',
		'currentException',
		'threads',
		'variablesReferenceCache',
		'sourcesReferenceCache'
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

{ #category : #'debugger support' }
DAPServer >> compilerFor: fileURI [
	| compi |
	compi := SmalltalkImage current compiler
		transformDoit;
		failBlock: [ nil ];
		yourself.
	^ compi
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
DAPServer >> dapContinue: aDAPContinueRequest [
	<dap: #continue>
	self
		sendMessage:
			(DAPContinueResponse new
				seq: self nextSeq;
				request_seq: aDAPContinueRequest seq;
				command: aDAPContinueRequest command;
				yourself).
	currentException resume
]

{ #category : #dap }
DAPServer >> dapDisconnect: arguments [
	<dap: #disconnect>
	self sendMessage: DAPDisconnectResponse new.
	socketClient close.
	serverLoop := false
]

{ #category : #dap }
DAPServer >> dapEvaluate: aDAPEvaluateRequest [
	<dap: #evaluate>
	| context expression localCompiler |
	context := (currentException signalerContext stackOfSize: 10)
		detect:
			[ :aStack | aStack hash = (aDAPEvaluateRequest arguments at: #frameId) ]
		ifNone: [ nil ].
	expression := '^ ' , (aDAPEvaluateRequest arguments at: #expression).
	localCompiler := (self compilerFor: nil)
		context: context;
		yourself.
	self
		sendMessage:
			(DAPEvaluateResponse new
				seq: self nextSeq;
				request_seq: aDAPEvaluateRequest seq;
				command: aDAPEvaluateRequest command;
				result: ([(localCompiler evaluate: expression)] on: Exception do: [ 'error' ]) printString;
				variablesReference: 0)
]

{ #category : #dap }
DAPServer >> dapInitialize: aDAPRequest [
	"Send that I receive  the initialize"

	<dap: #initialize>
	self
		sendMessage:
			(DAPInitializeResponse new
				seq: self nextSeq;
				request_seq: aDAPRequest seq;
				command: aDAPRequest command;
				body: DAPCapabilities new).
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
	compiler
		source: (aDAPLaunchRequest arguments at: #program) asFileReference contents.
	self threads at: aDAPLaunchRequest seq put: aDAPLaunchRequest seq.
	[ compiler evaluate ]
		on: Exception
		do: [ :exception | 
			currentException := exception.
			currentException freeze.
			self handleException ].
	self sendMessage: DAPTerminatedEvent new
]

{ #category : #dap }
DAPServer >> dapScopes: aDAPScopesRequest [
	<dap: #scopes>
	| stack scope dapScope response |
	stack := (currentException signalerContext stackOfSize: 10)
		detect: [ :aStack | aStack hash = (aDAPScopesRequest arguments at: #frameId) ].
	scope := stack sourceNodeExecuted scope.
	dapScope := DAPScope new
		name: scope printString;
		variablesReference: scope hash;
		yourself.
	variablesReferenceCache
		at: scope hash
		put:
			{(#scope
				->
					(DAPTScope new
						scope: scope;
						inCache: variablesReferenceCache;
						yourself)).
			(#context -> stack)} asDictionary.
	response := DAPScopesResponse new
		seq: self nextSeq;
		request_seq: aDAPScopesRequest seq;
		command: aDAPScopesRequest command;
		scopes: {dapScope};
		yourself.
	self sendMessage: response
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

{ #category : #dap }
DAPServer >> dapSource: aDAPSourceRequest [
	<dap: #source>
	self
		sendMessage:
			(DAPSourceResponse new
				seq: self nextSeq;
				request_seq: aDAPSourceRequest seq;
				command: aDAPSourceRequest command;
				content:
					(sourcesReferenceCache
						at: (aDAPSourceRequest arguments at: #sourceReference))
						sourceCode;
				mimeType: 'pharo';
				yourself)
]

{ #category : #dap }
DAPServer >> dapStackTrace: aDAPStackTraceRequest [
	<dap: #stackTrace>
	| response |
	response := DAPStackTraceResponse new
		seq: self nextSeq;
		request_seq: aDAPStackTraceRequest seq;
		command: aDAPStackTraceRequest command;
		yourself.
	response stackFrames
		addAll:
			((currentException signalerContext stackOfSize: 10)
				collect: [ :stack |
					"put reference to source in the cache"
					sourcesReferenceCache at: stack method hash put: stack method.
					"create the stack frame with its source"
					DAPStackFrame new
						id: stack hash;
						name: stack printString;
						source: (DAPSource new
							name: (stack method printString) "we add .st to notify the client that this source is a st type";
							sourceReference: stack method hash;
							yourself);
						yourself ]).
	self sendMessage: response
]

{ #category : #dap }
DAPServer >> dapThreads: aDAPThreadsRequest [
	<dap: #threads>
	| response |
	response := DAPThreadsResponse new
		seq: self nextSeq;
		request_seq: aDAPThreadsRequest seq;
		command: aDAPThreadsRequest command;
		yourself.
	response threads
		addAll:
			(self threads associations
				collect: [ :assoc | 
					DAPThread new
						id: assoc key;
						name: assoc value printString;
						yourself ]).
	self sendMessage: response
]

{ #category : #dap }
DAPServer >> dapVariables: aDAPVariablesRequest [
	<dap: #variables>
	| variablesReference scope context |
	variablesReference := aDAPVariablesRequest arguments
		at: #variablesReference.
	scope := (variablesReferenceCache at: variablesReference) at: #scope.
	context := (variablesReferenceCache at: variablesReference)
		at: #context.
	self
		sendMessage:
			(DAPVariablesResponse new
				seq: self nextSeq;
				request_seq: aDAPVariablesRequest seq;
				command: aDAPVariablesRequest command;
				variables: (scope getDAPVariablesInContent: context);
				yourself)
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
	[ data isEmpty and: [ serverLoop ] ] whileTrue: [ data := clientSocket receiveData ].
	data ifEmpty: [ ^ '' ].
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

{ #category : #'debugger support' }
DAPServer >> handleException [
	self
		sendMessage:
			(DAPStoppedEvent new
				seq: self nextSeq;
				description: currentException printString;
				threadId: self threads associations anyOne key;
				reason: 'exception';
				yourself).
	1h.
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
				ifFalse: [ self sendMessage: (aDAPRequest convertErrorToResponse: dapError) ] ]
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
	debugMode := true.
	messagesProcesses := Dictionary new.
	handlers := OrderedCollection new.
	compiler := self compilerFor: nil.
	threads := Dictionary new.
	variablesReferenceCache := Dictionary new.
	sourcesReferenceCache := Dictionary new.
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

{ #category : #context }
DAPServer >> removeMessageProcess: anId [
	self context removeMessageProcess: anId
]

{ #category : #cache }
DAPServer >> resetCache [
	variablesReferenceCache removeAll.
	sourcesReferenceCache removeAll
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
	tcpServer listenOn: 0 backlogSize: 10.
	serverLoop := true.
	[ (tcpServer waitForAcceptFor: 60)
		ifNotNil: [ :clientSocket | 
			socketClient := clientSocket.
			process := [ [ serverLoop ]
				whileTrue: [ | request |
					(request := self extractRequestFrom: clientSocket)
						ifNotEmpty: [ self handleRequest: request toClient: clientSocket ] ] ]
				forkAt: Processor lowIOPriority
				named: 'DAP TCP connection' ]
		ifNil: [ DAPError signal: 'DAPServer started but nobody join me' ] ]
		forkAt: Processor lowIOPriority
		named: 'DAP started'.
	^ tcpServer localPort
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

{ #category : #accessing }
DAPServer >> threads [
	^ threads
]

{ #category : #accessing }
DAPServer >> threads: anObject [
	threads := anObject
]
