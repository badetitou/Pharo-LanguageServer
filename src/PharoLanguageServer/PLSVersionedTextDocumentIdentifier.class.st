Class {
	#name : #PLSVersionedTextDocumentIdentifier,
	#superclass : #PLSTextDocumentIdentifier,
	#instVars : [
		'version'
	],
	#category : 'PharoLanguageServer-Structure-TextDocument'
}

{ #category : #accessing }
PLSVersionedTextDocumentIdentifier >> asJRPCJSON [

	| dic |
	dic := super asJRPCJSON.
	self version ifNotNil: [ :ver | dic at: #version put: ver asJRPCJSON ].
	^ dic
]

{ #category : #accessing }
PLSVersionedTextDocumentIdentifier >> version [

	^ version
]

{ #category : #accessing }
PLSVersionedTextDocumentIdentifier >> version: anObject [

	version := anObject
]
