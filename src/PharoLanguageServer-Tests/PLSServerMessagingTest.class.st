"
I test how PLSServer writes messages to the client.
"
Class {
	#name : 'PLSServerMessagingTest',
	#superclass : 'TestCase',
	#instVars : [
		'server',
		'output'
	],
	#category : 'PharoLanguageServer-Tests',
	#package : 'PharoLanguageServer-Tests'
}

{ #category : 'running - additional setup' }
PLSServerMessagingTest >> beInPushDiagnosticsMode [

	server context clientContext capabilities textDocument:
		PLSTextDocumentClientCapabilities new
]

{ #category : 'helpers' }
PLSServerMessagingTest >> messages [
	"Answer the JSON objects written to the client, checking their framing"

	| stream messages |
	stream := ReadStream on: output contents.
	messages := OrderedCollection new.
	[ stream atEnd ] whileFalse: [
		| headers length |
		headers := (stream upToAll: #[ 13 10 13 10 ]) asString.
		length := (headers lines detect: [ :line |
			           line beginsWith: 'Content-Length: ' ]) allButFirst: 16.
		messages add: (STONJSON fromString: (stream next: length asInteger) utf8Decoded) ].
	^ messages
]

{ #category : 'running - additional setup' }
PLSServerMessagingTest >> scriptDocument: aString [

	^ Dictionary new
		  at: #uri put: 'src/myScript.st';
		  at: #version put: 1;
		  at: #languageId put: 'pharo';
		  at: #text put: aString;
		  yourself
]

{ #category : 'running' }
PLSServerMessagingTest >> setUp [

	super setUp.
	output := WriteStream on: ByteArray new.
	server := PLSServer new.
	server debugMode: true.
	server clientOutStream: output.
	server context clientContext: (PLPInitializeParams new
			 capabilities: (PLPClientCapabilities from: {  } asDictionary);
			 yourself)
]

{ #category : 'tests' }
PLSServerMessagingTest >> testConcurrentMessagesAreNotInterleaved [

	| done |
	output := PLSInterleavingWriteStream on: ByteArray new.
	server clientOutStream: output.
	done := Semaphore new.
	1 to: 5 do: [ :index |
		[
		server
			sendNotification: 'pls/test'
			params: { (#index -> index). (#text -> (String new: 200 withAll: $a)) } asDictionary.
		done signal ] forkAt: Processor activePriority ].
	5 timesRepeat: [ done waitTimeoutMilliseconds: 5000 ].

	self
		assert: (self messages collect: [ :message | (message at: #params) at: #index ]) asSet
		equals: (1 to: 5) asSet
]

{ #category : 'tests' }
PLSServerMessagingTest >> testDidChangeOnUnknownDocumentPublishesDiagnosticsOnce [

	self beInPushDiagnosticsMode.

	server
		didChange: (self scriptDocument: '1 + 1')
		contentChanges: { (Dictionary with: #text -> '1 + 2') }.

	self assert: self messages size equals: 1.
	self assert: (self messages first at: #method) equals: 'textDocument/publishDiagnostics'
]

{ #category : 'tests' }
PLSServerMessagingTest >> testDidCloseSendsEmptyDiagnostics [

	| message |
	server didOpen: (self scriptDocument: '1 + 1').

	server didClose: (self scriptDocument: '1 + 1').

	message := self messages last.
	self assert: (message at: #method) equals: 'textDocument/publishDiagnostics'.
	self assert: ((message at: #params) at: #uri) equals: 'src/myScript.st'.
	self assertEmpty: ((message at: #params) at: #diagnostics)
]

{ #category : 'tests' }
PLSServerMessagingTest >> testDidOpenInPullDiagnosticsModeSendsNothing [

	server didOpen: (self scriptDocument: '1 + 1').

	self assertEmpty: self messages
]

{ #category : 'tests' }
PLSServerMessagingTest >> testDidOpenInPushDiagnosticsModePublishesDiagnosticsParams [

	| params |
	self beInPushDiagnosticsMode.

	server didOpen: (self scriptDocument: '1 + 1').

	self assert: self messages size equals: 1.
	params := self messages first at: #params.
	self assert: (params at: #uri) equals: 'src/myScript.st'.
	self assert: (params at: #diagnostics) isCollection
]

{ #category : 'tests' }
PLSServerMessagingTest >> testSendNotificationWritesOneFramedMessage [

	| message |
	server sendNotification: 'pls/test' params: { (#value -> 'é') } asDictionary.

	self assert: self messages size equals: 1.
	message := self messages first.
	self assert: (message at: #method) equals: 'pls/test'.
	self assert: ((message at: #params) at: #value) equals: 'é'.
	self deny: (message includesKey: #id)
]

{ #category : 'tests' }
PLSServerMessagingTest >> testSendRequestUsesANewIdEachTime [

	| firstId secondId |
	firstId := server sendRequest: 'window/showDocument' params: Dictionary new.
	secondId := server sendRequest: 'window/showDocument' params: Dictionary new.

	self deny: firstId equals: secondId.
	self
		assert: (self messages collect: [ :message | message at: #id ]) asArray
		equals: { firstId. secondId }
]
