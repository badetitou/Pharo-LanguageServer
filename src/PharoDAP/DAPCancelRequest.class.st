Class {
	#name : #DAPCancelRequest,
	#superclass : #DAPRequest,
	#category : #'PharoDAP-Structure'
}

{ #category : #initialization }
DAPCancelRequest >> initialize [
	super initialize.
	command := 'cancel'
]
