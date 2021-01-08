Class {
	#name : #DAPEvent,
	#superclass : #DAPMessage,
	#instVars : [
		'event',
		'body'
	],
	#category : #'PharoDAP-Structure'
}

{ #category : #'as yet unclassified' }
DAPEvent >> initialize [
	super initialize.
	type := 'event'
]
