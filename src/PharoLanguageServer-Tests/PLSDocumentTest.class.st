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
PLSDocumentTest >> testDiagnostics [
	"no diagnostics for generic document"

	self assert: document diagnostics equals: {  }
]

{ #category : 'tests' }
PLSDocumentTest >> testSymbols [
	"no symbols for generic document"

	self assert: document symbols equals: {  }
]
