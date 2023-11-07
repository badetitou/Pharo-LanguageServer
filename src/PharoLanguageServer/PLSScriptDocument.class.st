Class {
	#name : #PLSScriptDocument,
	#superclass : #PLSDocument,
	#category : 'PharoLanguageServer-Document'
}

{ #category : #'instance creation' }
PLSScriptDocument class >> fromDocumentDictionary: aDocumentDictionary [

	^ self new
		  version: (aDocumentDictionary at: #version);
		  text: (aDocumentDictionary at: #text ifAbsent: '');
		  languageId: (aDocumentDictionary at: #languageId ifAbsent: '');
		  uri: (aDocumentDictionary at: #uri);
		  yourself
]

{ #category : #'lsp - accessing' }
PLSScriptDocument >> diagnostics [
	^ ((PLSDiagnosticsParamsEngine document: self) requestor: self binder)
		computeDiagnostics asJRPCJSON
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
