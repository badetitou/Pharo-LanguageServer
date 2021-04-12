"
Represents programming constructs like variables, classes, interfaces *etc.* that appear in a document.
Document symbols can be hierarchical and they have two ranges: one that encloses its definition and one that points to its most interesting range, *e.g.* the range of an identifier.
"
Class {
	#name : #PLSDocumentSymbol,
	#superclass : #Object,
	#instVars : [
		'name',
		'detail',
		'kind',
		'tags',
		'range',
		'selectionRange',
		'children'
	],
	#category : #'PharoLanguageServer-Structure-Symbols'
}

{ #category : #converting }
PLSDocumentSymbol >> asJRPCJSON [
	| dic |
	dic := {(#name -> self name asJRPCJSON).
	(#kind -> self kind asJRPCJSON).
	(#range -> self range asJRPCJSON).
	(#selectionRange -> self selectionRange asJRPCJSON)} asDictionary.
	self detail ifNotNil: [ dic at: #detail put: self detail asJRPCJSON ].
	self tags ifNotNil: [ dic at: #tags put: self tags asJRPCJSON ].
	self children
		ifNotNil: [ dic at: #children put: self children asJRPCJSON ].
	^ dic
]

{ #category : #accessing }
PLSDocumentSymbol >> children [
	^ children
]

{ #category : #accessing }
PLSDocumentSymbol >> children: anObject [
	children := anObject
]

{ #category : #accessing }
PLSDocumentSymbol >> detail [
	^ detail
]

{ #category : #accessing }
PLSDocumentSymbol >> detail: anObject [
	detail := anObject
]

{ #category : #accessing }
PLSDocumentSymbol >> kind [
	^ kind
]

{ #category : #accessing }
PLSDocumentSymbol >> kind: anObject [
	kind := anObject
]

{ #category : #accessing }
PLSDocumentSymbol >> name [
	^ name
]

{ #category : #accessing }
PLSDocumentSymbol >> name: anObject [
	name := anObject
]

{ #category : #accessing }
PLSDocumentSymbol >> range [
	^ range
]

{ #category : #accessing }
PLSDocumentSymbol >> range: anObject [
	range := anObject
]

{ #category : #accessing }
PLSDocumentSymbol >> selectionRange [
	^ selectionRange
]

{ #category : #accessing }
PLSDocumentSymbol >> selectionRange: anObject [
	selectionRange := anObject
]

{ #category : #accessing }
PLSDocumentSymbol >> tags [
	^ tags
]

{ #category : #accessing }
PLSDocumentSymbol >> tags: anObject [
	tags := anObject
]
