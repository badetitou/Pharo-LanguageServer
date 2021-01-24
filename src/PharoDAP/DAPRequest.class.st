Class {
	#name : #DAPRequest,
	#superclass : #DAPMessage,
	#instVars : [
		'command',
		'arguments'
	],
	#category : #'PharoDAP-Structure'
}

{ #category : #'instance creation' }
DAPRequest class >> newFromJSON: aJSONObject [
	| deserializeMe |
	deserializeMe := self new
		seq: (aJSONObject at: #seq);
		command: (aJSONObject at: #command).
	aJSONObject
		at: #arguments
		ifPresent: [ :args | deserializeMe arguments: args ].
	^ deserializeMe
]

{ #category : #accessing }
DAPRequest >> arguments [
	^ arguments
]

{ #category : #accessing }
DAPRequest >> arguments: anObject [
	arguments := anObject
]

{ #category : #accessing }
DAPRequest >> command [
	^ command
]

{ #category : #accessing }
DAPRequest >> command: anObject [
	command := anObject
]

{ #category : #initialization }
DAPRequest >> convertErrorToResponse: anError [
	^ DAPErrorResponse new 
]

{ #category : #initialization }
DAPRequest >> initialize [
	super initialize.
	type := 'request'
]
