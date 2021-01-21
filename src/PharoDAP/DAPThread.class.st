Class {
	#name : #DAPThread,
	#superclass : #DAPJsonableObject,
	#instVars : [
		'id',
		'name'
	],
	#category : #'PharoDAP-Types'
}

{ #category : #converting }
DAPThread >> asDAPJSON [
	^ super asDAPJSON
		at: #id put: self id;
		at: #name put: self name;
		yourself
]

{ #category : #accessing }
DAPThread >> id [
	^ id
]

{ #category : #accessing }
DAPThread >> id: anObject [
	id := anObject
]

{ #category : #accessing }
DAPThread >> name [
	^ name
]

{ #category : #accessing }
DAPThread >> name: anObject [
	name := anObject
]
