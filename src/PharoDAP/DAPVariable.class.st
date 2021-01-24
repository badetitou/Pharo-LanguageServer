Class {
	#name : #DAPVariable,
	#superclass : #DAPJsonableObject,
	#instVars : [
		'name',
		'value',
		'variablesReference'
	],
	#category : #'PharoDAP-Types'
}

{ #category : #accessing }
DAPVariable >> asDAPJSON [
	^ super asDAPJSON
		at: #name put: self name;
		at: #value put: self value1;
		at: #variablesReference put: self variablesReference;
		yourself
]

{ #category : #accessing }
DAPVariable >> name [
	^ name
]

{ #category : #accessing }
DAPVariable >> name: anObject [
	name := anObject
]

{ #category : #accessing }
DAPVariable >> value1 [
	^ value
]

{ #category : #accessing }
DAPVariable >> value: anObject [
	value := anObject
]

{ #category : #accessing }
DAPVariable >> variablesReference [
	^ variablesReference
]

{ #category : #accessing }
DAPVariable >> variablesReference: anObject [
	variablesReference := anObject
]
