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
	self window ifNotNil: [ :el | dic at: #window put: el asJRPCJSON ].
	self workspace ifNotNil: [ :el | 
		dic at: #workspace put: el asJRPCJSON ].
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
