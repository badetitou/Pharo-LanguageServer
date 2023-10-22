Class {
	#name : #PLPTextDocumentPositionParams,
	#superclass : #Object,
	#instVars : [
		'textDocument',
		'position'
	],
	#category : #'PharoLanguageProtocol-Completion'
}

{ #category : #converting }
PLPTextDocumentPositionParams >> asJRPCJSON [

	^ { 
		  (#position -> self position asJRPCJSON).
		  (#textDocument -> self textDocument asJRPCJSON) } asDictionary
]

{ #category : #accessing }
PLPTextDocumentPositionParams >> position [

	^ position
]

{ #category : #accessing }
PLPTextDocumentPositionParams >> position: anObject [

	position := anObject
]

{ #category : #accessing }
PLPTextDocumentPositionParams >> textDocument [

	^ textDocument
]

{ #category : #accessing }
PLPTextDocumentPositionParams >> textDocument: anObject [

	textDocument := anObject
]
