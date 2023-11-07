Class {
	#name : #PLSShowMessage,
	#superclass : #Object,
	#instVars : [
		'type',
		'message'
	],
	#category : 'PharoLanguageServer-Structure-Message'
}

{ #category : #'as yet unclassified' }
PLSShowMessage class >> message: aMessage type: aTypeMessage [
	^ self new
		message: aMessage;
		type: aTypeMessage;
		yourself
]

{ #category : #accessing }
PLSShowMessage >> asJRPCJSON [
	^ {(#message -> self message asJRPCJSON).
	(#type -> self type asJRPCJSON)} asDictionary
]

{ #category : #accessing }
PLSShowMessage >> message [
	^ message
]

{ #category : #accessing }
PLSShowMessage >> message: anObject [
	message := anObject
]

{ #category : #accessing }
PLSShowMessage >> type [
	^ type
]

{ #category : #accessing }
PLSShowMessage >> type: anObject [
	type := anObject
]
