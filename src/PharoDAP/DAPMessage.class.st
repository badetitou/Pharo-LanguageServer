Class {
	#name : #DAPMessage,
	#superclass : #DAPJsonableObject,
	#instVars : [
		'seq',
		'type'
	],
	#category : #'PharoDAP-Structure'
}

{ #category : #converting }
DAPMessage >> asDAPJSON [
	| dic |
	dic := super asDAPJSON.
	self seq ifNotNil: [ dic add: #seq -> self seq ].
	self type ifNotNil: [ dic add: #type -> self type ].
	^ dic
]

{ #category : #accessing }
DAPMessage >> beConvertedBy: aDAPMessageProcessor [
	^ aDAPMessageProcessor convertDAPJsonableObjectToJSON: self
]

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
