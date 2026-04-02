"
A PLSDocumentTest is a test class for testing the behavior of PLSDocument
"
Class {
	#name : 'PLSDocumentTest',
	#superclass : 'TestCase',
	#instVars : [
		'document'
	],
	#category : 'PharoLanguageServer-Tests-Document',
	#package : 'PharoLanguageServer-Tests',
	#tag : 'Document'
}

{ #category : 'running' }
PLSDocumentTest >> setUp [
	super setUp.

	"Put here a common initialization logic for tests"
	document :=  PLSDocument new.
]

{ #category : 'tests' }
PLSDocumentTest >> testCodeLens [

	"no code lens for generic document"

	self assert: document codeLens equals: {  }
]

{ #category : 'tests' }
PLSDocumentTest >> testCreateFromAURI [
	
	self assert: (PLSDocument fromURI: 'hello.xyz') class equals: PLSDocument
]

{ #category : 'tests' }
PLSDocumentTest >> testCreateFromTextDocument [

	self
		assert: (PLSDocument from: {
					 (#uri -> 'hello.xyz').
					 (#languageId -> 'hello.xyz').
					 (#version -> 1) } asDictionary) class
		equals: PLSDocument
]

{ #category : 'tests' }
PLSDocumentTest >> testCreateFromTextDocumentWithComplexURI [

	| doc |
	doc := PLSDocument from: {
			            (#uri -> 'hello.xyz?hello=3').
			            (#languageId -> 'hello.xyz').
			            (#version -> 1) } asDictionary.
	self assert: doc uri equals: 'hello.xyz'.
	self assert: doc class equals: PLSDocument
]

{ #category : 'tests' }
PLSDocumentTest >> testDiagnostics [
	"no diagnostics for generic document"

	self assert: document diagnostics equals: {  }
]

{ #category : 'tests' }
PLSDocumentTest >> testExtractUriFrom [

	self
		assert: (PLSDocument extractUriFrom:
				 'pharoImage:/Doc/Element.class.st?hello=34')
		equals: 'pharoImage:/Doc/Element.class.st'
]

{ #category : 'tests' }
PLSDocumentTest >> testExtractUriFromNoError [

	self
		assert: (PLSDocument extractUriFrom:
				 'pharoImage:/Doc/Element.class.st')
		equals: 'pharoImage:/Doc/Element.class.st'
]

{ #category : 'tests' }
PLSDocumentTest >> testSymbols [
	"no symbols for generic document"

	self assert: document symbols equals: {  }
]
