Class {
	#name : #TextDocumentEdit,
	#superclass : #Object,
	#instVars : [
		'textDocument',
		'edits'
	],
	#category : #'PharoLanguageServer-Structure-TextDocument'
}

{ #category : #accessing }
TextDocumentEdit >> asJRPCJSON [

	^ {
		  (#edits -> self edits asJRPCJSON).
		  (#textDocument -> self textDocument asJRPCJSON) } asDictionary
]

{ #category : #accessing }
TextDocumentEdit >> edits [

	^ edits
]

{ #category : #accessing }
TextDocumentEdit >> edits: anObject [

	edits := anObject
]

{ #category : #accessing }
TextDocumentEdit >> textDocument [

	^ textDocument
]

{ #category : #accessing }
TextDocumentEdit >> textDocument: anObject [

	textDocument := anObject
]
