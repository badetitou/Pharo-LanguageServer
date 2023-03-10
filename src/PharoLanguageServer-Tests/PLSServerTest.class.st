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

{ #category : #'running - additional setup' }
PLSServerTest >> addMyScriptDocument [

	| textDocument |
	textDocument := Dictionary new.
	textDocument at: #uri put: 'src/myScript.st'.
	textDocument at: #version put: '1'.
	textDocument at: #languageId put: 'pharo'.
	textDocument at: #text put: '1 + 1'.

	server didOpen: textDocument
]

{ #category : #running }
PLSServerTest >> setUp [

	super setUp.
	server := PLSServer new.
	server clientOutStream: NullStream new
]

{ #category : #running }
PLSServerTest >> tearDown [

	server clientOutStream close.
	super tearDown
]

{ #category : #test }
PLSServerTest >> testCommandPharoPrintItTextDocument [

	| result |
	self addMyScriptDocument.
	result := server
		          commandPharoPrintIt: '''Hello World'''
		          textDocument:
		          { (#path -> 'src/myScript.st') } asDictionary.
	self assert: '''Hello World''' equals: result.
	result := server
		          commandPharoPrintIt: '1 + 1'
		          textDocument:
		          { (#path -> 'src/myScript.st') } asDictionary.
	self assert: '2' equals: result
]

{ #category : #test }
PLSServerTest >> testDidOpen [

	self addMyScriptDocument.
	self
		assert: (server context textItem: 'src/myScript.st') class
		equals: PLSScriptDocument
]
