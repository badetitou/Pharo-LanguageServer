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
	^ self new
		seq: (aJSONObject at: #seq);
		command: (aJSONObject at: #command);
		arguments: (aJSONObject at: #arguments);
		yourself
]

{ #category : #accessing }
DAPRequest >> arguments [
	^ arguments
]

{ #category : #accessing }
DAPRequest >> arguments: anObject [
	arguments := anObject
]

{ #category : #initialization }
DAPRequest >> beHandledBy: aDAPRequestProcessor [
	aDAPRequestProcessor handleRequest: self
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
DAPRequest >> initialize [
	super initialize.
	type := 'request'
]
