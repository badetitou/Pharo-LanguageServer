Class {
	#name : #PLSDocument,
	#superclass : #Object,
	#instVars : [
		'version',
		'text',
		'languageId',
		'uri'
	],
	#category : #'PharoLanguageServer-Document'
}

{ #category : #'instance creation' }
PLSDocument class >> from: aTextDocument [
	"return a script document or a tonel document with the built from the textDocument dictionary"

	^ (self isTonelDocument: aTextDocument)
		ifTrue: [ PLSTonelDocument fromDocumentDictionary: aTextDocument ]
		ifFalse: [ PLSScriptDocument fromDocumentDictionary: aTextDocument ]
]

{ #category : #'instance creation' }
PLSDocument class >> fromDocumentDictionary: aDocumentDictionary [
	self subclassResponsibility
]

{ #category : #'instance creation' }
PLSDocument class >> fromURI: aTextDocumentURI [
	"this is a backup solution"

	^ (self isURIFromTonelDocument: aTextDocumentURI)
		ifTrue: [ PLSTonelDocument new uri: aTextDocumentURI; yourself ]
		ifFalse: [ PLSScriptDocument new uri: aTextDocumentURI; yourself ]
]

{ #category : #'instance creation' }
PLSDocument class >> isTonelDocument: textDocument [
	^ ((textDocument at: #uri) endsWith: 'class.st') or: [ (textDocument at: #uri) endsWith: 'extension.st' ]
]

{ #category : #'instance creation' }
PLSDocument class >> isURIFromTonelDocument: textDocumentURI [
	^ (textDocumentURI endsWith: 'class.st')
		or: [ textDocumentURI endsWith: 'extension.st' ]
]

{ #category : #'lsp - accessing' }
PLSDocument >> codeLens [
	^ {}
]

{ #category : #testing }
PLSDocument >> isScriptDocument [
	^ false
]

{ #category : #testing }
PLSDocument >> isTonelDocument [
	^ false
]

{ #category : #accessing }
PLSDocument >> languageId [
	^ languageId
]

{ #category : #accessing }
PLSDocument >> languageId: anObject [
	languageId := anObject
]

{ #category : #'lsp - accessing' }
PLSDocument >> nodeAt: aPosition [
	self subclassResponsibility 
]

{ #category : #'lsp - accessing' }
PLSDocument >> symbols [
	^ {}
]

{ #category : #accessing }
PLSDocument >> text [
	^ text
]

{ #category : #accessing }
PLSDocument >> text: anObject [
	text := anObject
]

{ #category : #accessing }
PLSDocument >> uri [
	^ uri
]

{ #category : #accessing }
PLSDocument >> uri: anObject [
	uri := anObject
]

{ #category : #accessing }
PLSDocument >> version [
	^ version
]

{ #category : #accessing }
PLSDocument >> version: anObject [
	version := anObject
]
