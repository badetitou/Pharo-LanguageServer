Class {
	#name : #PLPDummyClient,
	#superclass : #Object,
	#traits : 'TPLCClient',
	#classTraits : 'TPLCClient classTrait',
	#category : #'PharoLanguageProtocol-Tests'
}

{ #category : #converting }
PLPDummyClient >> initialize [

	super initialize.
	self clientInit
]

{ #category : #'plp - tests' }
PLPDummyClient >> longServerMethod: answer [
	"Should never go here"

	<jrpc: #'plptest/longServerMethod'>
	
]

{ #category : #'plp - tests' }
PLPDummyClient >> sendLongServerMethod [

	self
		callMethod: 'plptest/longServerMethod'
		arguments: nil
		withId: self nextId
]

{ #category : #'lsp - window' }
PLPDummyClient >> windowLogMessage: message withType: type [

	<jrpc: #'window/logMessage'>
	message asString recordInfo
]
