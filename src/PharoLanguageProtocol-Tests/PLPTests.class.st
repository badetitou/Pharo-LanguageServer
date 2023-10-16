Class {
	#name : #PLPTests,
	#superclass : #TestCase,
	#instVars : [
		'client',
		'server',
		'serverProcess'
	],
	#category : #'PharoLanguageProtocol-Tests'
}

{ #category : #running }
PLPTests >> setUp [

	| openPort |
	super setUp.

	client := PLPDummyClient new.
	server := PLPDummyServer new.
	server debugMode: true.
	server serverLoopPriority: Processor activeProcess priority.
	client answerLoopPriority: Processor activeProcess priority.
	serverProcess := [ server start ]
		forkAt: Processor activeProcess priority
		named: 'Test PLS server'.

	[ server port = 0 ] whileTrue.
	openPort := server port.
	client port: openPort
]

{ #category : #running }
PLPTests >> tearDown [

	serverProcess terminate.
	server stop.
	super tearDown
]

{ #category : #running }
PLPTests >> testCancelRequest [
	"I test that the client can cancel a long processing request of the server"

	self timeLimit: 3 seconds.
	client start.
	client sendLongServerMethod.
	client sendCancelRequest: client currentId.
	[ client answerProcessor answerHandlers isEmpty ] whileFalse.
	[ server context messageProcesses isEmpty ] whileFalse
]

{ #category : #running }
PLPTests >> testInitialize [

	client start.
	[ client answerProcessor answerHandlers isEmpty ] whileFalse.
	self
		assert: (server context clientContext clientInfo at: #name)
		equals: 'PLCClient'.
	self
		assert: (client serverContext at: #name)
		equals: 'Pharo Language Server'
]
