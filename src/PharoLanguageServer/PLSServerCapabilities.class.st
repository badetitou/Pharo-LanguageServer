Class {
	#name : #PLSServerCapabilities,
	#superclass : #Object,
	#instVars : [
		'codeLens',
		'completionProvider',
		'documentFormattingProvider',
		'documentSymbolProvider',
		'hoverProvider',
		'signatureHelp',
		'textDocumentSync',
		'typeDefinitionOptions',
		'codeActionProvider',
		'diagnosticProvider',
		'inlineCompletionProvider'
	],
	#category : #'PharoLanguageServer-Structure-Capabilities'
}

{ #category : #public }
PLSServerCapabilities class >> forPharo [

	^ self new
		  codeLens: PLSCodeLensOptions new;
		  completionProvider: PLSCompletionOptions new;
		  documentFormattingProvider: PLSDocumentFormattingOptions new;
		  documentSymbolProvider: PLSDocumentSymbolOptions new;
		  hoverProvider: PLSHoverOptions new;
		  signatureHelp: (PLSSignatureHelpClientCapabilities new
				   triggerCharacters: ':';
				   retriggerCharacters: ':';
				   yourself);
		  textDocumentSync: (PLSTextDocumentSyncOptions new
				   openClose: true;
				   willSave: false;
				   save: { (#includeText -> true) } asDictionary;
				   willSaveWaitUntil: false;
				   change: PLSTextDocumentSyncKind full;
				   yourself);
		  typeDefinitionOptions: PLSTypeDefinitionOptions new;
		  yourself
]

{ #category : #converting }
PLSServerCapabilities >> asJRPCJSON [

	| dic |
	dic := Dictionary new.
	self completionProvider ifNotNil: [ 
		dic at: #completionProvider put: self completionProvider asJRPCJSON ].
	self textDocumentSync ifNotNil: [ 
		dic at: #textDocumentSync put: self textDocumentSync asJRPCJSON ].
	self hoverProvider ifNotNil: [ 
		dic at: #hoverProvider put: self hoverProvider asJRPCJSON ].
	self documentFormattingProvider ifNotNil: [ 
		dic
			at: #documentFormattingProvider
			put: self documentFormattingProvider asJRPCJSON ].
	self signatureHelp ifNotNil: [ 
		dic at: #signatureHelpProvider put: self signatureHelp asJRPCJSON ].
	self codeLens ifNotNil: [ 
		dic at: #codeLensProvider put: self codeLens asJRPCJSON ].
	self typeDefinitionOptions ifNotNil: [ 
		dic
			at: #typeDefinitionProvider
			put: self typeDefinitionOptions asJRPCJSON ].
	self documentSymbolProvider ifNotNil: [ 
		dic
			at: #documentSymbolProvider
			put: self documentSymbolProvider asJRPCJSON ].
	self codeActionProvider ifNotNil: [ 
		dic at: #codeActionProvider put: self codeActionProvider asJRPCJSON ].
	self diagnosticProvider ifNotNil: [ 
		dic at: #diagnosticProvider put: self diagnosticProvider asJRPCJSON ].
	^ dic
]

{ #category : #accessing }
PLSServerCapabilities >> codeActionProvider [

	^ codeActionProvider
]

{ #category : #accessing }
PLSServerCapabilities >> codeActionProvider: anObject [

	codeActionProvider := anObject
]

{ #category : #'as yet unclassified' }
PLSServerCapabilities >> codeLens [

	^ codeLens
]

{ #category : #accessing }
PLSServerCapabilities >> codeLens: anObject [

	codeLens := anObject
]

{ #category : #'as yet unclassified' }
PLSServerCapabilities >> completionProvider [

	^ completionProvider
]

{ #category : #accessing }
PLSServerCapabilities >> completionProvider: anObject [

	completionProvider := anObject
]

{ #category : #accessing }
PLSServerCapabilities >> diagnosticProvider [

	^ diagnosticProvider
]

{ #category : #accessing }
PLSServerCapabilities >> diagnosticProvider: anObject [

	diagnosticProvider := anObject
]

{ #category : #converting }
PLSServerCapabilities >> documentFormattingProvider [

	^ documentFormattingProvider
]

{ #category : #accessing }
PLSServerCapabilities >> documentFormattingProvider: anObject [

	documentFormattingProvider := anObject
]

{ #category : #converting }
PLSServerCapabilities >> documentSymbolProvider [

	^ documentSymbolProvider
]

{ #category : #accessing }
PLSServerCapabilities >> documentSymbolProvider: anObject [

	documentSymbolProvider := anObject
]

{ #category : #converting }
PLSServerCapabilities >> hoverProvider [

	^ hoverProvider
]

{ #category : #accessing }
PLSServerCapabilities >> hoverProvider: anObject [

	hoverProvider := anObject
]

{ #category : #accessing }
PLSServerCapabilities >> inlineCompletionProvider [

	^ inlineCompletionProvider
]

{ #category : #accessing }
PLSServerCapabilities >> inlineCompletionProvider: anObject [

	inlineCompletionProvider := anObject
]

{ #category : #'as yet unclassified' }
PLSServerCapabilities >> signatureHelp [

	^ signatureHelp
]

{ #category : #accessing }
PLSServerCapabilities >> signatureHelp: anObject [

	signatureHelp := anObject
]

{ #category : #converting }
PLSServerCapabilities >> textDocumentSync [

	^ textDocumentSync
]

{ #category : #accessing }
PLSServerCapabilities >> textDocumentSync: anObject [

	textDocumentSync := anObject
]

{ #category : #converting }
PLSServerCapabilities >> typeDefinitionOptions [

	^ typeDefinitionOptions
]

{ #category : #accessing }
PLSServerCapabilities >> typeDefinitionOptions: anObject [

	typeDefinitionOptions := anObject
]
