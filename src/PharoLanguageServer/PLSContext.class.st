"
The server use me to store informations such as the text item 
"
Class {
	#name : #PLSContext,
	#superclass : #Object,
	#instVars : [
		'textItems',
		'messageProcesses'
	],
	#category : #PharoLanguageServer
}

{ #category : #accessing }
PLSContext >> initialize [
	textItems := Dictionary new.
	messageProcesses := Dictionary new
]

{ #category : #accessing }
PLSContext >> messageProcesses [
	^ messageProcesses
]

{ #category : #accessing }
PLSContext >> messageProcesses: anObject [
	messageProcesses := anObject
]

{ #category : #accessing }
PLSContext >> messageProcessesAt: anId put: aProcess [
	anId ifNotNil: [ self messageProcesses at: anId put: aProcess ]
]

{ #category : #accessing }
PLSContext >> removeItem: aURI [
	^ self textItems removeKey: aURI
]

{ #category : #accessing }
PLSContext >> removeMessageProcess: anId [
	anId ifNotNil: [ self messageProcesses removeKey: anId ]
]

{ #category : #accessing }
PLSContext >> textItem: aURI [
	^ self textItems at: aURI
]

{ #category : #accessing }
PLSContext >> textItem: aURI put: aTextItem [
	^ self textItems at: aURI put: aTextItem
]

{ #category : #accessing }
PLSContext >> textItems [
	^ textItems
]

{ #category : #accessing }
PLSContext >> textItems: anObject [
	textItems := anObject
]
