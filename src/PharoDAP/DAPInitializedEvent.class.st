Class {
	#name : #DAPInitializedEvent,
	#superclass : #DAPEvent,
	#category : #'PharoDAP-Structure'
}

{ #category : #'as yet unclassified' }
DAPInitializedEvent >> initialize [
	super initialize.
	event := 'initialized'
]
