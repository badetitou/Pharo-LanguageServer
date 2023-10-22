Class {
	#name : #PLPTextDocumentClientCapabilities,
	#superclass : #Object,
	#instVars : [
		'synchronization',
		'completion',
		'hover',
		'signatureHelp',
		'declaration',
		'typeDefinition',
		'implementation',
		'references',
		'documentHighlight',
		'documentSymbol',
		'codeAction',
		'codeLens',
		'documentLink',
		'colorProvider',
		'formatting',
		'rangeFormatting',
		'onTypeFormatting',
		'rename',
		'publishDiagnostics',
		'foldingRange',
		'selectionRange',
		'linkedEditingRange',
		'callHierarchy',
		'semanticTokens',
		'moniker',
		'typeHierarchy',
		'inlineValue',
		'inlayHint',
		'diagnostic',
		'inlineCompletion'
	],
	#category : #'PharoLanguageProtocol-Initialize'
}

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> asJRPCJSON [

	| dic |
	dic := Dictionary new.
	self callHierarchy ifNotNil: [ :el | 
		dic at: #callHierarchy put: el asJRPCJSON ].
	self codeAction ifNotNil: [ :el | 
		dic at: #codeAction put: el asJRPCJSON ].
	self codeLens ifNotNil: [ :el | dic at: #codeLens put: el asJRPCJSON ].
	self colorProvider ifNotNil: [ :el | 
		dic at: #colorProvider put: el asJRPCJSON ].
	self completion ifNotNil: [ :el | 
		dic at: #completion put: el asJRPCJSON ].
	self declaration ifNotNil: [ :el | 
		dic at: #declaration put: el asJRPCJSON ].
	self diagnostic ifNotNil: [ :el | 
		dic at: #diagnostic put: el asJRPCJSON ].
	self documentHighlight ifNotNil: [ :el | 
		dic at: #documentHighlight put: el asJRPCJSON ].
	self documentLink ifNotNil: [ :el | 
		dic at: #documentLink put: el asJRPCJSON ].
	self documentSymbol ifNotNil: [ :el | 
		dic at: #documentSymbol put: el asJRPCJSON ].
	self foldingRange ifNotNil: [ :el | 
		dic at: #foldingRange put: el asJRPCJSON ].
	self formatting ifNotNil: [ :el | 
		dic at: #formatting put: el asJRPCJSON ].
	self hover ifNotNil: [ :el | dic at: #hover put: el asJRPCJSON ].
	self implementation ifNotNil: [ :el | 
		dic at: #implementation put: el asJRPCJSON ].
	self inlayHint ifNotNil: [ :el | 
		dic at: #inlayHint put: el asJRPCJSON ].
	self inlineCompletion ifNotNil: [ :el | 
		dic at: #inlineCompletion put: el asJRPCJSON ].
	self inlineValue ifNotNil: [ :el | 
		dic at: #inlineValue put: el asJRPCJSON ].
	self linkedEditingRange ifNotNil: [ :el | 
		dic at: #linkedEditingRange put: el asJRPCJSON ].
	self moniker ifNotNil: [ :el | dic at: #moniker put: el asJRPCJSON ].
	self onTypeFormatting ifNotNil: [ :el | 
		dic at: #onTypeFormatting put: el asJRPCJSON ].
	self publishDiagnostics ifNotNil: [ :el | 
		dic at: #publishDiagnostics put: el asJRPCJSON ].
	self rangeFormatting ifNotNil: [ :el | 
		dic at: #rangeFormatting put: el asJRPCJSON ].
	self references ifNotNil: [ :el | 
		dic at: #references put: el asJRPCJSON ].
	self rename ifNotNil: [ :el | dic at: #rename put: el asJRPCJSON ].
	self selectionRange ifNotNil: [ :el | 
		dic at: #selectionRange put: el asJRPCJSON ].
	self semanticTokens ifNotNil: [ :el | 
		dic at: #semanticTokens put: el asJRPCJSON ].
	self signatureHelp ifNotNil: [ :el | 
		dic at: #signatureHelp put: el asJRPCJSON ].
	self synchronization ifNotNil: [ :el | 
		dic at: #synchronization put: el asJRPCJSON ].
	self typeDefinition ifNotNil: [ :el | 
		dic at: #typeDefinition put: el asJRPCJSON ].
	self typeHierarchy ifNotNil: [ :el | 
		dic at: #typeHierarchy put: el asJRPCJSON ].

	^ dic
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> callHierarchy [

	^ callHierarchy
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> callHierarchy: anObject [

	callHierarchy := anObject
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> codeAction [

	^ codeAction
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> codeAction: anObject [

	codeAction := anObject
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> codeLens [

	^ codeLens
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> codeLens: anObject [

	codeLens := anObject
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> colorProvider [

	^ colorProvider
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> colorProvider: anObject [

	colorProvider := anObject
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> completion [

	^ completion
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> completion: anObject [

	completion := anObject
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> declaration [

	^ declaration
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> declaration: anObject [

	declaration := anObject
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> diagnostic [

	^ diagnostic
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> diagnostic: anObject [

	diagnostic := anObject
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> documentHighlight [

	^ documentHighlight
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> documentHighlight: anObject [

	documentHighlight := anObject
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> documentLink [

	^ documentLink
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> documentLink: anObject [

	documentLink := anObject
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> documentSymbol [

	^ documentSymbol
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> documentSymbol: anObject [

	documentSymbol := anObject
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> foldingRange [

	^ foldingRange
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> foldingRange: anObject [

	foldingRange := anObject
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> formatting [

	^ formatting
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> formatting: anObject [

	formatting := anObject
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> hover [

	^ hover
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> hover: anObject [

	hover := anObject
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> implementation [

	^ implementation
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> implementation: anObject [

	implementation := anObject
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> inlayHint [

	^ inlayHint
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> inlayHint: anObject [

	inlayHint := anObject
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> inlineCompletion [

	^ inlineCompletion
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> inlineCompletion: anObject [

	inlineCompletion := anObject
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> inlineValue [

	^ inlineValue
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> inlineValue: anObject [

	inlineValue := anObject
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> linkedEditingRange [

	^ linkedEditingRange
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> linkedEditingRange: anObject [

	linkedEditingRange := anObject
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> moniker [

	^ moniker
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> moniker: anObject [

	moniker := anObject
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> onTypeFormatting [

	^ onTypeFormatting
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> onTypeFormatting: anObject [

	onTypeFormatting := anObject
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> publishDiagnostics [

	^ publishDiagnostics
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> publishDiagnostics: anObject [

	publishDiagnostics := anObject
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> rangeFormatting [

	^ rangeFormatting
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> rangeFormatting: anObject [

	rangeFormatting := anObject
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> references [

	^ references
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> references: anObject [

	references := anObject
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> rename [

	^ rename
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> rename: anObject [

	rename := anObject
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> selectionRange [

	^ selectionRange
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> selectionRange: anObject [

	selectionRange := anObject
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> semanticTokens [

	^ semanticTokens
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> semanticTokens: anObject [

	semanticTokens := anObject
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> signatureHelp [

	^ signatureHelp
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> signatureHelp: anObject [

	signatureHelp := anObject
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> synchronization [

	^ synchronization
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> synchronization: anObject [

	synchronization := anObject
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> typeDefinition [

	^ typeDefinition
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> typeDefinition: anObject [

	typeDefinition := anObject
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> typeHierarchy [

	^ typeHierarchy
]

{ #category : #accessing }
PLPTextDocumentClientCapabilities >> typeHierarchy: anObject [

	typeHierarchy := anObject
]
