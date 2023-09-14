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
