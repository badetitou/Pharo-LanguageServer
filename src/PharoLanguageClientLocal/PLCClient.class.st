Class {
	#name : 'PLCClient',
	#superclass : 'Object',
	#traits : 'TPLCClient',
	#classTraits : 'TPLCClient classTrait',
	#category : 'PharoLanguageClientLocal',
	#package : 'PharoLanguageClientLocal'
}

{ #category : 'plp - answerLoop' }
PLCClient >> answerLoopPriority [

	^ answerLoopPriority ifNil: [
		  answerLoopPriority := Processor userBackgroundPriority ]
]

{ #category : 'api' }
PLCClient >> initialize [

	super initialize
]
