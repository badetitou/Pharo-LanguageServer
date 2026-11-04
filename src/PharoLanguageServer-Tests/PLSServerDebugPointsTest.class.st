"
I test the breakpoints of the client as debug points of the image (pls-debug:setBreakpoints, pls-debug:setFunctionBreakpoints, pls-debug:breakpoints) and the exception filters.
"
Class {
	#name : 'PLSServerDebugPointsTest',
	#superclass : 'TestCase',
	#instVars : [
		'server',
		'output',
		'sessions',
		'probe'
	],
	#category : 'PharoLanguageServer-Tests',
	#package : 'PharoLanguageServer-Tests'
}

{ #category : 'helpers' }
PLSServerDebugPointsTest >> breakpointAt: aLine [

	^ { (#line -> aLine) } asDictionary
]

{ #category : 'helpers' }
PLSServerDebugPointsTest >> entity [

	^ 'method:PLSDebugPointProbe>>sum:'
]

{ #category : 'helpers' }
PLSServerDebugPointsTest >> installedPointsOnProbe [

	^ DebugPoint all select: [ :each |
			  [ each nodes anyOne methodNode methodClass == probe ]
				  on: Error
				  do: [ false ] ]
]

{ #category : 'helpers' }
PLSServerDebugPointsTest >> lineOf: aDebugSession [
	"The line of the source of the method where aDebugSession stopped, as the debugger shows it"

	| context |
	context := aDebugSession interruptedContext.
	^ server
		  debugLineOf: (DAPServer new sourceNodeExecutedIn: context) start
		  in: context method sourceCode
]

{ #category : 'helpers' }
PLSServerDebugPointsTest >> probePackageName [

	^ 'PharoLanguageServer-DebugPointProbe'
]

{ #category : 'helpers' }
PLSServerDebugPointsTest >> resume: aSession [
	"Let the stopped process go on to its end"

	| process |
	process := aSession interruptedProcess.
	aSession resume.
	200 timesRepeat: [
			process isTerminated ifTrue: [ ^ self ].
			10 milliSeconds wait ]
]

{ #category : 'running' }
PLSServerDebugPointsTest >> setUp [

	super setUp.
	output := WriteStream on: ByteArray new.
	server := PLSServer new.
	server clientOutStream: output.
	sessions := OrderedCollection new.
	probe := ((Object << #PLSDebugPointProbe)
		          slots: { #count };
		          package: self probePackageName) install.
	probe
		compile: 'sum: aNumber
	| a b |
	a := 3.
	b := aNumber.

	count := a + b.
	^ count'
		classified: 'probing'
]

{ #category : 'helpers' }
PLSServerDebugPointsTest >> stoppedNotifications [

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
PLSServerDebugPointsTest >> sum [
	"Answer what the probe answers, or the exception it stopped on"

	^ server
		  debugEvaluate: [ probe new sum: 4 ]
		  ifStopped: [ :exception | exception ]
]

{ #category : 'helpers' }
PLSServerDebugPointsTest >> takeStoppedSession [

	| session |
	session := server debugSessionAt:
		           ((self stoppedNotifications last at: #params) at: #id).
	sessions add: session.
	^ session
]

{ #category : 'running' }
PLSServerDebugPointsTest >> tearDown [

	server debugPoints keys do: [ :each |
		server debugPointsAt: each put: #(  ) ].
	sessions do: [ :session | session terminate ].
	self stoppedNotifications do: [ :notification |
			[
				(server debugSessionAt: ((notification at: #params) at: #id))
					terminate ]
				on: PLSUnknownEntity
				do: [ ] ].
	probe removeFromSystem.
	self packageOrganizer removePackage: self probePackageName.
	super tearDown
]

{ #category : 'tests' }
PLSServerDebugPointsTest >> testBreakpointGoesOnWhenResumed [

	| session |
	server
		plsDebugSetBreakpoints: self entity
		breakpoints: { (self breakpointAt: 6) }.
	self sum.
	session := self takeStoppedSession.
	self resume: session.
	self assert: session interruptedProcess isTerminated
]

{ #category : 'tests' }
PLSServerDebugPointsTest >> testBreakpointMovesToTheNextStatement [

	| answers |
	answers := server plsDebugSetBreakpoints: self entity breakpoints: {
			           (self breakpointAt: 5).
			           (self breakpointAt: 2).
			           (self breakpointAt: 9) }.
	self
		assert:
		((answers first: 2) collect: [ :each | each at: #line ]) asArray
		equals: #( 6 3 ).
	self assert:
		((answers first: 2) allSatisfy: [ :each | each at: #verified ]).
	self deny: (answers last at: #verified).
	self assert: (answers last at: #message) notEmpty
]

{ #category : 'tests' }
PLSServerDebugPointsTest >> testBreakpointStopsInTheMethodOnItsLine [

	| stopped params session |
	server
		plsDebugSetBreakpoints: self entity
		breakpoints: { (self breakpointAt: 4) }.
	stopped := self sum.
	self assert: (stopped isKindOf: Break).
	params := self stoppedNotifications last at: #params.
	self assert: (params at: #breakpoint).
	session := self takeStoppedSession.
	self assert: session interruptedContext method equals: probe >> #sum:.
	self assert: (self lineOf: session) equals: 4
]

{ #category : 'tests' }
PLSServerDebugPointsTest >> testBreakpointsListsTheDebugPointsOfTheImage [

	| listed |
	server plsDebugSetBreakpoints: self entity breakpoints: { {
			(#line -> 6).
			(#condition -> 'b > 1') } asDictionary }.
	server plsDebugSetFunctionBreakpoints:
		{ { (#name -> 'PLSDebugPointProbe>>sum:') } asDictionary }.
	listed := server plsDebugBreakpoints select: [ :each |
		          (each at: #entity) = self entity ].
	self assert: listed size equals: 1.
	self assert: (listed first at: #line) equals: 6.
	self assert: (listed first at: #condition) equals: 'b > 1'.
	self assert: ((listed first at: #uri) urlDecoded endsWith:
			 '/PLSDebugPointProbe/instance/sum:.st')
]

{ #category : 'tests' }
PLSServerDebugPointsTest >> testCapabilitiesAnnounceBreakpointsAndFilters [

	| capabilities |
	capabilities := DAPCapabilities new asDAPJSON.
	#( #supportsConditionalBreakpoints #supportsHitConditionalBreakpoints
	   #supportsLogPoints #supportsFunctionBreakpoints
	   #supportsExceptionFilterOptions ) do: [ :each |
		self assert: (capabilities at: each) ].
	self
		assert:
			((capabilities at: #exceptionBreakpointFilters) collect: [ :each |
				 each at: #filter ]) asArray
		equals: #( 'error' 'messageNotUnderstood' 'halt' 'deprecation' )
]

{ #category : 'tests' }
PLSServerDebugPointsTest >> testDebuggerAttachesOnTheLineOfTheBreakpoint [

	| adapter stopped frame answer |
	server
		plsDebugSetBreakpoints: self entity
		breakpoints: { (self breakpointAt: 4) }.
	self sum.
	adapter := PLSDAPServerRecorder new
		           plsServer: server;
		           debugMode: false;
		           yourself.
	[
		self assert:
			((adapter request: 'attach' arguments: { (#debugSessionId
				   -> ((self stoppedNotifications last at: #params) at: #id)) })
				 at: #success).
		stopped := (adapter events: 'stopped') last at: #body.
		self assert: (stopped at: #reason) equals: 'breakpoint'.
		frame := (((adapter
			            request: 'stackTrace'
			            arguments: { (#threadId -> 1) }) at: #body) at:
			          #stackFrames) first.
		self assert: ((frame at: #name) endsWith: '>>sum:').
		self assert: (frame at: #line) equals: 4.
		answer := adapter request: 'setBreakpoints' arguments: {
				          (#source
				           ->
				           { (#path -> (server navUriOfMethod: probe >> #sum:)) }
					           asDictionary).
				          (#breakpoints -> { (self breakpointAt: 4) }) }.
		self assert:
			(((answer at: #body) at: #breakpoints) first at: #verified).
		adapter
			request: 'setExceptionBreakpoints'
			arguments: { (#filters -> #( 'messageNotUnderstood' )) }.
		self deny: (server debugShouldStopOn: ZeroDivide new) ] ensure: [
			adapter request: 'disconnect' arguments: {  }.
			Deprecation raiseWarning: false ]
]

{ #category : 'tests' }
PLSServerDebugPointsTest >> testDeprecationFilterRaisesDeprecations [

	[
		server debugExceptionFilters: #( 'deprecation' ) options: #(  ).
		self assert: Deprecation raiseWarning.
		self assert: (server debugShouldStopOn: Deprecation new) ] ensure: [
		Deprecation raiseWarning: false ]
]

{ #category : 'tests' }
PLSServerDebugPointsTest >> testExceptionFilters [

	self assert: (server debugShouldStopOn: ZeroDivide new).
	self assert: (server debugShouldStopOn: Halt new).
	self deny: (server debugShouldStopOn: Deprecation new).
	[
		server
			debugExceptionFilters: #( 'messageNotUnderstood' )
			options: #(  ).
		self assert: (server debugShouldStopOn: MessageNotUnderstood new).
		self deny: (server debugShouldStopOn: ZeroDivide new).
		self deny: (server debugShouldStopOn: Halt new).
		self assert: (server debugShouldStopOn: Break new).
		server debugExceptionFilters: #( 'halt' ) options: { {
				(#filterId -> 'error').
				(#condition -> 'ZeroDivide, KeyNotFound') } asDictionary }.
		self assert: (server debugShouldStopOn: ZeroDivide new).
		self assert: (server debugShouldStopOn: Halt new).
		self deny: (server debugShouldStopOn: MessageNotUnderstood new) ]
		ensure: [ Deprecation raiseWarning: false ]
]

{ #category : 'tests' }
PLSServerDebugPointsTest >> testFalseConditionDoesNotStop [

	server plsDebugSetBreakpoints: self entity breakpoints: { {
			(#line -> 6).
			(#condition -> 'b = 5') } asDictionary }.
	self assert: self sum equals: 7.
	self assert: self stoppedNotifications isEmpty
]

{ #category : 'tests' }
PLSServerDebugPointsTest >> testFrameOfABreakpointShowsItsLine [

	| frame |
	server
		plsDebugSetBreakpoints: self entity
		breakpoints: { (self breakpointAt: 4) }.
	self sum.
	frame := (DAPServer new plsServer: server) dapStackFrameOf:
		         self takeStoppedSession interruptedContext.
	self assert: frame line equals: 4.
	self assert: (frame source path urlDecoded endsWith:
			 '/PLSDebugPointProbe/instance/sum:.st')
]

{ #category : 'tests' }
PLSServerDebugPointsTest >> testFunctionBreakpointStopsOnTheFirstStatement [

	| answers session |
	answers := server plsDebugSetFunctionBreakpoints: {
			           { (#name -> 'PLSDebugPointProbe>>#sum:') } asDictionary.
			           { (#name -> 'PLSDebugPointProbe>>nope') } asDictionary }.
	self assert: (answers first at: #verified).
	self assert: (answers first at: #line) equals: 3.
	self deny: (answers last at: #verified).
	self assert: (self sum isKindOf: Break).
	session := self takeStoppedSession.
	self assert: (self lineOf: session) equals: 3
]

{ #category : 'tests' }
PLSServerDebugPointsTest >> testHitConditionStopsOnItsHit [

	server plsDebugSetBreakpoints: self entity breakpoints: { {
			(#line -> 6).
			(#hitCondition -> '2') } asDictionary }.
	self assert: self sum equals: 7.
	self assert: (self sum isKindOf: Break).
	self resume: self takeStoppedSession.
	self assert: self sum equals: 7
]

{ #category : 'tests' }
PLSServerDebugPointsTest >> testHitConditions [

	| behavior |
	behavior := PLSHitConditionBehavior new.
	self
		assert:
			((1 to: 6) select: [ :each |
				 (behavior condition: '3') accepts: each ]) asArray
		equals: #( 3 ).
	self
		assert: ((1 to: 6) select: [ :each |
				 (behavior condition: '>= 5') accepts: each ]) asArray
		equals: #( 5 6 ).
	self
		assert:
			((1 to: 6) select: [ :each |
				 (behavior condition: '<3') accepts: each ]) asArray
		equals: #( 1 2 ).
	self
		assert:
			((1 to: 6) select: [ :each |
				 (behavior condition: '%2') accepts: each ]) asArray
		equals: #( 2 4 6 ).
	self assert: ((1 to: 6) select: [ :each |
			 (behavior condition: 'often') accepts: each ]) isEmpty
]

{ #category : 'tests' }
PLSServerDebugPointsTest >> testLogMessageEvaluatesItsExpressionsInTheContext [

	| behavior text |
	behavior := PLSLogPointBehavior new message:
		            'a is {a + 1}, {nope zork} and {'.
	text := [ :a | behavior textIn: thisContext ] value: 2.
	self assert: (text beginsWith: 'a is 3, <').
	self assert: (text endsWith: '> and {')
]

{ #category : 'tests' }
PLSServerDebugPointsTest >> testLogPointDoesNotStop [

	| point |
	server plsDebugSetBreakpoints: self entity breakpoints: { {
			(#line -> 6).
			(#logMessage -> 'a is {a}, b is {b}') } asDictionary }.
	self assert: self sum equals: 7.
	self assert: self stoppedNotifications isEmpty.
	point := (server debugPoints at: self entity) first.
	self
		assert: (point getBehavior: PLSLogPointBehavior) message
		equals: 'a is {a}, b is {b}'
]

{ #category : 'tests' }
PLSServerDebugPointsTest >> testSettingBreakpointsReplacesTheOldOnes [

	server plsDebugSetBreakpoints: self entity breakpoints: {
			(self breakpointAt: 3).
			(self breakpointAt: 4) }.
	server
		plsDebugSetBreakpoints: self entity
		breakpoints: { (self breakpointAt: 6) }.
	self assert: (server debugPoints at: self entity) size equals: 1.
	self
		assert: (self installedPointsOnProbe collect: [ :each |
				 each nodes anyOne sourceCode ]) asArray
		equals: #( 'count := a + b' ).
	server plsDebugSetBreakpoints: self entity breakpoints: #(  ).
	self assert: self installedPointsOnProbe isEmpty.
	self deny: (server debugPoints includesKey: self entity)
]

{ #category : 'tests' }
PLSServerDebugPointsTest >> testStepOverFromABreakpointGoesToTheNextLine [

	| adapter lines |
	server
		plsDebugSetBreakpoints: self entity
		breakpoints: { (self breakpointAt: 4) }.
	self sum.
	adapter := PLSDAPServerRecorder new
		           plsServer: server;
		           debugMode: false;
		           yourself.
	[
		adapter request: 'attach' arguments: { (#debugSessionId
			 -> ((self stoppedNotifications last at: #params) at: #id)) }.
		lines := (1 to: 2) collect: [ :each |
				         | frame |
				         frame := (((adapter
					                     request: 'stackTrace'
					                     arguments: { (#threadId -> 1) }) at: #body)
					                   at: #stackFrames) first.
				         adapter request: 'next' arguments: { (#threadId -> 1) }.
				         frame at: #line ].
		self assert: lines asArray equals: #( 4 6 ) ] ensure: [
		adapter request: 'disconnect' arguments: {  } ]
]

{ #category : 'tests' }
PLSServerDebugPointsTest >> testTrueConditionStops [

	server plsDebugSetBreakpoints: self entity breakpoints: { {
			(#line -> 6).
			(#condition -> 'b = 4') } asDictionary }.
	self assert: (self sum isKindOf: Break)
]

{ #category : 'tests' }
PLSServerDebugPointsTest >> testUnknownMethodAnswersUnverifiedBreakpoints [

	| answers |
	answers := server
		           plsDebugSetBreakpoints:
		           'method:PLSDebugPointProbe>>noSuchMethod'
		           breakpoints: { (self breakpointAt: 2) }.
	self deny: (answers first at: #verified)
]

{ #category : 'tests' }
PLSServerDebugPointsTest >> testVerificationsOfAnEditor [

	| uri answers |
	server
		plsDebugSetBreakpoints: self entity
		breakpoints: { (self breakpointAt: 6) }.
	uri := server navUriOfMethod: probe >> #sum:.
	answers := server debugVerificationsAt: uri of: {
			           (self breakpointAt: 5).
			           (self breakpointAt: 3) }.
	self assert: (answers first at: #verified).
	self assert: (answers first at: #line) equals: 6.
	self deny: (answers last at: #verified)
]
