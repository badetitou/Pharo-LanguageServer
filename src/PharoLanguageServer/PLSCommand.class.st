Class {
	#name : #PLSCommand,
	#superclass : #Object,
	#instVars : [
		'title',
		'command',
		'arguments'
	],
	#category : 'PharoLanguageServer-Structure'
}

{ #category : #accessing }
PLSCommand >> arguments [
	^ arguments
]

{ #category : #accessing }
PLSCommand >> arguments: anObject [
	arguments := anObject
]

{ #category : #accessing }
PLSCommand >> asJRPCJSON [

	| dic |
	dic := { 
		       (#command -> self command asJRPCJSON).
		       (#title -> self title asJRPCJSON) } asDictionary.
	self arguments ifNotNil: [ 
		dic at: #arguments put: self arguments asJRPCJSON ].
	^ dic
]

{ #category : #accessing }
PLSCommand >> command [
	^ command
]

{ #category : #accessing }
PLSCommand >> command: anObject [
	command := anObject
]

{ #category : #accessing }
PLSCommand >> title [
	^ title
]

{ #category : #accessing }
PLSCommand >> title: anObject [
	title := anObject
]
