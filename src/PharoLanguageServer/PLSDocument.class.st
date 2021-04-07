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
PLSDocument class >> isTonelDocument: textDocument [
	^ ((textDocument at: #uri) endsWith: 'class.st') or: [ (textDocument at: #uri) endsWith: 'extension.st' ]
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
