Class {
	#name : #PLCAnswerProcessor,
	#superclass : #Object,
	#instVars : [
		'answerHandlers',
		'client'
	],
	#category : #PharoLanguageClient
}

{ #category : #'instance creation' }
PLCAnswerProcessor class >> for: aTPLCClient [

	^ self new
		  client: aTPLCClient;
		  yourself
]

{ #category : #adding }
PLCAnswerProcessor >> addHandlerFor: aRequest [
	self halt
]

{ #category : #accessing }
PLCAnswerProcessor >> client [

	^ client
]

{ #category : #accessing }
PLCAnswerProcessor >> client: anObject [

	client := anObject
]

{ #category : #adding }
PLCAnswerProcessor >> handle: aRequest [
]

{ #category : #initialization }
PLCAnswerProcessor >> initialize [

	super initialize.
	answerHandlers := Dictionary new
]
