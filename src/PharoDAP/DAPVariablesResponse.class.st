Class {
	#name : #DAPVariablesResponse,
	#superclass : #DAPResponse,
	#instVars : [
		'variables'
	],
	#category : #'PharoDAP-Structure'
}

{ #category : #accessing }
DAPVariablesResponse >> asDAPJSON [
	| dic |
	self body at: #variables put: variables asArray.
	dic := super asDAPJSON.
	^ dic
]

{ #category : #initialization }
DAPVariablesResponse >> initialize [
	super initialize.
	body := Dictionary new.
	variables := OrderedCollection new.
]

{ #category : #accessing }
DAPVariablesResponse >> variables [
	^ variables
]

{ #category : #accessing }
DAPVariablesResponse >> variables: anObject [
	variables := anObject
]
