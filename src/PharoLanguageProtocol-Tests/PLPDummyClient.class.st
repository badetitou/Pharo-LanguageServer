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

{ #category : #'lsp - window' }
PLPDummyClient >> windowLogMessage: message withType: type [

	<jrpc: #'window/logMessage'>
	message asString recordInfo
]
