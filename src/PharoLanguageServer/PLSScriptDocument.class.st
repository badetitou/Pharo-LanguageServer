Class {
	#name : #PLSScriptDocument,
	#superclass : #PLSDocument,
	#category : #'PharoLanguageServer-Document'
}

{ #category : #'instance creation' }
PLSScriptDocument class >> fromDocumentDictionary: aDocumentDictionary [
	^ self new
		version: (aDocumentDictionary at: #version);
		text: (aDocumentDictionary at: #text);
		languageId: (aDocumentDictionary at: #languageId);
		uri: (aDocumentDictionary at: #uri);
		yourself
]

{ #category : #testing }
PLSScriptDocument >> isScriptDocument [
	^ true
]

{ #category : #'lsp - accessing' }
PLSScriptDocument >> nodeAt: aPosition [
	| positionChar |
	positionChar := self text plsToPosition: aPosition.
	^ (RBParser parseFaultyExpression: self text)
		bestNodeFor: (Interval from: positionChar to: positionChar)
]
