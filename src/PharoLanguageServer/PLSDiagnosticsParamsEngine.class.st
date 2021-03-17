Class {
	#name : #PLSDiagnosticsParamsEngine,
	#superclass : #Object,
	#instVars : [
		'document'
	],
	#category : #'PharoLanguageServer-Structure-Diagnostic'
}

{ #category : #accessing }
PLSDiagnosticsParamsEngine class >> document: aDocument [
	"Document is aDictionary with uri, version, and sourceCode"

	^ self new
		document: aDocument;
		yourself
]

{ #category : #accessing }
PLSDiagnosticsParamsEngine >> computeDiagnostics [
	| ast diagnostics |
	ast := self class compiler
		source: (document at: 'text');
		noPattern: false;
		options: #(+ optionParseErrors + optionSkipSemanticWarnings);
		parse.
	diagnostics := OrderedCollection new.
	ast acceptVisitor: (RBParseErrorNodeVisitor new
		visitBlock:
			[ :aErrorBlock | 
			diagnostics
				add:
					(PLSDiagnostic new
						message: aErrorBlock errorMessage;
						range: (PLSRange start: aErrorBlock start end: aErrorBlock stop)) ]).
	^ PLSPublishDiagnosticsParams new
		diagnostics: diagnostics;
		uri: (document at: 'uri');
		version: (document at: 'version');
		yourself 
]

{ #category : #accessing }
PLSDiagnosticsParamsEngine >> document [
	^ document
]

{ #category : #accessing }
PLSDiagnosticsParamsEngine >> document: anObject [
	document := anObject
]
