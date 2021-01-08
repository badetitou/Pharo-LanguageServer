Class {
	#name : #DAPMessage,
	#superclass : #DAPJsonableObject,
	#instVars : [
		'seq',
		'type'
	],
	#category : #'PharoDAP-Structure'
}

{ #category : #accessing }
DAPMessage >> seq [
	^ seq
]

{ #category : #accessing }
DAPMessage >> seq: anObject [
	seq := anObject
]

{ #category : #accessing }
DAPMessage >> type [
	^ type
]

{ #category : #accessing }
DAPMessage >> type: anObject [
	type := anObject
]
