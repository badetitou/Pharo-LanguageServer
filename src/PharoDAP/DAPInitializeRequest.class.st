Class {
	#name : #DAPInitializeRequest,
	#superclass : #DAPRequest,
	#category : #'PharoDAP-Structure'
}

{ #category : #initialization }
DAPInitializeRequest >> initialize [
	super initialize.
	command := 'initialize'
]
