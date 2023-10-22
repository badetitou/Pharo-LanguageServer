Class {
	#name : #PLPTextDocumentItem,
	#superclass : #Object,
	#instVars : [
		'uri',
		'languageId',
		'version',
		'text'
	],
	#category : #'PharoLanguageProtocol-TextDocument'
}

{ #category : #accessing }
PLPTextDocumentItem >> asJRPCJSON [

	^ { 
		  (#languageId -> self languageId asJRPCJSON).
		  (#text -> self text asJRPCJSON).
		  (#uri -> self uri asJRPCJSON).
		  (#version -> self version asJRPCJSON) } asDictionary
]

{ #category : #accessing }
PLPTextDocumentItem >> languageId [

	^ languageId
]

{ #category : #accessing }
PLPTextDocumentItem >> languageId: anObject [

	languageId := anObject
]

{ #category : #accessing }
PLPTextDocumentItem >> text [

	^ text
]

{ #category : #accessing }
PLPTextDocumentItem >> text: anObject [

	text := anObject
]

{ #category : #accessing }
PLPTextDocumentItem >> uri [

	^ uri
]

{ #category : #accessing }
PLPTextDocumentItem >> uri: anObject [

	uri := anObject
]

{ #category : #accessing }
PLPTextDocumentItem >> version [

	^ version
]

{ #category : #accessing }
PLPTextDocumentItem >> version: anObject [

	version := anObject
]
