Class {
	#name : 'PLSInitializeResult',
	#superclass : 'Object',
	#instVars : [
		'capabilities',
		'serverInfo'
	],
	#category : 'PharoLanguageServer-Structure',
	#package : 'PharoLanguageServer',
	#tag : 'Structure'
}

{ #category : 'accessing' }
PLSInitializeResult >> asJRPCJSON [
	^ { 
	#'capabilities' -> self capabilities asJRPCJSON.
	#'serverInfo' -> self serverInfo asJRPCJSON.
	 } asDictionary 
]

{ #category : 'accessing' }
PLSInitializeResult >> capabilities [
	^ capabilities
]

{ #category : 'accessing' }
PLSInitializeResult >> capabilities: anObject [
	capabilities := anObject
]

{ #category : 'initialization' }
PLSInitializeResult >> initialize [
	super initialize.
	serverInfo := Dictionary new.
	serverInfo at: #name put: 'Pharo Language Server'.
	serverInfo at: #version put: 'v0.0.1'.
	capabilities := PLSServerCapabilities forPharo.
]

{ #category : 'accessing' }
PLSInitializeResult >> serverInfo [
	^ serverInfo
]

{ #category : 'accessing' }
PLSInitializeResult >> serverInfo: anObject [
	serverInfo := anObject
]
