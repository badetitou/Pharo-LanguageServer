"
The server use me to store informations such as the text item 
"
Class {
	#name : #PLSContext,
	#superclass : #Object,
	#instVars : [
		'textItems'
	],
	#category : #PharoLanguageServer
}

{ #category : #accessing }
PLSContext >> initialize [
	textItems := Dictionary new
]

{ #category : #accessing }
PLSContext >> removeItem: aURI [
	^ self textItems removeKey: aURI
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
