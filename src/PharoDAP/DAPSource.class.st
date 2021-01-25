Class {
	#name : #DAPSource,
	#superclass : #DAPJsonableObject,
	#instVars : [
		'name',
		'sourceReference'
	],
	#category : #'PharoDAP-Types'
}

{ #category : #accessing }
DAPSource >> asDAPJSON [
	^ super asDAPJSON
		at: #name put: self name;
		at: #sourceReference put: self sourceReference;
		yourself
]

{ #category : #accessing }
DAPSource >> name [
	^ name
]

{ #category : #accessing }
DAPSource >> name: anObject [
	name := anObject
]

{ #category : #accessing }
DAPSource >> sourceReference [
	^ sourceReference
]

{ #category : #accessing }
DAPSource >> sourceReference: anObject [
	sourceReference := anObject
]
