Class {
	#name : #PLSTextDocumentIdentifier,
	#superclass : #Object,
	#instVars : [
		'uri'
	],
	#category : #'PharoLanguageServer-Structure-TextDocument'
}

{ #category : #accessing }
PLSTextDocumentIdentifier >> asJRPCJSON [

	^ { (#uri -> self uri asJRPCJSON) } asDictionary
]

{ #category : #accessing }
PLSTextDocumentIdentifier >> uri [

	^ uri
]

{ #category : #accessing }
PLSTextDocumentIdentifier >> uri: anObject [

	uri := anObject
]
