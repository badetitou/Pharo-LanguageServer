"
I test how the server hands a process stopped on an unhandled exception to a debugger of the client: the pls-debug/stopped notification, the pending debug sessions, and the Debug Adapter Protocol requests on them.
"
Class {
	#name : 'PLSServerDebugTest',
	#superclass : 'TestCase',
	#instVars : [
		'server',
		'output',
		'sessions',
		'adapters'
	],
	#category : 'PharoLanguageServer-Tests',
	#package : 'PharoLanguageServer-Tests'
}

{ #category : 'helpers' }
PLSServerDebugTest >> attachTo: aBlock [
	"Evaluate aBlock until it stops on an exception, and answer a DAP server attached to the stopped process"

	| adapter |
	server debugEvaluate: aBlock ifStopped: [ ].
	adapter := PLSDAPServerRecorder new
		           plsServer: server;
		           debugMode: false;
		           yourself.
	(adapters ifNil: [ adapters := OrderedCollection new ]) add: adapter.
	self assert:
		((adapter request: 'attach' arguments: { (#debugSessionId
			   -> ((self stoppedNotifications last at: #params) at: #id)) })
			 at: #success).
	^ adapter
]

{ #category : 'helpers' }
PLSServerDebugTest >> frameOf: selector in: adapter [

	^ (self frames: adapter) detect: [ :frame |
		  (frame at: #name) endsWith: '>>' , selector ]
]

{ #category : 'helpers' }
PLSServerDebugTest >> frames: adapter [

	^ ((adapter request: 'stackTrace' arguments: { (#threadId -> 1) })
		   at: #body) at: #stackFrames
]

{ #category : 'helpers' }
PLSServerDebugTest >> newProbeClass [
	"Answer a class whose methods stop on errors"

	| class |
	class := ((Object << #PLSDebugProbe)
		          slots: { #count };
		          package: self probePackageName) install.
	class
		compile: 'divide
	^ 1 / 0'
		classified: 'probing'.
	class
		compile: 'sum
	| a b |
	a := 3.
	b := 4.
	count := a + b.
	^ count / 0'
		classified: 'probing'.
	^ class
]

{ #category : 'helpers' }
PLSServerDebugTest >> newProbeTest [
	"Answer a test class with a passing, a failing and an erroring test"

	| class |
	class := (TestCase << #PLSDebugProbeTest package:
		          self probePackageName) install.
	class compile: 'testPasses self assert: true' classified: 'tests'.
	class
		compile: 'testFails self assert: 1 equals: 2'
		classified: 'tests'.
	class compile: 'testErrors 1 / 0' classified: 'tests'.
	^ class
]

{ #category : 'helpers' }
PLSServerDebugTest >> probePackageName [

	^ 'PLSDebugProbe'
]

{ #category : 'running' }
PLSServerDebugTest >> setUp [

	super setUp.
	output := WriteStream on: ByteArray new.
	server := PLSServer new.
	server clientOutStream: output.
	sessions := OrderedCollection new
]

{ #category : 'helpers' }
PLSServerDebugTest >> stoppedNotifications [

	| stream notifications |
	stream := ReadStream on: output contents.
	notifications := OrderedCollection new.
	[ stream atEnd ] whileFalse: [
			| headers length |
			headers := (stream upToAll: #[ 13 10 13 10 ]) asString.
			length := (headers lines detect: [ :line |
				           line beginsWith: 'Content-Length: ' ]) allButFirst: 16.
			notifications add:
				(STONJSON fromString: (stream next: length asInteger) utf8Decoded) ].
	^ notifications select: [ :notification |
		  (notification at: #method) = 'pls-debug/stopped' ]
]

{ #category : 'helpers' }
PLSServerDebugTest >> takeStoppedSession [
	"Answer the debug session of the last pls-debug/stopped notification, as a debugger of the client takes it"

	| session |
	session := server debugSessionAt:
		           ((self stoppedNotifications last at: #params) at: #id).
	sessions add: session.
	^ session
]

{ #category : 'running' }
PLSServerDebugTest >> tearDown [
	adapters ifNotNil: [
		adapters do: [ :adapter | adapter request: 'disconnect' arguments: {  } ] ].
	sessions do: [ :session | session terminate ].
	self stoppedNotifications do: [ :notification |
		[ (server debugSessionAt: ((notification at: #params) at: #id)) terminate ]
			on: PLSUnknownEntity
			do: [ ] ].
	#( #PLSDebugProbeTest #PLSDebugProbe ) do: [ :name |
		self class environment
			at: name
			ifPresent: [ :class | class removeFromSystem ] ].
	self packageOrganizer removePackage: self probePackageName.
	super tearDown
]

{ #category : 'tests - dap' }
PLSServerDebugTest >> testAttachStopsOnTheException [

	| adapter stopped |
	adapter := self attachTo: [ 1 / 0 ].
	stopped := (adapter events: 'stopped') last at: #body.
	self assert: (stopped at: #reason) equals: 'exception'.
	self assert:
		((stopped at: #description) includesSubstring: 'ZeroDivide')
]

{ #category : 'tests - dap' }
PLSServerDebugTest >> testAttachToAnUnknownSessionFails [

	| adapter |
	adapter := PLSDAPServerRecorder new
		           plsServer: server;
		           debugMode: false;
		           yourself.
	self deny:
		((adapter
			  request: 'attach'
			  arguments: { (#debugSessionId -> 12345) }) at: #success)
]

{ #category : 'tests - dap' }
PLSServerDebugTest >> testCreateMissingMethodGoesOnInTheNewMethod [

	| probe adapter response |
	probe := self newProbeClass.
	adapter := self attachTo: [ probe new missing: 3 ].
	response := adapter
		            request: 'pharoCreateMissingMethod'
		            arguments: {  }.
	self assert: (response at: #success).
	self assert: (probe includesSelector: #missing:).
	self
		assert: ((response at: #body) at: #uri)
		equals: (server navUriOfMethod: probe >> #missing:).
	self
		assert: ((self frames: adapter) first at: #name)
		equals: 'PLSDebugProbe>>missing:'
]

{ #category : 'tests - dap' }
PLSServerDebugTest >> testCreateMissingMethodNeedsAMessageNotUnderstood [

	| adapter |
	adapter := self attachTo: [ 1 / 0 ].
	self deny:
		((adapter request: 'pharoCreateMissingMethod' arguments: {  }) at:
			 #success)
]

{ #category : 'tests' }
PLSServerDebugTest >> testDebuggedErroringTestStopsOnItsError [

	| result session |
	self newProbeTest.
	result := server plsTestDebugTest: (self testURIOf: 'testErrors').
	self assert: (result at: #errors) size equals: 1.
	session := self takeStoppedSession.
	self assert: (session exception isKindOf: ZeroDivide)
]

{ #category : 'tests' }
PLSServerDebugTest >> testDebuggedFailingTestStopsOnItsFailure [

	| result session |
	self newProbeTest.
	result := server plsTestDebugTest: (self testURIOf: 'testFails').
	self assert: (result at: #failures) size equals: 1.
	session := self takeStoppedSession.
	self assert: (session exception isKindOf: TestFailure).
	self assert:
		(session interruptedContext stack anySatisfy: [ :context |
			 context selector = #testFails ])
]

{ #category : 'tests' }
PLSServerDebugTest >> testDebuggedPassingTestAnswersItsResult [

	| result |
	self newProbeTest.
	result := server plsTestDebugTest: (self testURIOf: 'testPasses').
	self assert: (result at: #passed) size equals: 1.
	self assert: self stoppedNotifications isEmpty
]

{ #category : 'tests' }
PLSServerDebugTest >> testDebuggerTakesASessionOnce [

	| id |
	server debugEvaluate: [ 1 / 0 ] ifStopped: [ ].
	id := (self stoppedNotifications first at: #params) at: #id.
	sessions add: (server debugSessionAt: id).
	self should: [ server debugSessionAt: id ] raise: PLSUnknownEntity
]

{ #category : 'tests - dap' }
PLSServerDebugTest >> testDisconnectTerminatesTheProcess [

	| adapter value process |
	adapter := self attachTo: [
			           1 / 0.
			           value := #after ].
	process := (adapter instVarNamed: 'debugSession') interruptedProcess.
	adapter request: 'disconnect' arguments: {  }.
	self assert: process isTerminated.
	self assert: value isNil
]

{ #category : 'tests' }
PLSServerDebugTest >> testDismissEndsTheStoppedProcess [
	| id process |
	server debugEvaluate: [ 1 / 0 ] ifStopped: [  ].
	id := (self stoppedNotifications first at: #params) at: #id.
	process := (server instVarNamed: 'debugSessions') at: id.
	process := process interruptedProcess.
	self assert: (server plsDebugDismiss: id).
	self assert: process isTerminated.
	self deny: (server plsDebugDismiss: id)
]

{ #category : 'tests - dap' }
PLSServerDebugTest >> testEvaluateInTheFrame [

	| probe adapter frame response |
	probe := self newProbeClass.
	adapter := self attachTo: [ probe new sum ].
	frame := self frameOf: 'sum' in: adapter.
	response := adapter request: 'evaluate' arguments: {
			            (#expression -> 'a * b + count').
			            (#frameId -> (frame at: #id)).
			            (#context -> 'repl') }.
	self assert: ((response at: #body) at: #result) equals: '19'.
	response := adapter request: 'evaluate' arguments: {
			            (#expression -> 'nil foo').
			            (#frameId -> (frame at: #id)).
			            (#context -> 'repl') }.
	self deny: (response at: #success)
]

{ #category : 'tests' }
PLSServerDebugTest >> testEvaluationWithoutErrorAnswersItsValue [

	self
		assert: (server debugEvaluate: [ 3 + 4 ] ifStopped: [ #stopped ])
		equals: 7.
	self assert: self stoppedNotifications isEmpty
]

{ #category : 'tests - dap' }
PLSServerDebugTest >> testExceptionInfoNamesTheException [

	| adapter info |
	adapter := self attachTo: [ 1 / 0 ].
	info := (adapter
		         request: 'exceptionInfo'
		         arguments: { (#threadId -> 1) }) at: #body.
	self assert: (info at: #exceptionId) equals: 'ZeroDivide'.
	self assert: (info at: #breakMode) equals: 'unhandled'
]

{ #category : 'tests - dap' }
PLSServerDebugTest >> testFrameOfADoItShowsItsSource [

	| adapter frame source |
	adapter := self attachTo: [ Smalltalk compiler evaluate: '1 / 0' ].
	frame := self frameOf: 'DoIt' in: adapter.
	self assert: ((frame at: #source) at: #path ifAbsent: [ nil ]) isNil.
	source := adapter
		          request: 'source'
		          arguments:
		          { (#sourceReference
		           -> ((frame at: #source) at: #sourceReference)) }.
	self assert:
		(((source at: #body) at: #content) includesSubstring: '1 / 0')
]

{ #category : 'tests - dap' }
PLSServerDebugTest >> testFrameOfAMethodOpensItsEditorOnTheExecutedNode [

	| probe adapter frame |
	probe := self newProbeClass.
	adapter := self attachTo: [ probe new divide ].
	frame := self frameOf: 'divide' in: adapter.
	self
		assert: ((frame at: #source) at: #path)
		equals: (server navUriOfMethod: probe >> #divide).
	self assert: (frame at: #line) equals: 2.
	self assert: (frame at: #column) equals: 4.
	self assert: (frame at: #endLine) equals: 2.
	self assert: (frame at: #endColumn) equals: 9
]

{ #category : 'tests' }
PLSServerDebugTest >> testHaltStopsForTheDebugger [

	| stopped |
	stopped := server
		           debugEvaluate: [
				           Halt now.
				           #after ]
		           ifStopped: [ :exception | exception ].
	self assert: (stopped isKindOf: Halt).
	self deny: self takeStoppedSession interruptedProcess isTerminated
]

{ #category : 'tests' }
PLSServerDebugTest >> testHandledErrorDoesNotStop [

	self
		assert: (server
				 debugEvaluate: [
						 [ 1 / 0 ]
							 on: ZeroDivide
							 do: [ #handled ] ]
				 ifStopped: [ #stopped ])
		equals: #handled.
	self assert: self stoppedNotifications isEmpty
]

{ #category : 'tests - dap' }
PLSServerDebugTest >> testInspectVariableRegistersItsObject [

	| probe adapter frame scope response |
	probe := self newProbeClass.
	adapter := self attachTo: [ probe new sum ].
	frame := self frameOf: 'sum' in: adapter.
	scope := (((adapter
		            request: 'scopes'
		            arguments: { (#frameId -> (frame at: #id)) }) at: #body)
		          at: #scopes) detect: [ :each |
		         (each at: #name) = 'Receiver' ].
	adapter
		request: 'variables'
		arguments:
		{ (#variablesReference -> (scope at: #variablesReference)) }.
	response := adapter request: 'pharoInspectVariable' arguments: {
			            (#variablesReference -> (scope at: #variablesReference)).
			            (#name -> 'count') }.
	self assert: (response at: #success).
	self
		assert: (server inspectorObjectOf: ((response at: #body) at: #ref))
		equals: 7.
	self deny: ((adapter request: 'pharoInspectVariable' arguments: {
				  (#variablesReference -> (scope at: #variablesReference)).
				  (#name -> 'nothing') }) at: #success)
]

{ #category : 'tests' }
PLSServerDebugTest >> testNotificationDescribesTheStoppedProcess [
	| params |
	server debugEvaluate: [ Object new foo: 1 ] ifStopped: [  ].
	params := (self stoppedNotifications first at: #params).
	sessions add: (server debugSessionAt: (params at: #id)).
	self assert: (params at: #exception) equals: 'MessageNotUnderstood'.
	self assert: (params at: #receiverClass) equals: 'Object'.
	self assert: (params at: #doesNotUnderstand).
	self deny: (params at: #subclassResponsibility).
	self assert: (params at: #frames) notEmpty
]

{ #category : 'tests' }
PLSServerDebugTest >> testPrintItOfAnErrorOpensTheDebugger [
	self
		should: [
			server
				commandPharoPrintIt: '1/0'
				textDocument: { (#path -> '/playground.st') } asDictionary ]
		raise: Error
		withExceptionDo: [ :error |
			self assert: (error messageText includesSubstring: 'opened in the debugger') ].
	self assert: (self takeStoppedSession exception isKindOf: ZeroDivide)
]

{ #category : 'tests - dap' }
PLSServerDebugTest >> testRestartFrameRunsTheSavedMethod [

	| probe adapter value frame |
	probe := self newProbeClass.
	adapter := self attachTo: [ value := probe new divide ].
	probe
		compile: 'divide
	^ 42'
		classified: 'probing'.
	frame := self frameOf: 'divide' in: adapter.
	self assert: ((adapter
			  request: 'restartFrame'
			  arguments: { (#frameId -> (frame at: #id)) }) at: #success).
	self
		assert: (((adapter events: 'stopped') last at: #body) at: #reason)
		equals: 'restart'.
	adapter request: 'continue' arguments: { (#threadId -> 1) }.
	self assert: (adapter events: 'terminated') size equals: 1.
	200 timesRepeat: [ value ifNil: [ 10 milliSeconds wait ] ].
	self assert: value equals: 42
]

{ #category : 'tests' }
PLSServerDebugTest >> testResumeContinuesAfterTheError [

	| value session |
	server debugEvaluate: [ value := 1 / 0 -> #after ] ifStopped: [ ].
	session := self takeStoppedSession.
	session resume.
	self waitForProcessOf: session.
	self assert: value equals: nil -> #after
]

{ #category : 'tests - dap' }
PLSServerDebugTest >> testScopesSeparateTheContextAndTheReceiver [

	| probe adapter frame context receiver |
	probe := self newProbeClass.
	adapter := self attachTo: [ probe new sum ].
	frame := self frameOf: 'sum' in: adapter.
	context := self variables: 'Context' of: frame in: adapter.
	self assert: ((context at: 'a') at: #value) equals: '3'.
	self assert: ((context at: 'b') at: #evaluateName) equals: 'b'.
	self assert: (context includesKey: 'thisContext').
	receiver := self variables: 'Receiver' of: frame in: adapter.
	self
		assert: ((receiver at: 'self') at: #value)
		equals: 'a PLSDebugProbe'.
	self assert: ((receiver at: 'count') at: #value) equals: '7'.
	self assert: ((receiver at: 'self') at: #variablesReference) > 0
]

{ #category : 'tests - dap' }
PLSServerDebugTest >> testStackTraceLoadsByPage [

	| adapter body |
	adapter := self attachTo: [ 1 / 0 ].
	body := (adapter request: 'stackTrace' arguments: {
			         (#threadId -> 1).
			         (#startFrame -> 1).
			         (#levels -> 2) }) at: #body.
	self assert: (body at: #stackFrames) size equals: 2.
	self assert: (body at: #totalFrames) > 2
]

{ #category : 'helpers' }
PLSServerDebugTest >> testURIOf: selector [

	^ {
		  (#path
		   -> ('/' , self probePackageName , '/PLSDebugProbeTest.class.st')).
		  (#fragment -> selector) } asDictionary
]

{ #category : 'tests' }
PLSServerDebugTest >> testUnhandledErrorStopsForTheDebugger [

	| stopped notification session |
	stopped := server
		           debugEvaluate: [ 1 / 0 ]
		           ifStopped: [ :exception | exception ].
	self assert: (stopped isKindOf: ZeroDivide).
	self assert: self stoppedNotifications size equals: 1.
	notification := self stoppedNotifications first at: #params.
	self assert: (notification at: #exception) equals: 'ZeroDivide'.
	session := self takeStoppedSession.
	self assert: session exception identicalTo: stopped.
	self assert: session interruptedContext selector equals: #/.
	self deny: session interruptedProcess isTerminated
]

{ #category : 'helpers' }
PLSServerDebugTest >> variables: scopeName of: frame in: adapter [
	"Answer the variables of a scope of a frame, by name"

	| scope |
	scope := (((adapter
		            request: 'scopes'
		            arguments: { (#frameId -> (frame at: #id)) }) at: #body)
		          at: #scopes) detect: [ :each |
		         (each at: #name) = scopeName ].
	^ ((((adapter
		      request: 'variables'
		      arguments:
		      { (#variablesReference -> (scope at: #variablesReference)) })
		     at: #body) at: #variables) collect: [ :variable |
		   (variable at: #name) -> variable ]) asDictionary
]

{ #category : 'helpers' }
PLSServerDebugTest >> waitForProcessOf: aDebugSession [
	"Let the process of aDebugSession run until it ends, for two seconds at most"

	| process |
	process := aDebugSession interruptedProcess.
	200 timesRepeat: [
			process isTerminated ifTrue: [ ^ self ].
			10 milliSeconds wait ]
]
