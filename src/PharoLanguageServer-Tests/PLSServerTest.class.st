"
A PLSServerTest is a test class for testing the behavior of PLSServer
"
Class {
	#name : #PLSServerTest,
	#superclass : #TestCase,
	#instVars : [
		'server'
	],
	#category : #'PharoLanguageServer-Tests'
}

{ #category : #test }
PLSServerTest >> setUp [

	super setUp.
	server := PLSServer new.
	server clientOutStream: NullStream new
]

{ #category : #test }
PLSServerTest >> tearDown [

	server clientOutStream close.
	super tearDown
]

{ #category : #test }
PLSServerTest >> testDidOpen [

	| textDocument |
	textDocument := Dictionary new.
	textDocument at: #uri put: 'src/myScript.st'.
	textDocument at: #version put: '1'.
	textDocument at: #languageId put: 'pharo'.
	textDocument at: #text put: '1 + 1'.

	server didOpen: textDocument.

	self
		assert: (server context textItem: 'src/myScript.st') class
		equals: PLSScriptDocument
]
