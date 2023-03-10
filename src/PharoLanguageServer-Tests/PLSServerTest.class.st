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
	textDocument at: #text put: '1 + 1.
object := Object new'.

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
PLSServerTest >> testCommandPharoPrintItTextDocumentWithVariableCreated [

	| result |
	self addMyScriptDocument.
	result := server
		          commandPharoPrintIt: 'hello := 12'
		          textDocument:
		          { (#path -> 'src/myScript.st') } asDictionary.
	self assert: '12' equals: result.
	result := server
		          commandPharoPrintIt: 'hello'
		          textDocument:
		          { (#path -> 'src/myScript.st') } asDictionary.
	self assert: '12' equals: result
]

{ #category : #test }
PLSServerTest >> testDidClose [

	| textDocument |
	self addMyScriptDocument.

	textDocument := Dictionary new.
	textDocument at: #uri put: 'src/myScript.st'.

	server didClose: textDocument.
	self assert: server context textItems isEmpty
]

{ #category : #test }
PLSServerTest >> testDidOpen [

	self addMyScriptDocument.
	self
		assert: (server context textItem: 'src/myScript.st') class
		equals: PLSScriptDocument
]

{ #category : #test }
PLSServerTest >> testDocumentVariables [

	| result |
	self addMyScriptDocument.
	server
		commandPharoPrintIt: 'hello := 12'
		textDocument: { (#path -> 'src/myScript.st') } asDictionary.
	result := server documentVariables:
		          { (#uri -> { (#path -> 'src/myScript.st') } asDictionary) }
			          asDictionary.
	self assert: result size equals: 2.
	self
		assert:
		((result detect: [ :r | (r at: #name) = '#hello' ]) at: #value)
		equals: '12'.
		self
		assert:
		((result detect: [ :r | (r at: #name) = '#object' ]) at: #value)
		equals: 'nil'
]

{ #category : #test }
PLSServerTest >> testTextDocumentHoverWithPositionTextDocument [

	| result |
	self addMyScriptDocument.
	result := server
		          textDocumentHoverWithPosition: { 
				          (#line -> 1).
				          (#character -> 12) } asDictionary
		          textDocument: { (#uri -> 'src/myScript.st') } asDictionary.
	self assert: (result at: #contents) equals: Object comment.
	"hovering nothing return empty"
	result := server
		          textDocumentHoverWithPosition: { 
				          (#line -> 0).
				          (#character -> 0) } asDictionary
		          textDocument: { (#uri -> 'src/myScript.st') } asDictionary.
	self assert: (result at: #contents) equals: ''
]

{ #category : #test }
PLSServerTest >> testTypeDefinitionAtIn [

	| result |
	self addMyScriptDocument.
	result := server
		          typeDefinitionAt: { 
				          (#line -> 1).
				          (#character -> 12) } asDictionary
		          in: { (#uri -> 'src/myScript.st') } asDictionary.
	self assert: result class equals: PLSLocation.
	self assert: result uri equals: 'pharoImage://Kernel/Object.class.st'.
	self assert: result range class equals: PLSRange.
	self assert: result range start class equals: PLSPosition.
	self assert: result range start character equals: 0.
	self assert: result range start line equals: 0.
	self assert: result range end class equals: PLSPosition.
	self assert: result range end character equals: 0.
	self assert: result range end line equals: 0
]
