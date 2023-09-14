Class {
	#name : #PLCDummyClient,
	#superclass : #Object,
	#traits : 'TPLCClient',
	#classTraits : 'TPLCClient classTrait',
	#category : #'PharoLanguageProtocol-Tests'
}

{ #category : #converting }
PLCDummyClient >> initialize [

	super initialize.
	self clientInit
]

{ #category : #'lsp - window' }
PLCDummyClient >> windowLogMessage: message withType: type [

	<jrpc: #'window/logMessage'>
	message asString recordInfo
]
