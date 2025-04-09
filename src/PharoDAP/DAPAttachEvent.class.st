Class {
	#name : 'DAPAttachEvent',
	#superclass : 'DAPEvent',
	#category : 'PharoDAP-Structure',
	#package : 'PharoDAP',
	#tag : 'Structure'
}

{ #category : 'as yet unclassified' }
DAPAttachEvent >> initialize [
	super initialize.
	event := 'initialized'
]
