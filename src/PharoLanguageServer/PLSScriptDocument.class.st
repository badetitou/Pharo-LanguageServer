Class {
	#name : 'PLSScriptDocument',
	#superclass : 'PLSDocument',
	#category : 'PharoLanguageServer-Document',
	#package : 'PharoLanguageServer',
	#tag : 'Document'
}

{ #category : 'testing' }
PLSScriptDocument class >> supportDocument: aTextDocument [
	"I will be default one"

	^ ((aTextDocument at: #uri) endsWith: '.st') and: [
			  (PLSTonelDocument supportDocument: aTextDocument) not and: [
				  (PLSMethodDocument supportDocument: aTextDocument) not ] ]
]

{ #category : 'testing' }
PLSScriptDocument class >> supportDocumentUri: aTextDocumentUri [
	"I am the default one"

	^ (aTextDocumentUri endsWith: '.st') and: [
			  (PLSTonelDocument supportDocumentUri: aTextDocumentUri) not and: [
				  (PLSMethodDocument supportDocumentUri: aTextDocumentUri) not ] ]
]

{ #category : 'diagnostics' }
PLSScriptDocument >> diagnostics [

	(self text isNil or: [ self text isEmpty ]) ifTrue: [
		^ {  } asArray asJRPCJSON ].
	^ ((PLSDiagnosticsParamsEngine document: self) requestor: self binder)
		  computeDiagnostics asArray asJRPCJSON
]

{ #category : 'lsp - accessing' }
PLSScriptDocument >> nodeAt: aPosition [
	| positionChar |
	positionChar := self text plsToPosition: aPosition.
	^ (RBParser parseFaultyExpression: self text)
		bestNodeFor: (Interval from: positionChar to: positionChar)
]
