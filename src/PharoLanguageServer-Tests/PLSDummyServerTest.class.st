Class {
	#name : #PLSDummyServerTest,
	#superclass : #TestCase,
	#instVars : [
		'server',
		'out'
	],
	#category : #'PharoLanguageServer-Tests'
}

{ #category : #initialization }
PLSDummyServerTest >> setUp [
	super setUp.
	server := PLSDummyServer new
]

{ #category : #initialization }
PLSDummyServerTest >> tearDown [
	super tearDown.
]
