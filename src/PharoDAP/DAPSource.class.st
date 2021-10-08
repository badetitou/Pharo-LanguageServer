Class {
	#name : #DAPSource,
	#superclass : #DAPJsonableObject,
	#instVars : [
		'name',
		'sourceReference',
		'path'
	],
	#category : #'PharoDAP-Types'
}

{ #category : #accessing }
DAPSource >> asDAPJSON [
	| json |
	json:= super asDAPJSON
		at: #name put: self name;
		at: #sourceReference put: self sourceReference;
		yourself.
	self path ifNotNil:[ json at:#path put: self path ].
	^ json
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
DAPSource >> path [

	^ path
]

{ #category : #accessing }
DAPSource >> path: anObject [

	path := anObject
]

{ #category : #accessing }
DAPSource >> sourceReference [
	^ sourceReference
]

{ #category : #accessing }
DAPSource >> sourceReference: anObject [
	sourceReference := anObject
]
