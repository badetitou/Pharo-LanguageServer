Class {
	#name : 'DAPLaunchRequest',
	#superclass : 'DAPRequest',
	#category : 'PharoDAP-Structure',
	#package : 'PharoDAP',
	#tag : 'Structure'
}

{ #category : 'initialization' }
DAPLaunchRequest >> initialize [
	super initialize.
	command := 'launch'
]
