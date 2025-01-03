Class {
	#name : 'DAPInitializedEvent',
	#superclass : 'DAPEvent',
	#category : 'PharoDAP-Structure',
	#package : 'PharoDAP',
	#tag : 'Structure'
}

{ #category : 'as yet unclassified' }
DAPInitializedEvent >> initialize [
	super initialize.
	event := 'initialized'
]
