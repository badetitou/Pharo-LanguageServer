Class {
	#name : #DAPHandler,
	#superclass : #Object,
	#instVars : [
		'methodName',
		'receiver',
		'messageSelector'
	],
	#category : #PharoDAP
}

{ #category : #accessing }
DAPHandler >> checkParametersForRequest: aDAPRequestObject [ 
	aDAPRequestObject arguments
		ifNil: [
			self parametersCount = 0
				ifFalse: [ DAPInvalidParameters signal ] ].
	
	(aDAPRequestObject arguments ifNil: [ #() ]) size = self parametersCount
		ifFalse: [ DAPInvalidParameters signal ].
		
	(aDAPRequestObject arguments isDictionary
		and: [ ((aDAPRequestObject params keys union: self parametersNames) size ~= self parametersCount) ])
			ifTrue: [ DAPInvalidParameters signal ]
]

{ #category : #accessing }
DAPHandler >> executeWithArguments: anArrayOrDictionary [
	^ self execute: [ self
		send: self messageSelector
		to: self receiver
		with: anArrayOrDictionary ] recordedAs: self messageSelector printString
]

{ #category : #accessing }
DAPHandler >> messageSelector [
	^ messageSelector
]

{ #category : #accessing }
DAPHandler >> messageSelector: anObject [
	messageSelector := anObject
]

{ #category : #accessing }
DAPHandler >> methodName [
	^ methodName
]

{ #category : #accessing }
DAPHandler >> methodName: anObject [
	methodName := anObject
]

{ #category : #accessing }
DAPHandler >> parametersCount [
	"Returns the number of parameters expected by the handler."
	^ self parametersNames size
]

{ #category : #accessing }
DAPHandler >> parametersNames [
	^ (self receiver class >> self messageSelector) argumentNames
]

{ #category : #accessing }
DAPHandler >> receiver [
	^ receiver
]

{ #category : #accessing }
DAPHandler >> receiver: anObject [
	receiver := anObject
]

{ #category : #accessing }
DAPHandler >> send: aSelector to: aReceiver with: arguments [
	^ aReceiver perform: aSelector with: arguments
]
