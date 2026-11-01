Class {
	#name : 'PLSServerEnvironmentHistoryTest',
	#superclass : 'TestCase',
	#instVars : [
		'server',
		'previousLostChanges'
	],
	#category : 'PharoLanguageServer-Tests',
	#package : 'PharoLanguageServer-Tests'
}

{ #category : 'helpers' }
PLSServerEnvironmentHistoryTest >> loseChanges: events [
	"Pretend that the last session of the image ended without saving events"

	PLSLostChanges current: (PLSLostChanges withEntries:
			 (events collect: [ :event | OmEntry content: event ]))
]

{ #category : 'helpers' }
PLSServerEnvironmentHistoryTest >> lostChanges [

	^ server envLostChanges at: #items
]

{ #category : 'helpers' }
PLSServerEnvironmentHistoryTest >> newProbeClass [

	^ (Object << #PLSEnvironmentHistoryProbeClass)
		  package: self probePackageName;
		  install
]

{ #category : 'helpers' }
PLSServerEnvironmentHistoryTest >> probePackageName [

	^ 'PLSEnvironmentHistoryProbe'
]

{ #category : 'running' }
PLSServerEnvironmentHistoryTest >> setUp [

	super setUp.
	server := PLSServer new.
	previousLostChanges := PLSLostChanges current
]

{ #category : 'running' }
PLSServerEnvironmentHistoryTest >> tearDown [

	PLSLostChanges current: previousLostChanges.
	self packageOrganizer
		packageNamed: self probePackageName
		ifPresent: [ :package | package removeFromSystem ].
	super tearDown
]

{ #category : 'tests' }
PLSServerEnvironmentHistoryTest >> testCapabilitiesAnnounceTheHistory [

	self assert:
		((PLSServerCapabilities forPharo experimental at: #'pls-env') at:
			 #history)
]

{ #category : 'tests' }
PLSServerEnvironmentHistoryTest >> testDismissedChangesAreNoLongerPending [

	| class |
	class := self newProbeClass.
	class compile: 'answer ^ 1' classified: 'accessing'.
	self loseChanges: {
			(EpMethodAddition method: class >> #answer).
			(EpMethodRemoval method: class >> #answer) }.
	server envDismissLostChanges: #( '1' ).
	self
		assert:
		(self lostChanges collect: [ :change | change at: #ref ]) asArray
		equals: #( '2' )
]

{ #category : 'tests' }
PLSServerEnvironmentHistoryTest >> testFailedReplayStaysPending [

	| class method result |
	class := self newProbeClass.
	class compile: 'answer ^ 1' classified: 'accessing'.
	method := class >> #answer.
	self loseChanges: { (EpMethodRemoval method: method) }.
	class removeSelector: #answer.
	class removeFromSystem.
	result := server envReplayLostChanges: #( '1' ).
	self assert: (result at: #replayed) isEmpty.
	self
		assert:
			((result at: #failures) collect: [ :failure | failure at: #ref ])
				asArray
		equals: #( '1' ).
	self assert: self lostChanges size equals: 1
]

{ #category : 'tests' }
PLSServerEnvironmentHistoryTest >> testHistoryOfAClassIsRejected [

	self newProbeClass.
	self
		should: [
		server envHistory: 'class:PLSEnvironmentHistoryProbeClass' ]
		raise: PLSUnknownEntity
]

{ #category : 'tests' }
PLSServerEnvironmentHistoryTest >> testHistoryStartsWithTheCurrentVersion [

	| class items |
	class := self newProbeClass.
	class compile: 'answer ^ 1' classified: 'accessing'.
	class compile: 'answer ^ 2' classified: 'accessing'.
	items := (server envHistory:
		          'method:PLSEnvironmentHistoryProbeClass>>answer') at:
		         #items.
	self
		assert: (items collect: [ :item | item at: #source ]) asArray
		equals: #( 'answer ^ 2' 'answer ^ 1' ).
	self assert: (items first at: #protocol) equals: 'accessing'.
	self assert: (items first at: #stamp) notNil
]

{ #category : 'tests' }
PLSServerEnvironmentHistoryTest >> testLostChangesGiveTheSourcesBeforeAndAfter [

	| class old change |
	class := self newProbeClass.
	class compile: 'answer ^ 1' classified: 'accessing'.
	old := class >> #answer.
	class compile: 'answer ^ 2' classified: 'accessing'.
	self loseChanges: {
			(EpMethodModification oldMethod: old newMethod: class >> #answer).
			(EpMethodRemoval method: class >> #answer) }.
	change := self lostChanges first.
	self assert: (change at: #ref) equals: '1'.
	self assert: (change at: #kind) equals: 'methodModification'.
	self
		assert: (change at: #id)
		equals: 'method:PLSEnvironmentHistoryProbeClass>>answer'.
	self
		assert: (change at: #label)
		equals: 'PLSEnvironmentHistoryProbeClass>>answer'.
	self assert: (change at: #oldSource) equals: 'answer ^ 1'.
	self assert: (change at: #source) equals: 'answer ^ 2'.
	change := self lostChanges second.
	self assert: (change at: #kind) equals: 'methodRemoval'.
	self assert: (change at: #oldSource) equals: 'answer ^ 2'.
	self assert: (change at: #source) isNil
]

{ #category : 'tests' }
PLSServerEnvironmentHistoryTest >> testOnlyCodeChangesAreKept [

	self loseChanges: { EpSessionStart new }.
	self assert: self lostChanges isEmpty
]

{ #category : 'tests' }
PLSServerEnvironmentHistoryTest >> testReplayAppliesTheChangesThenForgetsThem [

	| class old new result |
	class := self newProbeClass.
	class compile: 'answer ^ 1' classified: 'accessing'.
	old := class >> #answer.
	class compile: 'answer ^ 2' classified: 'accessing'.
	new := class >> #answer.
	class compile: 'answer ^ 1' classified: 'accessing'.
	self loseChanges:
		{ (EpMethodModification oldMethod: old newMethod: new) }.
	result := server envReplayLostChanges: #( '1' ).
	self assert: (result at: #replayed) equals: #( '1' ).
	self assert: (result at: #failures) isEmpty.
	self assert: (class >> #answer) sourceCode equals: 'answer ^ 2'.
	self assert: self lostChanges isEmpty
]
