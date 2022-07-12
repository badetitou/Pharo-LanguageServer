Class {
	#name : #PLSLogMessage,
	#superclass : #Object,
	#instVars : [
		'type',
		'message'
	],
	#category : #'PharoLanguageServer-Strcuture-LogMessage'
}

{ #category : #'as yet unclassified' }
PLSLogMessage class >> message: aMessage type: aTypeMessage [
	^ self new
		message: aMessage;
		type: aTypeMessage;
		yourself
]

{ #category : #accessing }
PLSLogMessage >> asJRPCJSON [
	^ {(#message -> self message asJRPCJSON).
	(#type -> self type asJRPCJSON)} asDictionary
]

{ #category : #accessing }
PLSLogMessage >> message [
	^ message
]

{ #category : #accessing }
PLSLogMessage >> message: anObject [
	message := anObject
]

{ #category : #accessing }
PLSLogMessage >> type [
	^ type
]

{ #category : #accessing }
PLSLogMessage >> type: anObject [
	type := anObject
]
