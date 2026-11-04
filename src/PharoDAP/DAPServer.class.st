Class {
	#name : 'DAPServer',
	#superclass : 'Object',
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
		'justMyCode',
		'shouldStop',
		'plsServer',
		'attachedSessionId',
		'variablesObjects',
		'currentVariablesObjects'
	],
	#category : 'PharoDAP',
	#package : 'PharoDAP'
}

{ #category : 'handlers management' }
DAPServer >> addHandler: aDAPHandler [
	handlers add: aDAPHandler
]

{ #category : 'handlers management' }
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

{ #category : 'accessing' }
DAPServer >> breakpoints [ 
	"breakpoint is a source->breakpoints array dictionary"
	^ breakpoints ifNil:[ breakpoints := Dictionary new ]
]

{ #category : 'debugger support' }
DAPServer >> compilerFor: fileURI [

	| compi |
	compi := SmalltalkImage current compiler.
	compi compilationContext isScripting: true.
	compi failBlock: [ nil ].
	^ compi
]

{ #category : 'context' }
DAPServer >> context [
	^ serverContext
]

{ #category : 'debugger support' }
DAPServer >> contextAt: frameId [
	"Answer the context of the stack of the debug session whose frame has the id frameId"

	^ debugSession interruptedContext stack
		  detect: [ :each | each hash = frameId ]
		  ifNone: [ DAPInvalidParameters signal: 'Unknown frame: ' , frameId printString ]
]

{ #category : 'debugger support' }
DAPServer >> contextVariablesOf: aContext [
	"Answer the variables of the Context scope of aContext: thisContext, its arguments and its temporaries"

	^ (OrderedCollection with:
			   (self
				    variableNamed: 'thisContext'
				    value: aContext
				    evaluateName: nil))
		  addAll: (aContext tempNames collect: [ :name |
						   self
							   variableNamed: name
							   value: ([ aContext tempNamed: name ]
									    on: Error
									    do: [ :error | error ])
							   evaluateName: name ]);
		  yourself
]

{ #category : 'handlers management' }
DAPServer >> convertDAPJsonableObjectToJSON: aDAPJsonableObject [
	^ String streamContents: [ :stream |
		self convertDAPJsonableObjectToJSON: aDAPJsonableObject asDAPJSON on: stream ]
]

{ #category : 'handlers management' }
DAPServer >> convertDAPJsonableObjectToJSON: aDAPJsonableObject on: stream [
	STONJSON put: aDAPJsonableObject onStream: stream
]

{ #category : 'dap' }
DAPServer >> dapAttach: aDAPRequest [
	"Attach to a process that the image stopped on an exception: the debug session of the id that a pls-debug/stopped notification gave to the client"

	<dap: #attach>
	| id |
	id := aDAPRequest arguments at: #debugSessionId ifAbsent: [ nil ].
	(plsServer isNil or: [ id isNil ]) ifTrue: [
			^ self
				  respondTo: aDAPRequest
				  failure:
				  'Attach to a Pharo debug session: debugSessionId is missing.' ].
	debugSession := [ plsServer debugSessionAt: id ]
		                on: PLSUnknownEntity
		                do: [
				                ^ self
					                  respondTo: aDAPRequest
					                  failure:
					                  'This Pharo debug session is no longer waiting for a debugger.' ].
	attachedSessionId := id.
	self shouldStop: true.
	self threads at: id put: debugSession name asString.
	self respondTo: aDAPRequest body: nil.
	self sendStopped: 'exception'
]

{ #category : 'dap' }
DAPServer >> dapConfigurationDone: aDAPConfigurationDoneRequest [

	<dap: #configurationDone>
	self sendMessage: (DAPConfigurationDoneResponse new
			 seq: self nextSeq;
			 request_seq: aDAPConfigurationDoneRequest seq;
			 command: aDAPConfigurationDoneRequest command)
]

{ #category : 'dap' }
DAPServer >> dapContinue: aDAPContinueRequest [
	"Resume the process. An attached process goes on without the debugger, which ends: a new exception opens a new one"

	<dap: #continue>
	attachedSessionId ifNotNil: [
			| session |
			session := debugSession.
			debugSession := nil.
			self
				respondTo: aDAPContinueRequest
				body: { (#allThreadsContinued -> true) } asDictionary.
			session resume.
			^ self sendEvent: 'terminated' body: Dictionary new ].
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

{ #category : 'dap' }
DAPServer >> dapDisconnect: aDAPDisconnectRequest [
	"An attached process that the debugger did not resume ends with it, as when the debugger of Pharo closes"

	<dap: #disconnect>
	attachedSessionId ifNotNil: [
			debugSession ifNotNil: [ :session | session terminate ].
			debugSession := nil ].
	initialized := false.
	self resetContext.
	self resetCache.
	self sendMessage: DAPDisconnectResponse new.
	aDAPDisconnectRequest arguments
		at: #terminateDebuggee
		ifPresent: [ :terminate |
				('terminate: ' , terminate printString) record.
				terminate ifTrue: [
						OupsDebuggerSelectionStrategy debuggerSelectionStrategy:
							OupsDebuggerSelectionStrategy defaultDebuggerSelectionStrategy.
						^ self stop ] ].
	self shouldStop ifTrue: [
			OupsDebuggerSelectionStrategy debuggerSelectionStrategy:
				OupsDebuggerSelectionStrategy defaultDebuggerSelectionStrategy.
			self stop ]
]

{ #category : 'dap' }
DAPServer >> dapEvaluate: aDAPEvaluateRequest [
	"Evaluate an expression of the debug console, of the watches or of a hover in the frame, and answer its result as a variable the client can expand"

	<dap: #evaluate>
	| arguments frame result variable |
	attachedSessionId ifNil: [
		^ self dapLaunchedEvaluate: aDAPEvaluateRequest ].
	arguments := aDAPEvaluateRequest arguments.
	frame := (arguments at: #frameId ifAbsent: [ nil ]) ifNotNil: [ :id |
		         self contextAt: id ].
	result := [ self evaluate: (arguments at: #expression) in: frame ]
		          on: Error , Halt , Warning
		          do: [ :exception |
			          ^ self
				            respondTo: aDAPEvaluateRequest
				            failure: exception description ].
	variable := self variableNamed: '' value: result evaluateName: nil.
	self respondTo: aDAPEvaluateRequest body: {
			(#result -> (variable at: #value)).
			(#type -> (variable at: #type)).
			(#variablesReference -> (variable at: #variablesReference)) }
			asDictionary
]

{ #category : 'dap' }
DAPServer >> dapExceptionInfo: aDAPExceptionInfoRequest [

	<dap: #exceptionInfo>
	| exception |
	exception := debugSession exception.
	self respondTo: aDAPExceptionInfoRequest body: {
			(#exceptionId -> exception class name asString).
			(#description -> exception description asString).
			(#breakMode -> 'unhandled').
			(#details -> {
				 (#typeName -> exception class name asString).
				 (#message -> exception messageText asString) } asDictionary) }
			asDictionary
]

{ #category : 'dap' }
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

{ #category : 'dap' }
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

	'change debugger' record.
	OupsDebuggerSelectionStrategy debuggerSelectionStrategy: strategy.
	"we recove the old debugger once we receive the #debuggSession: strategy is an instance var
	jmari: I think it's better reactivate the normal debugger once we hace received the debugSession 
	for debugging purposes "
	'terminated' record.
	self shouldStop: true.
	self sendMessage: DAPTerminatedEvent new
]

{ #category : 'dap - launch' }
DAPServer >> dapLaunchedEvaluate: aDAPEvaluateRequest [
	"Evaluate in a frame of a launched program"

	| localContext expression localCompiler |
	localContext := self getStacks
		                detect: [ :aStack |
			                aStack hash
			                = (aDAPEvaluateRequest arguments at: #frameId) ]
		                ifNone: [ nil ].
	expression := '^ ' , (aDAPEvaluateRequest arguments at: #expression).
	localCompiler := (self compilerFor: nil)
		                 context: localContext;
		                 yourself.
	self sendMessage: (DAPEvaluateResponse new
			 seq: self nextSeq;
			 request_seq: aDAPEvaluateRequest seq;
			 command: aDAPEvaluateRequest command;
			 result: ([ localCompiler evaluate: expression ]
					  on: Exception
					  do: [ :err | err printString ]) printString;
			 variablesReference: 0)
]

{ #category : 'dap - launch' }
DAPServer >> dapLaunchedScopes: aDAPScopesRequest [
	"Answer the scope of a frame of a launched program"

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

{ #category : 'dap - launch' }
DAPServer >> dapLaunchedStackTrace: aDAPStackTraceRequest [
	"Answer the stack of a launched program"

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

{ #category : 'dap - launch' }
DAPServer >> dapLaunchedVariables: aDAPVariablesRequest [
	"Answer the variables of a frame of a launched program"

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

{ #category : 'dap' }
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

{ #category : 'dap' }
DAPServer >> dapPharoCreateMissingMethod: aDAPRequest [
	"Implement the message that the process did not find in the class of its receiver, or in the class and the protocol that the client chose, and go on in the new method, as the Create button of the debugger of Pharo does. A subclassResponsibility is implemented in the class of the receiver as well.
	 Answer the URI of the editor of the new method"
	<dap: #pharoCreateMissingMethod>

	| missing class protocol arguments |
	missing := self missingMethod ifNil: [
		           ^ self
			             respondTo: aDAPRequest
			             failure: 'The process did not stop on a message not understood or a subclassResponsibility.' ].
	arguments := aDAPRequest arguments.
	class := (arguments at: #className ifAbsent: [ nil ])
		         ifNil: [ self missingMethodReceiverClass ]
		         ifNotNil: [ :name |
			         Smalltalk globals
				         at: name asSymbol
				         ifAbsent: [
					         ^ self
						           respondTo: aDAPRequest
						           failure: 'Unknown class ' , name ] ].
	protocol := (arguments at: #protocol ifAbsent: [ nil ])
		            ifNil: [ Protocol unclassified ]
		            ifNotNil: [ :name | name asSymbol ].
	(debugSession exception isKindOf: MessageNotUnderstood)
		ifTrue: [
			debugSession
				implement: missing key
				classified: protocol
				inClass: class
				forContext: missing value ]
		ifFalse: [
			class
				compile: (DynamicMessageImplementor for: missing key in: class) value
				classified: protocol.
			debugSession
				rewindContextToMethod: (class >> missing key selector)
				fromContext: missing value ].
	self respondTo: aDAPRequest body: { (#uri
		 -> (plsServer navUriOfMethod: class >> missing key selector)) }
			asDictionary.
	self sendStopped: 'goto'
]

{ #category : 'dap' }
DAPServer >> dapPharoInspectVariable: aDAPRequest [
	"Register the object of a variable of the Variables view in the inspector of the language server, and answer its reference there: { ref }"

	<dap: #pharoInspectVariable>
	| arguments object |
	arguments := aDAPRequest arguments.
	object := ((variablesObjects ifNil: [ Dictionary new ])
		           at: (arguments at: #variablesReference)
		           ifAbsent: [ Dictionary new ])
		          at: (arguments at: #name)
		          ifAbsent: [
				          ^ self
					            respondTo: aDAPRequest
					            failure:
					            'This variable is no longer shown by the debugger.' ].
	(plsServer respondsTo: #inspectorRegister:) ifFalse: [
			^ self
				  respondTo: aDAPRequest
				  failure: 'The language server has no inspector.' ].
	self
		respondTo: aDAPRequest
		body:
		{ (#ref -> (plsServer inspectorRegister: object)) } asDictionary
]

{ #category : 'dap' }
DAPServer >> dapPharoMissingMethod: aDAPRequest [
	"Describe the method that the stopped process misses, to let the client choose the class and the protocol of the new method"
	<dap: #pharoMissingMethod>

	| missing class |
	missing := self missingMethod ifNil: [
		           ^ self
			             respondTo: aDAPRequest
			             failure: 'The process did not stop on a message not understood or a subclassResponsibility.' ].
	class := self missingMethodReceiverClass.
	self respondTo: aDAPRequest body: {
			(#kind -> ((debugSession exception isKindOf: MessageNotUnderstood)
				  ifTrue: [ 'doesNotUnderstand' ]
				  ifFalse: [ 'subclassResponsibility' ])).
			(#selector -> missing key selector asString).
			(#className -> class name asString).
			(#classes -> (class withAllSuperclasses
				  reject: [ :each | each == ProtoObject ]
				  thenCollect: [ :each | each name asString ])).
			(#protocols -> ((class withAllSuperclasses
				  flatCollect: [ :each | each protocols collect: [ :protocol | protocol name asString ] ]
				  as: Set) reject: [ :name | name beginsWith: '*' ]) asSortedCollection asArray) } asDictionary
]

{ #category : 'dap' }
DAPServer >> dapPharoRestart: aDAPRequest [
	"Run a restart of the stopped exception, with the value of the expression of the client when it needs one"
	<dap: #pharoRestart>

	| arguments id value frame |
	arguments := aDAPRequest arguments.
	id := arguments at: #id.
	frame := debugSession interruptedContext.
	(#(#returnValue #resumeWith) includes: id asSymbol) ifTrue: [
		value := [ self evaluate: (arguments at: #expression) in: frame ]
			         on: Error , Halt , Warning
			         do: [ :exception |
				         ^ self respondTo: aDAPRequest failure: exception description ] ].
	id = 'proceed' ifTrue: [
		self respondTo: aDAPRequest body: nil.
		self sendEvent: 'continued' body: {
				(#threadId -> self threads associations anyOne key).
				(#allThreadsContinued -> true) } asDictionary.
		^ debugSession resume ].
	id = 'retry' ifTrue: [
		debugSession restart: frame.
		self respondTo: aDAPRequest body: nil.
		^ self sendStopped: 'restart' ].
	id = 'returnValue' ifTrue: [
		debugSession returnValue: value from: frame.
		self respondTo: aDAPRequest body: nil.
		^ self sendStopped: 'step' ].
	id = 'resumeWith' ifTrue: [
		self respondTo: aDAPRequest body: nil.
		self sendEvent: 'continued' body: {
				(#threadId -> self threads associations anyOne key).
				(#allThreadsContinued -> true) } asDictionary.
		^ debugSession resume: value ].
	^ self respondTo: aDAPRequest failure: 'Unknown restart ' , id asString
]

{ #category : 'dap' }
DAPServer >> dapPharoRestarts: aDAPRequest [
	"The restarts of the stopped exception, like the restarts of the debuggers of Lisp"
	<dap: #pharoRestarts>

	| restarts |
	restarts := OrderedCollection new.
	restarts
		add: { (#id -> 'proceed'). (#label -> 'Proceed'). (#detail -> 'Resume the process after the exception') . (#needsValue -> false)} asDictionary;
		add: { (#id -> 'retry'). (#label -> 'Retry'). (#detail -> 'Restart the method that raised the exception'). (#needsValue -> false) } asDictionary;
		add: { (#id -> 'returnValue'). (#label -> 'Return value…'). (#detail -> 'Return an expression from the method that raised the exception'). (#needsValue -> true) } asDictionary;
		add: { (#id -> 'resumeWith'). (#label -> 'Resume with…'). (#detail -> 'Resume the exception with an expression as the value of the signal'). (#needsValue -> true) } asDictionary.
	self missingMethod ifNotNil: [
		restarts add: { (#id -> 'create'). (#label -> 'Create'). (#detail -> 'Implement the missing method and go on in it'). (#needsValue -> false) } asDictionary ].
	self respondTo: aDAPRequest body: { (#restarts -> restarts asArray) } asDictionary
]

{ #category : 'dap' }
DAPServer >> dapRestartFrame: aDAPRestartFrameRequest [
	"Restart the frame, in the method as it is now when it changed since the frame started, as the debugger of Pharo does when a method of the stack is saved"

	<dap: #restartFrame>
	| frame method |
	frame := self contextAt:
		         (aDAPRestartFrameRequest arguments at: #frameId).
	(frame isBlockContext and: [
			 (self installedMethodOf: frame method method)
			 ~~ frame method method and: [
				 debugSession interruptedContext stack includes: frame home ] ])
		ifTrue: [ frame := frame home ].
	method := self installedMethodOf: frame method.
	(frame isBlockContext not and: [
		 method notNil and: [ method ~~ frame method ] ])
		ifTrue: [
		debugSession rewindContextToMethod: method fromContext: frame ]
		ifFalse: [ debugSession restart: frame ].
	self respondTo: aDAPRestartFrameRequest body: nil.
	self sendStopped: 'restart'
]

{ #category : 'dap' }
DAPServer >> dapScopes: aDAPScopesRequest [
	"Answer the Context scope of the frame, with its arguments and temporaries, and its Receiver scope, as the debugger of Pharo shows them side by side"

	<dap: #scopes>
	| frame |
	attachedSessionId ifNil: [
		^ self dapLaunchedScopes: aDAPScopesRequest ].
	frame := self contextAt: (aDAPScopesRequest arguments at: #frameId).
	self respondTo: aDAPScopesRequest body: { (#scopes -> {
			 {
				 (#name -> 'Context').
				 (#presentationHint -> 'locals').
				 (#expensive -> false).
				 (#variablesReference
				  ->
				  (self referenceForVariables: [ self contextVariablesOf: frame ])) }
				 asDictionary.
			 {
				 (#name -> 'Receiver').
				 (#expensive -> false).
				 (#variablesReference
				  ->
				  (self referenceForVariables: [ self receiverVariablesOf: frame ])) }
				 asDictionary }) } asDictionary
]

{ #category : 'dap' }
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

{ #category : 'dap' }
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

{ #category : 'dap' }
DAPServer >> dapSource: aDAPSourceRequest [

	<dap: #source>
	self sendMessage: (DAPSourceResponse new
			 seq: self nextSeq;
			 request_seq: aDAPSourceRequest seq;
			 command: aDAPSourceRequest command;
			 content: (sourcesReferenceCache
					  at: (aDAPSourceRequest arguments at: #sourceReference)
					  ifPresent: [ :code |
							  | source |
							  source := code sourceCode
								            copyReplaceAll: String cr
								            with: String lf.
							  "The columns of the frames of an attached process count the tabs"
							  attachedSessionId
								  ifNil: [ source copyReplaceAll: String tab with: '    ' ]
								  ifNotNil: [ source ] ]
					  ifAbsent: [ 'Debugger cannot get block source code yet' ]);
			 mimeType: 'pharo';
			 yourself)
]

{ #category : 'debugger support' }
DAPServer >> dapSourceOf: aMethod [
	"Answer the source of a frame of aMethod: the editor of the method when it is installed, so that the client can change it, else its source code as the server keeps it"

	(self isEditable: aMethod) ifTrue: [
			^ DAPSource new
				  name: aMethod printString;
				  path: (plsServer navUriOfMethod: aMethod);
				  sourceReference: 0;
				  yourself ].
	sourcesReferenceCache at: aMethod hash put: aMethod.
	^ DAPSource new
		  name: aMethod printString;
		  sourceReference: aMethod hash;
		  yourself
]

{ #category : 'debugger support' }
DAPServer >> dapStackFrameOf: aContext [
	"Answer the frame of aContext, on the range of the node it executes in the source of its method"

	| frame method start stop |
	method := aContext method method.
	frame := DAPStackFrame new
		         id: aContext hash;
		         name: aContext printString;
		         source: (self dapSourceOf: method);
		         yourself.
	[
		| node |
		node := aContext sourceNodeExecuted.
		start := self lineColumnOf: node start in: method sourceCode.
		stop := self lineColumnOf: node stop + 1 in: method sourceCode ]
		on: Error
		do: [ start := stop := 1 @ 1 ].
	^ frame
		  line: start x;
		  column: start y;
		  endLine: stop x;
		  endColumn: stop y;
		  yourself
]

{ #category : 'dap' }
DAPServer >> dapStackTrace: aDAPStackTraceRequest [

	<dap: #stackTrace>
	| stack arguments start levels contexts |
	attachedSessionId ifNil: [
		^ self dapLaunchedStackTrace: aDAPStackTraceRequest ].
	stack := debugSession interruptedContext stack.
	arguments := aDAPStackTraceRequest arguments ifNil: [ Dictionary new ].
	start := (arguments at: #startFrame ifAbsent: [ 0 ]) min: stack size.
	levels := arguments at: #levels ifAbsent: [ 0 ].
	contexts := stack copyFrom: start + 1 to: (levels = 0
			             ifTrue: [ stack size ]
			             ifFalse: [ start + levels min: stack size ]).
	self respondTo: aDAPStackTraceRequest body: {
			(#stackFrames
			 ->
			 (contexts
				  collect: [ :each | self dapStackFrameOf: each ]
				  as: Array)).
			(#totalFrames -> stack size) } asDictionary
]

{ #category : 'dap' }
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

{ #category : 'dap' }
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

{ #category : 'dap' }
DAPServer >> dapTerminateThreads: aDAPRequest [
	"Terminate the attached process, as the debugger of Pharo does when it closes without resuming, and end the debug session"

	<dap: #terminateThreads>
	| ids |
	ids := (aDAPRequest arguments ifNil: [ Dictionary new ])
		       at: #threadIds
		       ifAbsent: [ #(  ) ].
	(attachedSessionId isNotNil and: [
			 debugSession isNotNil and: [
				 ids isEmpty or: [ ids includes: attachedSessionId ] ] ])
		ifFalse: [
				^ self
					  respondTo: aDAPRequest
					  failure:
					  'Only the process the debugger is attached to can be terminated.' ].
	debugSession terminate.
	debugSession := nil.
	self respondTo: aDAPRequest body: nil.
	self sendEvent: 'terminated' body: Dictionary new
]

{ #category : 'dap' }
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

{ #category : 'dap' }
DAPServer >> dapVariables: aDAPVariablesRequest [

	<dap: #variables>
	attachedSessionId ifNil: [
		^ self dapLaunchedVariables: aDAPVariablesRequest ].
	self
		respondTo: aDAPVariablesRequest
		body: { (#variables -> (self variablesAt:
				  (aDAPVariablesRequest arguments at: #variablesReference))) }
				asDictionary
]

{ #category : 'accessing' }
DAPServer >> debugMode [
	^ debugMode
]

{ #category : 'accessing' }
DAPServer >> debugMode: anObject [
	debugMode := anObject
]

{ #category : 'debugger support' }
DAPServer >> debugSession: aDebugSession [

	'Start debug session' record.
	('Description: ' , aDebugSession exception printString) record.
	debugSession := aDebugSession.
	self sendMessage: (DAPStoppedEvent new
			 seq: self nextSeq;
			 description: aDebugSession exception printString;
			 threadId: self threads associations anyOne key;
			 reason: 'exception';
			 yourself)
]

{ #category : 'debugger support' }
DAPServer >> evaluate: aString in: aContext [
	"Evaluate aString as if it were in the method of aContext, with its receiver, arguments and temporaries, or as a doit without a context"

	aContext ifNil: [ ^ (self compilerFor: nil) evaluate: aString ].
	^ aContext receiver class compiler
		  source: aString;
		  context: aContext;
		  receiver: aContext receiver;
		  evaluate
]

{ #category : 'starting' }
DAPServer >> extractLengthOf: aData [
	(aData beginsWith: 'Content-Length: ')
		ifTrue:
			[ ^ aData asInteger ]
		ifFalse: [ ^ -1 ]
]

{ #category : 'starting' }
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

{ #category : 'dap' }
DAPServer >> fileNameForCode: aName [
	^ ''
]

{ #category : 'accessing' }
DAPServer >> getAllBreakpoints [ 
	"breakpoint is a source->breakpoints array dictionary"
	| oc |
	oc := OrderedCollection new.
	
	self breakpoints associationsDo:[ :anAssociation | 
		oc add:{ #source:->anAssociation key. #breakpoints->anAssociation value } asDictionary ].
	^oc asArray
	
]

{ #category : 'starting' }
DAPServer >> getDatafromPosition: startingPoint fromSocket: clientSocket in: existingData [
	clientSocket receiveDataInto: existingData startingAt: startingPoint
]

{ #category : 'starting' }
DAPServer >> getHeaderFor: answer into: aStream [
	aStream << 'Content-Length: ' << answer size asString << String crlf
		<< String crlf
]

{ #category : 'accessing' }
DAPServer >> getStacks [ 

	^ debugSession stackOfSize: self numberOfStacks.

]

{ #category : 'debugger support' }
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

{ #category : 'starting' }
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

{ #category : 'starting' }
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

{ #category : 'handlers management' }
DAPServer >> handlerFor: aDAPRequest [
	aDAPRequest command isString
		ifFalse: [ DAPIncorrectJSON signal ].
	^ handlers
		detect: [ :handler | handler methodName = aDAPRequest command ]
		ifNone: [ DAPNonExistentHandler signal: aDAPRequest command ]
]

{ #category : 'debugger support' }
DAPServer >> hasVariables: anObject [
	"Answer whether the client can expand anObject into its slots and indexed items"

	(anObject isNil or: [
			 anObject isNumber or: [
					 anObject isString or: [
						 anObject isCharacter or: [
							 anObject == true or: [ anObject == false ] ] ] ] ]) ifTrue: [
		^ false ].
	^ (thisContext objectClass: anObject) instSize > 0 or: [
		  (thisContext objectSize: anObject) > 0 ]
]

{ #category : 'initialize' }
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

{ #category : 'debugger support' }
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

{ #category : 'debugger support' }
DAPServer >> insertHaltsIn: source using:breakpointList [
	| sourceLines stream |
	sourceLines := source deepCopy findTokens: String lf.
	stream := WriteStream on: String new.
	
	breakpointList do:[ :aBreakpointIndex |
		self insertBestHaltOn: sourceLines at: (aBreakpointIndex at:#line) ].
	sourceLines do:[ :aLine | stream nextPutAll: aLine;crlf ].
	^ stream contents
]

{ #category : 'debugger support' }
DAPServer >> installedMethodOf: aMethod [
	"Answer the method that the class of aMethod has now under its selector, or nil when it has none"

	^ aMethod methodClass
		  compiledMethodAt: aMethod selector
		  ifAbsent: [ nil ]
]

{ #category : 'debugger support' }
DAPServer >> isEditable: aMethod [
	"Answer whether the client can open aMethod in its editor: an installed method, not a doit"

	^ plsServer notNil and: [
		  aMethod isDoIt not and: [ aMethod isInstalled ] ]
]

{ #category : 'accessing' }
DAPServer >> isJustMyCode [
	^ justMyCode ifNil:[ justMyCode:= false ]
]

{ #category : 'debugger support' }
DAPServer >> isObsolete [
	^ true
]

{ #category : 'testing' }
DAPServer >> isRunning [
	^ serverLoop
]

{ #category : 'accessing' }
DAPServer >> justMyCode [
	justMyCode := true
]

{ #category : 'debugger support' }
DAPServer >> lineColumnOf: index in: aString [
	"Answer the one-based line and column of the character at index in aString"

	| line lineStart |
	line := 1.
	lineStart := 1.
	1 to: (index - 1 min: aString size) do: [ :i |
			| character |
			character := aString at: i.
			(character = Character lf or: [
					 character = Character cr and: [
						 (i < aString size and: [ (aString at: i + 1) = Character lf ])
							 not ] ]) ifTrue: [
					line := line + 1.
					lineStart := i + 1 ] ].
	^ line @ (index - lineStart + 1)
]

{ #category : 'accessing' }
DAPServer >> lineOffset [

	^ lineOffset ifNil:[ lineOffset := 0 ]
]

{ #category : 'accessing' }
DAPServer >> lineOffset: anObject [

	lineOffset := anObject
]

{ #category : 'context' }
DAPServer >> messageProcess: anId [	
	^ self context messageProcessesAt: anId 
]

{ #category : 'context' }
DAPServer >> messageProcess: anId	put: aProcess [
	self context messageProcessesAt: anId put: aProcess
]

{ #category : 'dap-helpers' }
DAPServer >> missingMethod [
	"Answer an association, the message that the stopped process cannot find and the context to restart once it is implemented, or nil when the process did not stop on a missing method"

	| exception frame |
	exception := debugSession exception.
	(exception isKindOf: MessageNotUnderstood) ifTrue: [
		^ exception message -> debugSession interruptedContext ].
	(exception isKindOf: SubclassResponsibility) ifTrue: [
		frame := debugSession interruptedContext stack
			         detect: [ :each | each selector ~~ #subclassResponsibility ]
			         ifNone: [ ^ nil ].
		^ (Message selector: frame selector arguments: frame arguments) -> frame ].
	^ nil
]

{ #category : 'dap-helpers' }
DAPServer >> missingMethodReceiverClass [
	"The class where the missing method is implemented by default: the class of the receiver of the message"

	| missing |
	missing := self missingMethod.
	^ thisContext objectClass: ((debugSession exception isKindOf: MessageNotUnderstood)
			   ifTrue: [ debugSession exception receiver ]
			   ifFalse: [ missing value receiver ])
]

{ #category : 'accessing' }
DAPServer >> nextSeq [
	^ current_seq := current_seq + 1
]

{ #category : 'accessing' }
DAPServer >> numberOfStacks [
	^ numberOfStacks ifNil:[ numberOfStacks := 10 ]
]

{ #category : 'accessing' }
DAPServer >> numberOfStacks: anInteger [
	numberOfStacks := anInteger
]

{ #category : 'debugger support' }
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

{ #category : 'starting' }
DAPServer >> parseJSON: aJSONString [
	| jsonObject |
	jsonObject := STONJSON fromString: aJSONString.
	^ DAPRequest newFromJSON: jsonObject
]

{ #category : 'debugger support' }
DAPServer >> plsServer [

	^ plsServer
]

{ #category : 'debugger support' }
DAPServer >> plsServer: aPLSServer [
	"The language server that keeps the processes stopped on an exception, which this server attaches to"

	plsServer := aPLSServer
]

{ #category : 'accessing' }
DAPServer >> pluggableCompilationBlock [

	^ pluggableEvaluationBlock ifNil: [ 
		  pluggableEvaluationBlock := [ :source | 
		                              compiler
			                              source: source;
			                              compile ] ]
]

{ #category : 'accessing' }
DAPServer >> pluggableCompilationBlock: aOneArgBlock [
	pluggableEvaluationBlockSender := thisContext sender. 
	pluggableEvaluationBlock := aOneArgBlock
]

{ #category : 'debugger support' }
DAPServer >> printStringOf: anObject [

	^ [ anObject printStringLimitedTo: 1000 ]
		  on: Error
		  do: [ :error |
				  'Error printing a ' , (thisContext objectClass: anObject) name
				  , ': ' , error messageText asString ]
]

{ #category : 'debugger support' }
DAPServer >> receiverVariablesOf: aContext [
	"Answer the variables of the Receiver scope of aContext: self and its slots, which an expression of the frame reads by their names"

	| receiver |
	receiver := aContext receiver.
	^ (OrderedCollection with:
			   (self variableNamed: 'self' value: receiver evaluateName: 'self'))
		  addAll: ((thisContext objectClass: receiver) allInstVarNames
				   withIndexCollect: [ :name :index |
						   self
							   variableNamed: name
							   value: (thisContext object: receiver instVarAt: index)
							   evaluateName: name ]);
		  yourself
]

{ #category : 'debugger support' }
DAPServer >> referenceForVariables: aBlock [
	"Answer a new reference to the variables that aBlock answers, valid until the process stops again"

	| reference |
	variablesReferenceCache ifNil: [
		variablesReferenceCache := Dictionary new ].
	reference := variablesReferenceCache size + 1.
	variablesReferenceCache at: reference put: aBlock.
	^ reference
]

{ #category : 'context' }
DAPServer >> removeMessageProcess: anId [
	self context removeMessageProcess: anId
]

{ #category : 'cache' }
DAPServer >> resetCache [
	variablesReferenceCache removeAll.
	sourcesReferenceCache removeAll
]

{ #category : 'context' }
DAPServer >> resetContext [
	serverContext := DAPContext new
]

{ #category : 'debugger support' }
DAPServer >> respondTo: aDAPRequest body: aBody [

	self sendMessage: (DAPResponse new
			 seq: self nextSeq;
			 request_seq: aDAPRequest seq;
			 command: aDAPRequest command;
			 body: aBody;
			 yourself)
]

{ #category : 'debugger support' }
DAPServer >> respondTo: aDAPRequest failure: aString [

	self sendMessage: (DAPResponse new
			 seq: self nextSeq;
			 request_seq: aDAPRequest seq;
			 command: aDAPRequest command;
			 success: false;
			 message: aString;
			 yourself)
]

{ #category : 'starting' }
DAPServer >> sendData: answer toClient: clientSocket [
	answer
		ifNotEmpty: [ clientSocket
				sendData:
					(String
						streamContents: [ :contentStream | 
							self getHeaderFor: answer into: contentStream.
							contentStream << answer ]) ]
]

{ #category : 'debugger support' }
DAPServer >> sendEvent: aString body: aDictionary [

	self sendMessage: (DAPEvent new
			 seq: self nextSeq;
			 event: aString;
			 body: aDictionary;
			 yourself)
]

{ #category : 'starting' }
DAPServer >> sendMessage: aDAPMessage [
	self sendData: (aDAPMessage beConvertedBy: self) toClient: socketClient
]

{ #category : 'debugger support' }
DAPServer >> sendStopped: reason [
	"Tell the client that the debugged process stopped. The references to its variables of the previous stop are no longer valid"

	variablesReferenceCache := Dictionary new.
	variablesObjects := Dictionary new.
	self sendEvent: 'stopped' body: {
			(#reason -> reason).
			(#description -> (debugSession exception
				  ifNil: [ debugSession name asString ]
				  ifNotNil: [ :exception | exception description ])).
			(#threadId -> self threads associations anyOne key).
			(#allThreadsStopped -> true) } asDictionary
]

{ #category : 'debugger support' }
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

{ #category : 'accessing' }
DAPServer >> shouldStop [

	"this variable should be at true when the execution is over"

	^ shouldStop ifNil: [ ^ false ]
]

{ #category : 'accessing' }
DAPServer >> shouldStop: anObject [

	shouldStop := anObject
]

{ #category : 'starting' }
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

{ #category : 'stopping' }
DAPServer >> stop [
	serverLoop := false.
	tcpServer closeAndDestroy.
	
	"Ensure process finishes."
	(process isNil or:[ process isTerminated])
		ifTrue: [ ^ self ].
	process terminate
]

{ #category : 'accessing' }
DAPServer >> threads [
	^ threads
]

{ #category : 'accessing' }
DAPServer >> threads: anObject [
	threads := anObject
]

{ #category : 'debugger support' }
DAPServer >> variableNamed: aString value: anObject evaluateName: anExpression [
	"Answer the DAP variable that shows anObject under aString. The client evaluates anExpression, when not nil, to get anObject again"

	| variable |
	currentVariablesObjects ifNotNil: [ :objects |
		objects at: aString asString put: anObject ].
	variable := Dictionary new
		            at: #name put: aString asString;
		            at: #value put: (self printStringOf: anObject);
		            at: #type
		            put: (thisContext objectClass: anObject) name asString;
		            at: #variablesReference
		            put: ((self hasVariables: anObject)
				             ifTrue: [
					             self referenceForVariables: [
							             self variablesOf: anObject ] ]
				             ifFalse: [ 0 ]);
		            yourself.
	anExpression ifNotNil: [
		variable at: #evaluateName put: anExpression ].
	^ variable
]

{ #category : 'debugger support' }
DAPServer >> variablesAt: reference [
	"Answer the variables of the reference, and remember the objects they show by their names, for the inspector"

	| variables |
	currentVariablesObjects := Dictionary new.
	[
		variables := (variablesReferenceCache
			              at: reference
			              ifAbsent: [ [ #(  ) ] ]) value asArray ] ensure: [
			(variablesObjects ifNil: [ variablesObjects := Dictionary new ])
				at: reference
				put: currentVariablesObjects.
			currentVariablesObjects := nil ].
	^ variables
]

{ #category : 'debugger support' }
DAPServer >> variablesOf: anObject [
	"Answer the variables of the slots and indexed items of anObject, as the Raw view of the inspector shows them"

	| nodes |
	nodes := [
		         anObject allInspectorNodes reject: [ :node |
			         node isKindOf: StInspectorSelfNode ] ]
		         on: Error
		         do: [
				         ^ (thisContext objectClass: anObject) allInstVarNames
					           withIndexCollect: [ :name :index |
							           self
								           variableNamed: name
								           value:
								           (thisContext object: anObject instVarAt: index)
								           evaluateName: nil ] ].
	^ nodes
		  collect: [ :node |
			  self
				  variableNamed: node label
				  value: node rawValue
				  evaluateName: nil ]
		  as: Array
]
