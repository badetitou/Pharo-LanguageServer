Class {
	#name : #DAPLaunchRequest,
	#superclass : #DAPRequest,
	#category : #'PharoDAP-Structure'
}

{ #category : #initialization }
DAPLaunchRequest >> initialize [
	super initialize.
	command := 'launch'
]
