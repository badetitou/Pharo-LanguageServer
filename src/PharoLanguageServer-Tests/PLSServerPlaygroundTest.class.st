"
I test the requests and notifications of PLSServer that the playground of the client uses: the bindings of a page and the Transcript.
"
Class {
	#name : 'PLSServerPlaygroundTest',
	#superclass : 'TestCase',
	#instVars : [
		'server',
		'output'
	],
	#category : 'PharoLanguageServer-Tests',
	#package : 'PharoLanguageServer-Tests'
}

{ #category : 'running' }
PLSServerPlaygroundTest >> notifications [

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
		  (notification at: #method) = 'pls/transcript' ]
]

{ #category : 'running' }
PLSServerPlaygroundTest >> page [

	^ { (#uri -> { (#path -> '/image/Page 1.st') } asDictionary) }
		  asDictionary
]

{ #category : 'running' }
PLSServerPlaygroundTest >> setUp [

	super setUp.
	output := WriteStream on: ByteArray new.
	server := PLSServer new.
	server clientOutStream: output
]

{ #category : 'running' }
PLSServerPlaygroundTest >> tearDown [

	server transcriptUnsubscribe.
	super tearDown
]

{ #category : 'tests' }
PLSServerPlaygroundTest >> testBindingsSurviveBetweenEvaluations [

	server
		commandPharoPrintIt: 'x := 3'
		textDocument: (self page at: #uri).
	self
		assert: (server
				 commandPharoPrintIt: 'x + 1'
				 textDocument: (self page at: #uri))
		equals: '4'
]

{ #category : 'tests' }
PLSServerPlaygroundTest >> testCapabilitiesAnnounceThePlayground [

	self assert:
		((PLSServerCapabilities forPharo experimental at: #'pls-playground')
			 at: #transcript)
]

{ #category : 'tests' }
PLSServerPlaygroundTest >> testInspectItBindsTheResultToIt [

	self
		assert:
		(server inspectIt: '3 + 4' textDocument: (self page at: #uri))
		equals: '7'.
	self
		assert: (server
				 commandPharoPrintIt: 'it * 2'
				 textDocument: (self page at: #uri))
		equals: '14'
]

{ #category : 'tests' }
PLSServerPlaygroundTest >> testResetBindingsForgetsTheVariablesOfThePage [

	server
		commandPharoPrintIt: 'x := 3'
		textDocument: (self page at: #uri).
	server resetBindings: self page.
	self assert: (server documentVariables: self page) isEmpty
]

{ #category : 'tests' }
PLSServerPlaygroundTest >> testTranscriptEntryIsNotified [

	server transcriptSubscribe.
	SystemAnnouncer uniqueInstance announce: (NewEntryToTranscript new
			 entry: 'hello';
			 yourself).
	self
		assert:
			(self notifications collect: [ :each | each at: #params at: #text ])
				asArray
		equals: #( 'hello' )
]

{ #category : 'tests' }
PLSServerPlaygroundTest >> testUnsubscribeStopsTheTranscript [

	server transcriptSubscribe.
	server transcriptUnsubscribe.
	SystemAnnouncer uniqueInstance announce: (NewEntryToTranscript new
			 entry: 'hello';
			 yourself).
	self assert: self notifications isEmpty
]
