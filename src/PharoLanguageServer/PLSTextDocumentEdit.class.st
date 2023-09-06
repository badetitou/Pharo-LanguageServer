Class {
	#name : #PLSTextDocumentEdit,
	#superclass : #Object,
	#instVars : [
		'textDocument',
		'edits'
	],
	#category : #'PharoLanguageServer-Structure-TextDocument'
}

{ #category : #accessing }
PLSTextDocumentEdit >> asJRPCJSON [

	^ {
		  (#edits -> self edits asJRPCJSON).
		  (#textDocument -> self textDocument asJRPCJSON) } asDictionary
]

{ #category : #accessing }
PLSTextDocumentEdit >> edits [

	^ edits
]

{ #category : #accessing }
PLSTextDocumentEdit >> edits: anObject [

	edits := anObject
]

{ #category : #accessing }
PLSTextDocumentEdit >> textDocument [

	^ textDocument
]

{ #category : #accessing }
PLSTextDocumentEdit >> textDocument: anObject [

	textDocument := anObject
]
