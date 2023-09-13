Class {
	#name : #PLPTests,
	#superclass : #TestCase,
	#instVars : [
		'client',
		'server'
	],
	#category : #'PharoLanguageProtocol-Tests'
}

{ #category : #running }
PLPTests >> setUp [

	| byteArray openPort |
	super setUp.

	client := PLCDummyClient new.
	server := PLSServer new.
	[ server start ]
		forkAt: Processor activeProcess priority
		named: 'Test PLS server'.
	Stdio stdout waitForData.
	byteArray := Stdio stdout next: 100.
	openPort := byteArray asString asInteger.
	client port: openPort
]

{ #category : #running }
PLPTests >> testInitialize [

	client connect.
	self
		assert: (server context clientInfo at: #name)
		equals: 'PLCClient'
]
