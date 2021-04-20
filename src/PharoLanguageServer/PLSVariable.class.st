Class {
	#name : #PLSVariable,
	#superclass : #Object,
	#instVars : [
		'name',
		'value',
		'variableReference'
	],
	#category : #'PharoLanguageServer-Structure-Variables'
}

{ #category : #accessing }
PLSVariable >> asJRPCJSON [
	^ {(#name -> self name asJRPCJSON).
	(#value -> self value1 asJRPCJSON).
	(#variableReference -> self variableReference asJRPCJSON)} asDictionary
]

{ #category : #accessing }
PLSVariable >> name [
	^ name
]

{ #category : #accessing }
PLSVariable >> name: anObject [
	name := anObject
]

{ #category : #accessing }
PLSVariable >> value1 [
	^ value
]

{ #category : #accessing }
PLSVariable >> value: anObject [
	value := anObject
]

{ #category : #accessing }
PLSVariable >> variableReference [
	^ variableReference
]

{ #category : #accessing }
PLSVariable >> variableReference: anObject [
	variableReference := anObject
]
