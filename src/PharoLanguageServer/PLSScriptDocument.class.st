Class {
	#name : 'PLSScriptDocument',
	#superclass : 'PLSDocument',
	#category : 'PharoLanguageServer-Document',
	#package : 'PharoLanguageServer',
	#tag : 'Document'
}

{ #category : 'as yet unclassified' }
PLSScriptDocument class >> supportDocument: aTextDocument [
	"I will be default one"

	^ (aTextDocument at: #uri) endsWith: '.st'
]

{ #category : 'as yet unclassified' }
PLSScriptDocument class >> supportDocumentUri: aTextDocumentUri [
	"I am the default one"

	^ false
]

{ #category : 'diagnostics' }
PLSScriptDocument >> diagnostics [

	^ ((PLSDiagnosticsParamsEngine document: self) requestor: self binder)
		  computeDiagnostics asArray asJRPCJSON
]

{ #category : 'testing' }
PLSScriptDocument >> isScriptDocument [
	^ true
]

{ #category : 'lsp - accessing' }
PLSScriptDocument >> nodeAt: aPosition [
	| positionChar |
	positionChar := self text plsToPosition: aPosition.
	^ (RBParser parseFaultyExpression: self text)
		bestNodeFor: (Interval from: positionChar to: positionChar)
]
