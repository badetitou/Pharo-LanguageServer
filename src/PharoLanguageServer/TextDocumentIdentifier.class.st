Class {
	#name : #TextDocumentIdentifier,
	#superclass : #Object,
	#instVars : [
		'uri'
	],
	#category : #'PharoLanguageServer-Structure-TextDocument'
}

{ #category : #accessing }
TextDocumentIdentifier >> uri [

	^ uri
]

{ #category : #accessing }
TextDocumentIdentifier >> uri: anObject [

	uri := anObject
]
