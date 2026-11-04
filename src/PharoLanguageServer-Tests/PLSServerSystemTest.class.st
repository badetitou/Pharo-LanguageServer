"
I test the pls-system requests of PLSServer (processes, stacks, terminate, debug, profile) and the pls-chest requests
"
Class {
	#name : 'PLSServerSystemTest',
	#superclass : 'TestCase',
	#instVars : [
		'server',
		'output',
		'processes'
	],
	#category : 'PharoLanguageServer-Tests',
	#package : 'PharoLanguageServer-Tests'
}

{ #category : 'helpers' }
PLSServerSystemTest >> itemOf: aProcess [

	^ (server systemProcesses at: #items)
		  detect: [ :each | (each at: #id) = aProcess identityHash ]
		  ifNone: [ nil ]
]

{ #category : 'helpers' }
PLSServerSystemTest >> newSleeper [
	"Answer a process waiting on a semaphore nobody signals, terminated by #tearDown"

	| semaphore process |
	semaphore := Semaphore new.
	process := [ semaphore wait ] forkNamed: 'PLS system test sleeper'.
	processes add: process.
	Processor yield.
	^ process
]

{ #category : 'running' }
PLSServerSystemTest >> setUp [

	super setUp.
	output := WriteStream on: ByteArray new.
	server := PLSServer new.
	server clientOutStream: output.
	processes := OrderedCollection new
]

{ #category : 'helpers' }
PLSServerSystemTest >> stoppedNotifications [

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

{ #category : 'running' }
PLSServerSystemTest >> tearDown [

	processes do: [ :each | each terminate ].
	self stoppedNotifications do: [ :notification |
			[
				(server debugSessionAt: ((notification at: #params) at: #id))
					terminate ]
				on: PLSUnknownEntity
				do: [ ] ].
	super tearDown
]

{ #category : 'tests' }
PLSServerSystemTest >> testCapabilityAnnouncesSystemTools [

	| capability |
	capability := PLSServerCapabilities forPharo experimental at:
		              #'pls-system'.
	self assert: (capability at: #version) equals: 1.
	self assert: (capability at: #processes).
	self assert: (capability at: #profile)
]

{ #category : 'tests' }
PLSServerSystemTest >> testChestListWithoutChest [

	| list |
	server chestClass ifNotNil: [ ^ self skip: 'Chest is loaded' ].
	list := server chestList.
	self deny: (list at: #available).
	self assert: (list at: #chests) isEmpty
]

{ #category : 'tests' }
PLSServerSystemTest >> testDebugGivesTheProcessToADebuggerAtOnce [

	| process answer notification |
	process := self newSleeper.
	answer := server systemDebug: process identityHash.
	self assert: process isSuspended.
	notification := self stoppedNotifications last at: #params.
	self
		assert: (notification at: #id)
		equals: (answer at: #debugSessionId).
	self assert: (notification at: #breakpoint)
]

{ #category : 'tests' }
PLSServerSystemTest >> testProcessesDescribeAWaitingProcess [
	"Semaphore>>wait is a primitive: the process waits in the block that sent it"

	| process item |
	process := self newSleeper.
	item := self itemOf: process.
	self assert: (item at: #name) equals: 'PLS system test sleeper'.
	self assert: (item at: #priority) equals: process priority.
	self assert: (item at: #state) equals: 'waiting'.
	self
		assert: (item at: #method)
		equals: '[] in PLSServerSystemTest>>newSleeper'.
	self assert: (item at: #uri) isNotNil.
	self deny: (item at: #current)
]

{ #category : 'tests' }
PLSServerSystemTest >> testProcessesLeaveOutTerminatedProcesses [

	| process |
	process := self newSleeper.
	process terminate.
	self assert: (self itemOf: process) isNil
]

{ #category : 'tests' }
PLSServerSystemTest >> testProcessesMarkTheCurrentProcess [

	| item |
	item := self itemOf: Processor activeProcess.
	self assert: (item at: #current).
	self assert: (item at: #state) equals: 'running'
]

{ #category : 'tests' }
PLSServerSystemTest >> testProfileAnswersTheTreeOfTheCalls [

	| profile root |
	profile := server
		           systemProfile:
		           '30 timesRepeat: [ (1 to: 20000) asArray reverse sort ]'
		           textDocumentURI: nil.
	self assert: (profile at: #error) isNil.
	self assert: (profile at: #milliseconds) >= 0.
	root := profile at: #root.
	self
		assert: (root at: #label)
		equals: '30 timesRepeat: [ (1 to: 20000) asArray reverse sort ]'.
	self assert: (root at: #samples) equals: (profile at: #samples).
	(root at: #children) do: [ :child |
			self assert: (child at: #samples) <= (root at: #samples).
			self assert: (child at: #selfSamples) <= (child at: #samples) ]
]

{ #category : 'tests' }
PLSServerSystemTest >> testProfileRefusesASyntaxError [

	self
		should: [ server systemProfile: '1 +' textDocumentURI: nil ]
		raise: JRPCInvalidParameters
]

{ #category : 'tests' }
PLSServerSystemTest >> testProfileReportsTheError [

	| profile |
	profile := server systemProfile: '1/0' textDocumentURI: nil.
	self assert: ((profile at: #error) includesSubstring: 'ZeroDivide')
]

{ #category : 'tests' }
PLSServerSystemTest >> testStackAnswersTheFramesOfAProcess [

	| frames |
	frames := (server systemStack: self newSleeper identityHash limit: 2)
		          at: #items.
	self assert: frames size equals: 2.
	self
		assert: (frames first at: #label)
		equals: '[] in PLSServerSystemTest>>newSleeper'.
	self assert: (frames first at: #uri) isNotNil
]

{ #category : 'tests' }
PLSServerSystemTest >> testTerminateRefusesTheProcessThatAnswers [

	self
		should: [
		server systemTerminate: Processor activeProcess identityHash ]
		raise: JRPCInvalidParameters
]

{ #category : 'tests' }
PLSServerSystemTest >> testTerminateTerminatesTheProcess [

	| process |
	process := self newSleeper.
	server systemTerminate: process identityHash.
	self assert: process isTerminated
]

{ #category : 'tests' }
PLSServerSystemTest >> testUnknownProcess [

	| process |
	process := self newSleeper.
	process terminate.
	self
		should: [ server systemStack: process identityHash limit: nil ]
		raise: PLSUnknownEntity
]
