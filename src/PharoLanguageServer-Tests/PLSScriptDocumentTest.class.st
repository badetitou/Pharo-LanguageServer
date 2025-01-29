"
A PLSScriptDocumentTest is a test class for testing the behavior of PLSScriptDocument
"
Class {
	#name : 'PLSScriptDocumentTest',
	#superclass : 'TestCase',
	#category : 'PharoLanguageServer-Tests-Document',
	#package : 'PharoLanguageServer-Tests',
	#tag : 'Document'
}

{ #category : 'tests' }
PLSScriptDocumentTest >> testCreateFromAURI [
	
	self assert: (PLSDocument fromURI: 'hello.st') class equals: PLSScriptDocument
]

{ #category : 'tests' }
PLSScriptDocumentTest >> testCreateFromTextDocument [

	self
		assert: (PLSDocument from: {
					 (#uri -> 'hello.st').
					 (#languageId -> 'hello.st').
					 (#version -> 1) } asDictionary) class
		equals: PLSScriptDocument
]
