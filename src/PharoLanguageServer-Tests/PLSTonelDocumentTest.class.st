"
A PLSTonelDocumentTest is a test class for testing the behavior of PLSTonelDocument
"
Class {
	#name : 'PLSTonelDocumentTest',
	#superclass : 'TestCase',
	#category : 'PharoLanguageServer-Tests-Document',
	#package : 'PharoLanguageServer-Tests',
	#tag : 'Document'
}

{ #category : 'tests' }
PLSTonelDocumentTest >> testCreateFromAURI [

	self
		assert: (PLSDocument fromURI: 'hello.class.st') class
		equals: PLSTonelDocument
]

{ #category : 'tests' }
PLSTonelDocumentTest >> testCreateFromTextDocument [

	self
		assert: (PLSDocument from: {
					 (#uri -> 'hello.class.st').
					 (#languageId -> 'hello.class.st').
					 (#version -> 1) } asDictionary) class
		equals: PLSTonelDocument
]

{ #category : 'tests' }
PLSTonelDocumentTest >> testCreateFromTextDocumentWithIceRepositoryURI [

	self
		assert: (PLSDocument from: {
					 (#uri -> 'hello.class.st?iceRepository=my-repo').
					 (#languageId -> 'hello.class.st').
					 (#version -> 1) } asDictionary) class
		equals: PLSTonelDocument
]
