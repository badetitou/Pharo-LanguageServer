Class {
	#name : #PLSTonelDocument,
	#superclass : #PLSDocument,
	#category : #'PharoLanguageServer-Document'
}

{ #category : #'instance creation' }
PLSTonelDocument class >> fromDocumentDictionary: aDocumentDictionary [
	^ self new
		version: (aDocumentDictionary at: #version);
		text: (aDocumentDictionary at: #text);
		languageId: (aDocumentDictionary at: #languageId);
		uri: (aDocumentDictionary at: #uri);
		yourself
]

{ #category : #testing }
PLSTonelDocument >> isTonelDocument [
	^ true
]
