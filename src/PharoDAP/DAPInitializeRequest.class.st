Class {
	#name : 'DAPInitializeRequest',
	#superclass : 'DAPRequest',
	#category : 'PharoDAP-Structure',
	#package : 'PharoDAP',
	#tag : 'Structure'
}

{ #category : 'initialization' }
DAPInitializeRequest >> initialize [
	super initialize.
	command := 'initialize'
]
