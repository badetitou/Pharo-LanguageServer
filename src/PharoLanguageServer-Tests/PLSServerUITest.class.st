"
I test how the language server shows the tools and the questions of the image in the client (protocol pls - ui of PLSServer, PLSUIManager, PLSClientTool): the requests sent to the client, and the answers of the client the waiting processes get.
"
Class {
	#name : 'PLSServerUITest',
	#superclass : 'TestCase',
	#instVars : [
		'server',
		'output'
	],
	#category : 'PharoLanguageServer-Tests',
	#package : 'PharoLanguageServer-Tests'
}

{ #category : 'helpers' }
PLSServerUITest >> answer: aBlock with: aResultJSON [
	"Run aBlock in another process, answer the request it sends to the client with aResultJSON, and answer {request. value of aBlock}"

	| done value request |
	done := Semaphore new.
	[
		value := aBlock value.
		done signal ] forkAt: Processor activePriority - 1.
	request := self waitForRequest.
	self assert: (server handleClientResponse: (server parseJSON:
				  '{"jsonrpc":"2.0","id":' , (request at: 'id') printString , ','
				  , aResultJSON , '}')).
	self assert: (done waitTimeoutMilliseconds: 2000) not.
	^ {
		  request.
		  value }
]

{ #category : 'helpers' }
PLSServerUITest >> manager [

	^ PLSUIManager new
		  plsServer: server;
		  yourself
]

{ #category : 'helpers' }
PLSServerUITest >> messages [
	"The JSON objects written to the client"

	| stream messages |
	stream := ReadStream on: output contents.
	messages := OrderedCollection new.
	[ stream atEnd ] whileFalse: [
			| headers length |
			headers := (stream upToAll: #[ 13 10 13 10 ]) asString.
			length := (headers lines detect: [ :line |
				           line beginsWith: 'Content-Length: ' ]) allButFirst: 16.
			messages add:
				(STONJSON fromString: (stream next: length asInteger) utf8Decoded) ].
	^ messages
]

{ #category : 'running' }
PLSServerUITest >> setUp [

	super setUp.
	output := WriteStream on: ByteArray new.
	server := PLSServer new.
	server debugMode: false.
	server clientOutStream: output.
	server instVarNamed: #uiEnabled put: true
]

{ #category : 'running' }
PLSServerUITest >> tearDown [

	server cancelPendingClientRequests.
	server uiStop.
	super tearDown
]

{ #category : 'tests' }
PLSServerUITest >> testAResponseNobodyWaitsForIsNotHandled [

	self deny: (server handleClientResponse:
			 (server parseJSON: '{"jsonrpc":"2.0","id":999,"result":null}'))
]

{ #category : 'tests' }
PLSServerUITest >> testBrowserToolShowsTheEditorOfTheMethod [

	| message |
	(PLSBrowserTool on: server replacing: nil) openOnMethod:
		Object >> #printString.
	message := self messages last.
	self assert: (message at: 'method') equals: 'window/showDocument'.
	self
		assert: ((message at: 'params') at: 'uri')
		equals: (server navUriOfMethod: Object >> #printString)
]

{ #category : 'tests' }
PLSServerUITest >> testChooseFromAnswersTheValueOfTheChosenItem [

	| exchange |
	exchange := self
		            answer: [
				            self manager
					            chooseFrom: #( 'one' 'two' )
					            values: #( 1 2 )
					            title: 'Pick' ]
		            with: '"result":{"index":1}'.
	self assert: (exchange first at: 'method') equals: 'pls-ui/choose'.
	self
		assert: ((exchange first at: 'params') at: 'items')
		equals: #( 'one' 'two' ).
	self assert: exchange second equals: 2
]

{ #category : 'tests' }
PLSServerUITest >> testChooseOrRequestAnswersTheTypedText [

	| exchange |
	exchange := self
		            answer: [
		            self manager
			            chooseOrRequestFrom: #( 'one' )
			            title: 'Pick' ]
		            with: '"result":{"text":"other"}'.
	self assert: exchange second equals: 'other'
]

{ #category : 'tests' }
PLSServerUITest >> testClientToolsAreInstalledAndRestored [

	| original |
	original := Smalltalk tools toolNamed: #inspector.
	[
		server uiInstallTools.
		self assert:
			((Smalltalk tools toolNamed: #inspector) isKindOf: PLSInspectorTool).
		self
			assert: (Smalltalk tools toolNamed: #inspector) originalTool
			identicalTo: original ] ensure: [ server uiRestoreTools ].
	self
		assert: (Smalltalk tools toolNamed: #inspector)
		identicalTo: original
]

{ #category : 'tests' }
PLSServerUITest >> testConfirmAsksTheClient [

	| exchange |
	exchange := self
		            answer: [ self manager confirm: 'Sure?' ]
		            with: '"result":true'.
	self assert: (exchange first at: 'method') equals: 'pls-ui/confirm'.
	self
		assert: ((exchange first at: 'params') at: 'message')
		equals: 'Sure?'.
	self assert: exchange second
]

{ #category : 'tests' }
PLSServerUITest >> testConfirmOrCancelRunsTheCancelBlockWhenDismissed [

	| exchange |
	exchange := self
		            answer: [
		            self manager confirm: 'Sure?' orCancel: [ #cancelled ] ]
		            with: '"result":null'.
	self assert: exchange second equals: #cancelled
]

{ #category : 'tests' }
PLSServerUITest >> testInspectorToolOpensTheInspectorOfTheClient [

	| message |
	(PLSInspectorTool on: server replacing: nil) inspect: #( 1 2 3 ).
	message := self messages last.
	self assert: (message at: 'method') equals: 'pls-ui/inspect'.
	self
		assert:
		((server instVarNamed: #inspectorObjects) at: ((message at: 'params') at: 'ref'))
		equals: #( 1 2 3 )
]

{ #category : 'tests' }
PLSServerUITest >> testJobProgressIsReportedToTheClient [

	| exchange values |
	server uiStartProgress.
	exchange := self
		            answer: [
			            [ :job |
			            job title: 'Working'.
			            job currentValue: 50 ] asJob
				            min: 0;
				            max: 100;
				            run ]
		            with: '"result":null'.
	self assert: (exchange first at: 'method') equals: 'window/workDoneProgress/create'.
	values := (self messages select: [ :each |
		           (each at: 'method' ifAbsent: [ nil ]) = '$/progress' ]) collect: [ :each |
		          (each at: 'params') at: 'value' ].
	self assert: (values first at: 'kind') equals: 'begin'.
	self assert: (values last at: 'kind') equals: 'end'.
	self assert: (values anySatisfy: [ :each |
			 (each at: 'kind') = 'report' and: [ (each at: 'percentage') = 50 ] ])
]

{ #category : 'tests' }
PLSServerUITest >> testProvidedAnswersAreNotAskedToTheClient [

	| answer |
	answer := [ self manager confirm: 'Sure?' ]
		          on: ProvideAnswerNotification
		          do: [ :notification | notification resume: false ].
	self deny: answer.
	self assertEmpty: self messages
]

{ #category : 'tests' }
PLSServerUITest >> testQuestionsStayInPharoWhenTheClientDidNotAskForThem [

	server instVarNamed: #uiEnabled put: false.
	self deny: self manager forwardsToClient
]

{ #category : 'tests' }
PLSServerUITest >> testRequestAnswersNilWhenCancelled [

	self assert:
		(self
			 answer: [ self manager request: 'Name?' ]
			 with: '"result":null') second isNil
]

{ #category : 'tests' }
PLSServerUITest >> testRequestAsksTheClientForAText [

	| exchange |
	exchange := self
		            answer: [
		            self manager request: 'Name?' initialAnswer: 'Foo' ]
		            with: '"result":"Bar"'.
	self assert: (exchange first at: 'method') equals: 'pls-ui/request'.
	self
		assert: ((exchange first at: 'params') at: 'initialAnswer')
		equals: 'Foo'.
	self assert: exchange second equals: 'Bar'
]

{ #category : 'tests' }
PLSServerUITest >> testSendRequestAndWaitAnswersTheResultOfTheClient [

	| exchange |
	exchange := self
		            answer: [
		            server
			            sendRequestAndWait: 'pls/test'
			            params: Dictionary new ]
		            with: '"result":{"value":42}'.
	self assert: (exchange first at: 'method') equals: 'pls/test'.
	self assert: (exchange second at: 'value') equals: 42.
	self assertEmpty: server pendingClientRequests
]

{ #category : 'tests' }
PLSServerUITest >> testSendRequestAndWaitGivesUpAfterItsTimeout [

	self
		should: [
				server
					sendRequestAndWait: 'pls/test'
					params: Dictionary new
					timeout: 50 milliSeconds ]
		raise: PLSClientRequestFailed.
	self assertEmpty: server pendingClientRequests
]

{ #category : 'tests' }
PLSServerUITest >> testSendRequestAndWaitSignalsTheErrorOfTheClient [

	| exchange |
	exchange := self
		            answer: [
				            [
				            server
					            sendRequestAndWait: 'pls/test'
					            params: Dictionary new ]
					            on: PLSClientRequestFailed
					            do: [ :error | error code ] ]
		            with: '"error":{"code":-32601,"message":"Unknown"}'.
	self assert: exchange second equals: -32601
]

{ #category : 'tests' }
PLSServerUITest >> testUIIsEnabledOnlyWhenTheClientAsksForIt [

	self deny: (server uiEnabledIn: nil).
	self deny: (server uiEnabledIn: Dictionary new).
	self deny: (server uiEnabledIn: { (#ui -> true) } asDictionary).
	self assert: (server uiEnabledIn:
			 { (#ui -> { (#version -> 1) } asDictionary) } asDictionary)
]

{ #category : 'helpers' }
PLSServerUITest >> waitForRequest [
	"The request the server sent to the client, once it sent it"

	100 timesRepeat: [
			self messages
				detect: [ :each |
					(each includesKey: 'id') and: [ each includesKey: 'method' ] ]
				ifFound: [ :request | ^ request ].
			(Delay forMilliseconds: 20) wait ].
	self fail: 'The server sent no request'
]
