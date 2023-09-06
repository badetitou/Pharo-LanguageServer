Class {
	#name : #VersionedTextDocumentIdentifier,
	#superclass : #TextDocumentIdentifier,
	#instVars : [
		'version'
	],
	#category : #'PharoLanguageServer-Structure-TextDocument'
}

{ #category : #accessing }
VersionedTextDocumentIdentifier >> version [

	^ version
]

{ #category : #accessing }
VersionedTextDocumentIdentifier >> version: anObject [

	version := anObject
]
