"
The server use me to store informations such as the text item 
"
Class {
	#name : #PLSContext,
	#superclass : #Object,
	#instVars : [
		'textItems',
		'messageProcesses',
		'clientContext'
	],
	#category : #'PharoLanguageServer-Context'
}

{ #category : #accessing }
PLSContext >> clientContext [

	^ clientContext
]

{ #category : #accessing }
PLSContext >> clientContext: anObject [

	clientContext := anObject
]

{ #category : #initialization }
PLSContext >> initialize [
	textItems := Dictionary new.
	messageProcesses := Dictionary new.
	clientContext := PLSClientContext
]

{ #category : #'message processing' }
PLSContext >> messageProcesses [
	^ messageProcesses
]

{ #category : #'message processing' }
PLSContext >> messageProcesses: anObject [
	messageProcesses := anObject
]

{ #category : #'message processing' }
PLSContext >> messageProcessesAt: anId put: aProcess [
	anId ifNotNil: [ self messageProcesses at: anId put: aProcess ]
]

{ #category : #'text item' }
PLSContext >> removeItem: aURI [
	^ self textItems removeKey: aURI
]

{ #category : #'message processing' }
PLSContext >> removeMessageProcess: anId [
	anId ifNotNil: [ self messageProcesses removeKey: anId ]
]

{ #category : #'text item' }
PLSContext >> textItem: aURI [
	^ self textItems at: aURI ifAbsentPut: [ PLSDocument fromURI: aURI ]
]

{ #category : #'text item' }
PLSContext >> textItem: aURI ifAbsent: aBlock [ 
	^ self textItems at: aURI ifAbsent: aBlock
]

{ #category : #'text item' }
PLSContext >> textItem: aURI put: aTextItem [
	^ self textItems at: aURI put: aTextItem
]

{ #category : #'text item' }
PLSContext >> textItems [
	^ textItems
]

{ #category : #'text item' }
PLSContext >> textItems: anObject [
	textItems := anObject
]
