"
I test the pls-env/didChange notifications of PLSServer: the subscription to the system announcements, the grouping of changes and the unsubscription.
I change classes of a probe package that I remove after each test.
"
Class {
	#name : 'PLSServerEnvironmentChangesTest',
	#superclass : 'TestCase',
	#instVars : [
		'server',
		'output'
	],
	#category : 'PharoLanguageServer-Tests',
	#package : 'PharoLanguageServer-Tests'
}

{ #category : 'running' }
PLSServerEnvironmentChangesTest >> changeOf: kind id: id [

	^ self changes
		  detect: [ :change |
		  (change at: #kind) = kind and: [ (change at: #id) = id ] ]
		  ifNone: [ nil ]
]

{ #category : 'running' }
PLSServerEnvironmentChangesTest >> changes [
	"Answer the changes of the pls-env/didChange notifications sent to the client"

	^ self notifications flatCollect: [ :notification |
		  notification at: #params at: #changes ]
]

{ #category : 'running' }
PLSServerEnvironmentChangesTest >> newProbeClass [

	^ (Object << #PLSEnvironmentChangesProbeClass)
		  package: self probePackageName;
		  install
]

{ #category : 'running' }
PLSServerEnvironmentChangesTest >> notifications [

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
		  (notification at: #method) = 'pls-env/didChange' ]
]

{ #category : 'running' }
PLSServerEnvironmentChangesTest >> probePackageName [

	^ 'PLSEnvironmentChangesProbe'
]

{ #category : 'running' }
PLSServerEnvironmentChangesTest >> setUp [

	super setUp.
	output := WriteStream on: ByteArray new.
	server := PLSServer new.
	server clientOutStream: output
]

{ #category : 'running' }
PLSServerEnvironmentChangesTest >> tearDown [

	server envUnsubscribe.
	self packageOrganizer
		packageNamed: self probePackageName
		ifPresent: [ :package | package removeFromSystem ].
	super tearDown
]

{ #category : 'tests' }
PLSServerEnvironmentChangesTest >> testCapabilitiesAnnounceTheNotification [

	| experimental |
	experimental := (PLSInitializeResult new asJRPCJSON at: #capabilities)
		                at: #experimental.
	self assert: ((experimental at: #'pls-env') at: #didChange)
]

{ #category : 'tests' }
PLSServerEnvironmentChangesTest >> testChangesAreSentOnceTheSystemIsQuiet [

	server envSubscribe.
	self newProbeClass.
	self assert: self notifications isEmpty.
	(Delay forMilliseconds: server envQuietDelay * 4) wait.
	self assert: self notifications size equals: 1.
	self assert:
		(self changeOf: 'added' id: 'class:PLSEnvironmentChangesProbeClass')
			notNil
]

{ #category : 'tests' }
PLSServerEnvironmentChangesTest >> testChangesOfOneEntityAreGrouped [

	| class versions |
	class := self newProbeClass.
	server envSubscribe.
	versions := (1 to: 3) collect: [ :each |
			            class
				            compile: 'answer ^ ' , each printString
				            classified: 'accessing'.
			            (server envEntity:
				             'method:PLSEnvironmentChangesProbeClass>>answer')
				            at: #version ].
	server envFlushChanges.
	self assert: self notifications size equals: 1.
	self
		assert:
			(self changes select: [ :change | (change at: #kind) = 'changed' ])
				size
		equals: 1.
	self
		assert: ((self
				  changeOf: 'changed'
				  id: 'method:PLSEnvironmentChangesProbeClass>>answer') at:
				 #version)
		equals: versions last
]

{ #category : 'tests' }
PLSServerEnvironmentChangesTest >> testCompiledMethodIsNotifiedWithItsVersion [

	| class change |
	server envSubscribe.
	class := self newProbeClass.
	class compile: 'answer ^ 42' classified: 'accessing'.
	server envFlushChanges.
	change := self
		          changeOf: 'added'
		          id: 'method:PLSEnvironmentChangesProbeClass>>answer'.
	self assert: change notNil.
	self
		assert: (change at: #parent)
		equals: 'protocol:PLSEnvironmentChangesProbeClass>>accessing'.
	self
		assert: (change at: #version)
		equals:
			((server envEntity:
				  'method:PLSEnvironmentChangesProbeClass>>answer') at: #version).
	self assert:
		(self changeOf: 'added' id: 'class:PLSEnvironmentChangesProbeClass')
			notNil.
	self assert:
		(self changeOf: 'added' id: 'package:' , self probePackageName)
			notNil
]

{ #category : 'tests' }
PLSServerEnvironmentChangesTest >> testFailingChangeIsIgnored [

	server envSubscribe.
	self shouldnt: [ server envRecord: [ 1 / 0 ] ] raise: Error.
	server envFlushChanges.
	self assert: self notifications isEmpty
]

{ #category : 'tests' }
PLSServerEnvironmentChangesTest >> testInitializedSubscribesAndStopUnsubscribes [

	server serverInitialized.
	self assert: server isSubscribedToEnvironmentChanges.
	server stop.
	self deny: server isSubscribedToEnvironmentChanges
]

{ #category : 'tests' }
PLSServerEnvironmentChangesTest >> testNothingIsSentWithoutSubscription [

	self newProbeClass.
	server envFlushChanges.
	(Delay forMilliseconds: server envQuietDelay * 2) wait.
	self assert: self notifications isEmpty
]

{ #category : 'tests' }
PLSServerEnvironmentChangesTest >> testRecategorizedMethodIsMoved [

	| class change |
	class := self newProbeClass.
	class compile: 'answer ^ 42' classified: 'accessing'.
	server envSubscribe.
	class classify: #answer under: 'constants'.
	server envFlushChanges.
	change := self
		          changeOf: 'moved'
		          id: 'method:PLSEnvironmentChangesProbeClass>>answer'.
	self
		assert: (change at: #parent)
		equals: 'protocol:PLSEnvironmentChangesProbeClass>>constants'.
	self
		assert: (change at: #oldParent)
		equals: 'protocol:PLSEnvironmentChangesProbeClass>>accessing'
]

{ #category : 'tests' }
PLSServerEnvironmentChangesTest >> testRemovedClassKeepsItsName [

	| class |
	class := self newProbeClass.
	server envSubscribe.
	class removeFromSystem.
	server envFlushChanges.
	self
		assert:
			((self
				  changeOf: 'removed'
				  id: 'class:PLSEnvironmentChangesProbeClass') at: #parent)
		equals: 'package:' , self probePackageName
]

{ #category : 'tests' }
PLSServerEnvironmentChangesTest >> testRenamedClassGivesItsOldId [

	| class |
	class := self newProbeClass.
	server envSubscribe.
	class rename: #PLSEnvironmentChangesProbeRenamed.
	server envFlushChanges.
	self
		assert: ((self
				  changeOf: 'renamed'
				  id: 'class:PLSEnvironmentChangesProbeRenamed') at: #oldId)
		equals: 'class:PLSEnvironmentChangesProbeClass'
]

{ #category : 'tests' }
PLSServerEnvironmentChangesTest >> testTooManyChangesAreSentAsOneReset [

	server envSubscribe.
	1 to: server envMaxChanges + 1 do: [ :index |
			server envRecord: [
				server
					envChange: 'changed'
					id: 'method:Fake>>m' , index printString ] ].
	server envFlushChanges.
	self assert: self notifications size equals: 1.
	self assert: (self notifications first at: #params at: #reset).
	self assert: self changes isEmpty
]

{ #category : 'tests' }
PLSServerEnvironmentChangesTest >> testUnsubscribeStopsListening [

	| subscribers |
	subscribers := [
		               (SystemAnnouncer uniqueInstance subscriptions
			                subscriptions select: [ :subscription |
			                subscription subscriber == server ]) size ].
	server envSubscribe.
	self
		assert: subscribers value
		equals: server envAnnouncementSelectors size.
	server envUnsubscribe.
	self assert: subscribers value equals: 0.
	self deny: server isSubscribedToEnvironmentChanges.
	self newProbeClass.
	server envFlushChanges.
	self assert: self notifications isEmpty
]
