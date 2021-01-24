Class {
	#name : #DAPEvaluateResponse,
	#superclass : #DAPResponse,
	#instVars : [
		'result',
		'variablesReference'
	],
	#category : #'PharoDAP-Structure'
}

{ #category : #accessing }
DAPEvaluateResponse >> asDAPJSON [
	| dic |
	self body at: #result put: self result.
	self body at: #variableReferences put: self variablesReference.
	dic := super asDAPJSON.
	^ dic
]

{ #category : #accessing }
DAPEvaluateResponse >> initialize [
	super initialize.
	body := Dictionary new
]

{ #category : #accessing }
DAPEvaluateResponse >> result [
	^ result
]

{ #category : #accessing }
DAPEvaluateResponse >> result: anObject [
	result := anObject
]

{ #category : #accessing }
DAPEvaluateResponse >> variablesReference [
	^ variablesReference
]

{ #category : #accessing }
DAPEvaluateResponse >> variablesReference: anObject [
	variablesReference := anObject
]
