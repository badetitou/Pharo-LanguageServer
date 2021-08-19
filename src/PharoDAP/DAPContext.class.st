"
The server use me to store informations such as the text item 
"
Class {
	#name : #DAPContext,
	#superclass : #Object,
	#instVars : [
		'textItems',
		'messageProcesses'
	],
	#category : #PharoDAP
}

{ #category : #initialization }
DAPContext >> initialize [
	textItems := Dictionary new.
	messageProcesses := Dictionary new.
]

{ #category : #'message processing' }
DAPContext >> messageProcesses [
	^ messageProcesses
]

{ #category : #'message processing' }
DAPContext >> messageProcesses: anObject [
	messageProcesses := anObject
]

{ #category : #'message processing' }
DAPContext >> messageProcessesAt: anId put: aProcess [
	anId ifNotNil: [ self messageProcesses at: anId put: aProcess ]
]

{ #category : #'text item' }
DAPContext >> removeItem: aURI [
	^ self textItems removeKey: aURI
]

{ #category : #'message processing' }
DAPContext >> removeMessageProcess: anId [
	anId ifNotNil: [ self messageProcesses removeKey: anId ]
]

{ #category : #'text item' }
DAPContext >> textItem: aURI [
	^ self textItems at: aURI ifAbsentPut: [ PLSDocument fromURI: aURI ]
]

{ #category : #'text item' }
DAPContext >> textItem: aURI ifAbsent: aBlock [ 
	^ self textItems at: aURI ifAbsent: aBlock
]

{ #category : #'text item' }
DAPContext >> textItem: aURI put: aTextItem [
	^ self textItems at: aURI put: aTextItem
]

{ #category : #'text item' }
DAPContext >> textItems [
	^ textItems
]

{ #category : #'text item' }
DAPContext >> textItems: anObject [
	textItems := anObject
]
