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

	client := PLCDummyClient new.
	server := PLSServer new.
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
PLPTests >> testInitialize [

	client connect.
	self
		assert: (server context clientContext clientInfo at: #name)
		equals: 'PLCClient'
]
