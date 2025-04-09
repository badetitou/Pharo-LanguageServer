Class {
	#name : 'DAPCancelRequest',
	#superclass : 'DAPRequest',
	#category : 'PharoDAP-Structure',
	#package : 'PharoDAP',
	#tag : 'Structure'
}

{ #category : 'initialization' }
DAPCancelRequest >> initialize [
	super initialize.
	command := 'cancel'
]
