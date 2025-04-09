Class {
	#name : 'PLPDummyClient',
	#superclass : 'Object',
	#traits : 'TPLCClient',
	#classTraits : 'TPLCClient classTrait',
	#instVars : [
		'receivedAnswer'
	],
	#category : 'PharoLanguageProtocol-Tests',
	#package : 'PharoLanguageProtocol-Tests'
}

{ #category : 'accessing' }
PLPDummyClient >> answerLoop [

	^ answerLoop
]

{ #category : 'accessing' }
PLPDummyClient >> answerLoop: aBoolean [

	answerLoop := aBoolean
]

{ #category : 'plp - tests' }
PLPDummyClient >> anwserWithAccent: answer [
	"Should never go here"

	<jrpc: #'plptest/frenchAccent'>
	self receivedAnswer: answer
]

{ #category : 'initialization' }
PLPDummyClient >> initialize [

	super initialize.
	self language: #dummy.
	self clientInit
]

{ #category : 'plp - tests' }
PLPDummyClient >> longServerMethod: answer [
	"Should never go here"

	<jrpc: #'plptest/longServerMethod'>
	
]

{ #category : 'accessing' }
PLPDummyClient >> receivedAnswer [

	^ receivedAnswer
]

{ #category : 'accessing' }
PLPDummyClient >> receivedAnswer: anObject [

	receivedAnswer := anObject
]

{ #category : 'plp - tests' }
PLPDummyClient >> sendAnwserWithAccent [

	self
		callMethod: 'plptest/frenchAccent'
		arguments: nil
		withId: self nextId
]

{ #category : 'plp - tests' }
PLPDummyClient >> sendLongServerMethod [

	self
		callMethod: 'plptest/longServerMethod'
		arguments: nil
		withId: self nextId
]

{ #category : 'lsp - window' }
PLPDummyClient >> windowLogMessage: message withType: type [

	<jrpc: #'window/logMessage'>
	message asString recordInfo
]
