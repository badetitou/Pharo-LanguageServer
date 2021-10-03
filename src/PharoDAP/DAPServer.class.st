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
		'sourcesReferenceCache',
		'context',
		'debugSession',
		'breakpoints',
		'initialized',
		'pluggableEvaluationBlock',
		'strategy',
		'pluggableEvaluationBlockSender',
		'lineOffset',
		'numberOfStacks',
		'justMyCode'
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

{ #category : #accessing }
DAPServer >> breakpoints [ 
	"breakpoint is a source->breakpoints array dictionary"
	^ breakpoints ifNil:[ breakpoints := Dictionary new ]
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
DAPServer >> dapAttach: aDAPRequest [

	"Send that I receive  the initialize"

	<dap: #attach>
	self sendMessage: (DAPAttachResponse new
			 seq: self nextSeq;
			 request_seq: aDAPRequest seq;
			 command: aDAPRequest command;
			 body: DAPCapabilities new).
	self sendMessage: DAPAttachEvent new
]

{ #category : #dap }
DAPServer >> dapConfigurationDone: aDAPConfigurationDoneRequest [

	<dap: #configurationDone>
	self sendMessage: (DAPConfigurationDoneResponse new
			 seq: self nextSeq;
			 request_seq: aDAPConfigurationDoneRequest seq;
			 command: aDAPConfigurationDoneRequest command)
]

{ #category : #dap }
DAPServer >> dapContinue: aDAPContinueRequest [

	<dap: #continue>

	self
		sendMessage: (DAPContinuedEvent new
				 seq: self nextSeq;
				 threadId: self threads associations anyOne key;
				 yourself);
		sendMessage: (DAPContinueResponse new
				 seq: self nextSeq;
				 request_seq: aDAPContinueRequest seq;
				 command: aDAPContinueRequest command;
				 yourself).
	debugSession resume
]

{ #category : #dap }
DAPServer >> dapDisconnect: aDAPDisconnectRequest [

	<dap: #disconnect>
	initialized := false.
	self resetContext.
	self resetCache.
	self sendMessage: DAPDisconnectResponse new.

	aDAPDisconnectRequest arguments
		at: #terminateDebuggee
		ifPresent: [ :terminate | 
			terminate ifTrue: [ 
				OupsDebuggerSelectionStrategy debuggerSelectionStrategy:
					OupsDebuggerSelectionStrategy defaultDebuggerSelectionStrategy.
				socketClient close.
				serverLoop := false ] ]
]

{ #category : #dap }
DAPServer >> dapEvaluate: aDAPEvaluateRequest [
	<dap: #evaluate>
	| localContext expression localCompiler |
	localContext := self getStacks
		detect:
			[ :aStack | aStack hash = (aDAPEvaluateRequest arguments at: #frameId) ]
		ifNone: [ nil ].
	expression := '^ ' , (aDAPEvaluateRequest arguments at: #expression).
	localCompiler := (self compilerFor: nil)
		context: localContext;
		yourself.
	self
		sendMessage:
			(DAPEvaluateResponse new
				seq: self nextSeq;
				request_seq: aDAPEvaluateRequest seq;
				command: aDAPEvaluateRequest command;
				result: ([(localCompiler evaluate: expression)] on: Exception do: [ :err | err printString ]) printString;
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
	| source compiledMethod breakpointList sourceWithBreakpoints |
	self sendMessage: (DAPResponse new
			 seq: self nextSeq;
			 request_seq: aDAPLaunchRequest seq;
			 command: aDAPLaunchRequest command;
			 body: DAPLaunchResponse new).
	source := (aDAPLaunchRequest arguments at: #program) asFileReference
		          contents.
	self threads at: aDAPLaunchRequest seq put: aDAPLaunchRequest seq.
	strategy := OupsDebuggerSelectionStrategy debuggerSelectionStrategy.
	breakpointList := self breakpoints
		                  at: (self fileNameForCode: source)
		                  ifAbsent: Array new.
	sourceWithBreakpoints := self
		                         insertHaltsIn: source
		                         using: breakpointList.
	compiledMethod := self pluggableCompilationBlock value:
		                  sourceWithBreakpoints.
	"compiledMethod  valueWithReceiver:  self pluggableCompilationBlock receiver arguments:{self}.
	"
	OupsDebuggerSelectionStrategy debuggerSelectionStrategy:
		(DAPOupsDebuggerSelector with: { self }).
	self execute: [ compiler evaluate ] recordedAs: 'Evaluate'.

	OupsDebuggerSelectionStrategy debuggerSelectionStrategy: strategy.
	"we recove the old debugger once we receive the #debuggSession: strategy is an instance var
	jmari: I think it's better reactivate the normal debugger once we hace received the debugSession 
	for debugging purposes "
	self sendMessage: DAPTerminatedEvent new
]

{ #category : #dap }
DAPServer >> dapNext: aDAPNextRequest [
	"Send that I receive  the initialize"

	<dap: #next>
	self
		sendMessage:
			(DAPNextResponse new
				seq: self nextSeq;
				request_seq: aDAPNextRequest seq;
				command: aDAPNextRequest command).

	self
		sendMessage:
			(DAPContinuedEvent new
				seq: self nextSeq;
				threadId: self threads associations anyOne key;
				yourself).
				
	debugSession stepThrough.

	self
		sendMessage:
			(DAPStoppedEvent new
				seq: self nextSeq;
				description: 'step';
				threadId: self threads associations anyOne key;
				reason: 'step';
				yourself).
]

{ #category : #dap }
DAPServer >> dapScopes: aDAPScopesRequest [

	<dap: #scopes>
	| stack scope dapScope response |
	stack := self getStacks detect: [ :aStack | 
		         aStack hash = (aDAPScopesRequest arguments at: #frameId) ].
	scope := stack sourceNodeExecuted scope.
	sourcesReferenceCache
		at: 0
		ifPresent: [ :sourceRef | 
		sourceRef sourceCode: stack method sourceCode ].
	dapScope := DAPScope new
		            name: scope printString;
		            variablesReference: scope hash;
		            yourself.
	variablesReferenceCache at: scope hash put: { 
			(#scope -> (DAPTScope new
				  scope: scope;
				  inCache: variablesReferenceCache;
				  yourself)).
			(#context -> stack) } asDictionary.
	response := DAPScopesResponse new
		            seq: self nextSeq;
		            request_seq: aDAPScopesRequest seq;
		            command: aDAPScopesRequest command;
		            scopes: { dapScope };
		            yourself.
	self sendMessage: response
]

{ #category : #dap }
DAPServer >> dapSetBreakpoints: aDAPSetBreakpointsRequest [

	<dap: #setBreakpoints>
	| breakpointsList sourcePath bl |
	breakpointsList := aDAPSetBreakpointsRequest arguments
		                   at: 'breakpoints'
		                   ifAbsent: [ 
		                   aDAPSetBreakpointsRequest arguments at: 'lines' ].
	sourcePath := (aDAPSetBreakpointsRequest arguments at: #source)
		              at: #path
		              ifAbsent: [ 
		              (aDAPSetBreakpointsRequest arguments at: #source) at:
			              #reference ].

	bl := breakpointsList collectWithIndex: [ :aLine :anIndex | 
		      { 
			      (#id -> (self getAllBreakpoints size + 1)).
			      (#source -> { (#path -> sourcePath) } asDictionary).
			      (#line -> (aLine at: #line)).
			      (#verified -> true) } asDictionary ].

	self breakpoints at: sourcePath put: breakpointsList.

	[ 
	self sendMessage: (DAPSetBreakpointsResponse new
			 seq: self nextSeq;
			 request_seq: aDAPSetBreakpointsRequest seq;
			 command: aDAPSetBreakpointsRequest command;
			 body: { (#breakpoints -> bl asArray) } asDictionary).

	bl do: [ :eachBreakpoint | 
		self sendMessage:
			((DAPBreakpointCreatedEvent newFromABreakpoint: eachBreakpoint) 
				 seq: self nextSeq) ] ]
		forkAt: Processor timingPriority - 1
		named: #transaction
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

	self sendMessage: (DAPSourceResponse new
			 seq: self nextSeq;
			 request_seq: aDAPSourceRequest seq;
			 command: aDAPSourceRequest command;
			 content: (sourcesReferenceCache
					  at: (aDAPSourceRequest arguments at: #sourceReference)
					  ifPresent: [ :code | 
						  (code sourceCode copyReplaceAll: String cr with: String lf)
							  copyReplaceAll: String tab
							  with: '    ' ]
					  ifAbsent: [ 'Debugger cannot get block source code yet' ]);
			 mimeType: 'pharo';
			 yourself)
]

{ #category : #dap }
DAPServer >> dapStackTrace: aDAPStackTraceRequest [

	<dap: #stackTrace>
	| response stacks sourceNode dapStacks |
	response := DAPStackTraceResponse new
		            seq: self nextSeq;
		            request_seq: aDAPStackTraceRequest seq;
		            command: aDAPStackTraceRequest command;
		            yourself.
	stacks := self getStacks.
	sourcesReferenceCache
		at: 0
		ifPresent: [ :sourceRef | 
		sourceRef sourceCode: stacks first method sourceCode ].

	dapStacks := stacks collect: [ :stack | 
		             | positions |
		             "put reference to source in the cache"
		             sourcesReferenceCache
			             at: stack method hash
			             put: stack method.
		             positions := stack sourceCode toLineColumn:
			                          stack sourceNodeExecuted start.
		             "create the stack frame with its source"
		             sourceNode := DAPSource new
			                           name: stack method printString;
			                           sourceReference: stack method hash;
			                           yourself.

		             DAPStackFrame new
			             id: stack hash;
			             name: stack printString;
			             source: sourceNode;
			             line: (positions at: #line) + self lineOffset;
			             column: (positions at: #column);
			             yourself ].
	self isJustMyCode
		ifTrue: [ 
			response stackFrames addAll:
				(dapStacks select: [ :aStack | aStack source sourceReference = 0 ]) ]
		ifFalse: [ response stackFrames addAll: dapStacks ].

	self sendMessage: response
]

{ #category : #dap }
DAPServer >> dapStepIn: aDAPStepInRequest [
	"Send that I receive  the initialize"

	<dap: #stepIn>
	self
		sendMessage:
			(DAPStepInResponse new
				seq: self nextSeq;
				request_seq: aDAPStepInRequest seq;
				command: aDAPStepInRequest command).
				
	self
		sendMessage:
			(DAPContinuedEvent new
				seq: self nextSeq;
				threadId: self threads associations anyOne key;
				yourself).
				
	debugSession stepInto.
	self
		sendMessage:
			(DAPStoppedEvent new
				seq: self nextSeq;
				description: 'step';
				threadId: self threads associations anyOne key;
				reason: 'step';
				yourself).
]

{ #category : #dap }
DAPServer >> dapStepOut: aDAPStepOutRequest [
	"Send that I receive  the initialize"

	<dap: #stepOut>
	self
		sendMessage:
			(DAPStepOutResponse new
				seq: self nextSeq;
				request_seq: aDAPStepOutRequest seq;
				command: aDAPStepOutRequest command).
	self
		sendMessage:
			(DAPContinuedEvent new
				seq: self nextSeq;
				threadId: self threads associations anyOne key;
				yourself).
			
	debugSession stepOver.
	self
		sendMessage:
			(DAPStoppedEvent new
				seq: self nextSeq;
				description: 'step';
				threadId: self threads associations anyOne key;
				reason: 'step';
				yourself).
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
	response threads addAll:
		(self threads associations collect: [ :assoc | 
			 DAPThread new
				 id: assoc key;
				 name: assoc value printString;
				 yourself ]).
	self sendMessage: response
]

{ #category : #dap }
DAPServer >> dapVariables: aDAPVariablesRequest [

	<dap: #variables>
	| variablesReference scope context2 |
	variablesReference := aDAPVariablesRequest arguments at:
		                      #variablesReference.
	scope := (variablesReferenceCache at: variablesReference) at: #scope.
	context2 := (variablesReferenceCache at: variablesReference) at:
		            #context.
	self sendMessage: (DAPVariablesResponse new
			 seq: self nextSeq;
			 request_seq: aDAPVariablesRequest seq;
			 command: aDAPVariablesRequest command;
			 variables: (scope getDAPVariablesInContent: context2);
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

{ #category : #'debugger support' }
DAPServer >> debugSession: aDebugSession [
	'DAP debugSession:' record.
	debugSession := aDebugSession.
	"easy to debug if we keep the debugger"
	aDebugSession exception class = Halt ifTrue:[
		"jumps the halt stack"
		debugSession stepOver].
	self
		sendMessage:
			(DAPStoppedEvent new
				seq: self nextSeq;
				description: aDebugSession exception printString;
				threadId: self threads associations anyOne key;
				reason: 'exception';
				yourself)
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

{ #category : #dap }
DAPServer >> fileNameForCode: aName [
	^ ''
]

{ #category : #accessing }
DAPServer >> getAllBreakpoints [ 
	"breakpoint is a source->breakpoints array dictionary"
	| oc |
	oc := OrderedCollection new.
	
	self breakpoints associationsDo:[ :anAssociation | 
		oc add:{ #source:->anAssociation key. #breakpoints->anAssociation value } asDictionary ].
	^oc asArray
	
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

{ #category : #accessing }
DAPServer >> getStacks [ 

	^ debugSession stackOfSize: self numberOfStacks.

]

{ #category : #'debugger support' }
DAPServer >> handleException: exception ofProcess: aProcess [
	'DAP handleException:ofProcess:' record.
	debugSession := DebugSession new
		process: aProcess
		context: exception signalerContext.

	self
		sendMessage:
			(DAPStoppedEvent new
				seq: self nextSeq;
				description: exception printString;
				threadId: self threads associations anyOne key;
				reason: 'exception';
				yourself)
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
		ifFalse: [ DAPIncorrectJSON signal ].
	^ handlers
		detect: [ :handler | handler methodName = aDAPRequest command ]
		ifNone: [ DAPNonExistentHandler signal: aDAPRequest command ]
]

{ #category : #initialize }
DAPServer >> initialize [
	serverContext := DAPContext new.
	data := ''.
	current_seq := 0.
	debugMode := true.
	messagesProcesses := Dictionary new.
	handlers := OrderedCollection new.
	compiler := self compilerFor: nil.
	threads := Dictionary new.
	variablesReferenceCache := Dictionary new.
	sourcesReferenceCache := Dictionary new.
	initialized := false.
	self addHandlersFromPragmasIn: self.
	
	
]

{ #category : #'debugger support' }
DAPServer >> insertBestHaltOn: sourceLines at: line [ 

		| sourceLineBefore |
	line = 1 
		ifTrue:[
			"first Line"
			sourceLines at:line put: 'self halt.' , (sourceLines at: line ) ]
		ifFalse:[
			sourceLineBefore := (sourceLines at: (line - 1)) trimRight.
			(sourceLineBefore endsWithAnyOf:  #('.' '[' '|')) ifTrue:[ 
				sourceLines at:line put: 'self halt.' , (sourceLines at: line ) ] 
			ifFalse:[ (sourceLineBefore endsWith: ';') ifTrue:[ 
				sourceLines at:line put: 'halt;' , (sourceLines at: line ) ]
			ifFalse:[ 	self insertBestHaltOn: sourceLines at: (line -1) ] ] ]
]

{ #category : #'debugger support' }
DAPServer >> insertHaltsIn: source using:breakpointList [
	| sourceLines stream |
	sourceLines := source deepCopy findTokens: String lf.
	stream := WriteStream on: String new.
	
	breakpointList do:[ :aBreakpointIndex |
		self insertBestHaltOn: sourceLines at: (aBreakpointIndex at:#line) ].
	sourceLines do:[ :aLine | stream nextPutAll: aLine;crlf ].
	^ stream contents
]

{ #category : #accessing }
DAPServer >> isJustMyCode [
	^ justMyCode ifNil:[ justMyCode:= false ]
]

{ #category : #'debugger support' }
DAPServer >> isObsolete [
	^ true
]

{ #category : #testing }
DAPServer >> isRunning [
	^ serverLoop
]

{ #category : #accessing }
DAPServer >> justMyCode [
	justMyCode := true
]

{ #category : #accessing }
DAPServer >> lineOffset [

	^ lineOffset ifNil:[ lineOffset := 0 ]
]

{ #category : #accessing }
DAPServer >> lineOffset: anObject [

	lineOffset := anObject
]

{ #category : #context }
DAPServer >> messageProcess: anId [	
	^ self context messageProcessesAt: anId 
]

{ #category : #context }
DAPServer >> messageProcess: anId	put: aProcess [
	self context messageProcessesAt: anId put: aProcess
]

{ #category : #accessing }
DAPServer >> nextSeq [
	^ current_seq := current_seq + 1
]

{ #category : #accessing }
DAPServer >> numberOfStacks [
	^ numberOfStacks ifNil:[ numberOfStacks := 10 ]
]

{ #category : #accessing }
DAPServer >> numberOfStacks: anInteger [
	numberOfStacks := anInteger
]

{ #category : #'debugger support' }
DAPServer >> openOn: aDebugSession withFullView: bool andNotification: notification [
	debugSession := aDebugSession.
	'Open debug' record.
	self
		sendMessage:
			(DAPStoppedEvent new
				seq: self nextSeq;
				threadId: self threads associations anyOne key;
				reason: 'exception';
				yourself)
]

{ #category : #starting }
DAPServer >> parseJSON: aJSONString [
	| jsonObject |
	jsonObject := STONJSON fromString: aJSONString.
	^ DAPRequest newFromJSON: jsonObject
]

{ #category : #accessing }
DAPServer >> pluggableCompilationBlock [

	^ pluggableEvaluationBlock ifNil:[ pluggableEvaluationBlock := [	:source |	 compiler source:source;compile ] ] 
]

{ #category : #accessing }
DAPServer >> pluggableCompilationBlock: aOneArgBlock [
	pluggableEvaluationBlockSender := thisContext sender. 
	pluggableEvaluationBlock := aOneArgBlock
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
	serverContext := DAPContext new
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

{ #category : #'debugger support' }
DAPServer >> setBreakpoints: breakpointList inCompiledMethod: aCompiledMethod [
	| breakpoint |
	'Set breakpoint' record.
	Breakpoint removeAll.
	breakpointList do:[ :aBreakpointIndex |
		breakpoint := Breakpoint
		breakOnAST: ( aCompiledMethod ast statements at: (aBreakpointIndex at:#line))
		inObject: self pluggableCompilationBlock receiver.
		breakpoint enable].
	
]

{ #category : #starting }
DAPServer >> start [
	tcpServer := Socket newTCP.
	tcpServer listenOn: 0 backlogSize: 10.
	serverLoop := true.
	[ (tcpServer waitForAcceptFor: 6000)
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
	(process isNil or:[ process isTerminated])
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
