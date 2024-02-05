Class {
	#name : #PLCContext,
	#superclass : #Object,
	#instVars : [
		'textItems'
	],
	#category : 'PharoLanguageClient'
}

{ #category : #initialization }
PLCContext >> initialize [

	super initialize.
	textItems := Dictionary new
]

{ #category : #initialization }
PLCContext >> removeTextItem: aURI [

	^ self textItems removeKey: aURI
]

{ #category : #initialization }
PLCContext >> textItem: aURI [

	^ self textItems at: aURI
]

{ #category : #initialization }
PLCContext >> textItem: aURI put: aTextItem [

	^ self textItems at: aURI put: aTextItem
]

{ #category : #accessing }
PLCContext >> textItems [

	^ textItems
]

{ #category : #accessing }
PLCContext >> textItems: anObject [

	textItems := anObject
]
