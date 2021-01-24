Class {
	#name : #DAPScopesResponse,
	#superclass : #DAPResponse,
	#instVars : [
		'scopes'
	],
	#category : #'PharoDAP-Structure'
}

{ #category : #accessing }
DAPScopesResponse >> asDAPJSON [
	| dic |
	self body at: #scopes put: self scopes asArray.
	dic := super asDAPJSON.
	^ dic
]

{ #category : #accessing }
DAPScopesResponse >> initialize [
	super initialize.
	body := Dictionary new.
	scopes := OrderedCollection new.
]

{ #category : #accessing }
DAPScopesResponse >> scopes [
	^ scopes
]

{ #category : #accessing }
DAPScopesResponse >> scopes: anObject [
	scopes := anObject
]
