Class {
	#name : #PLSTextDocumentClientCapabilities,
	#superclass : #Object,
	#instVars : [
		'completion',
		'hover',
		'signatureHelp',
		'declaration',
		'definition',
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
		'diagnostic'
	],
	#category : #'PharoLanguageServer-Structure-Capabilities'
}

{ #category : #'instance creation' }
PLSTextDocumentClientCapabilities class >> from: aDictionary [

	| instance |
	instance := self new.
	aDictionary
		at: #completion
		ifPresent: [ :completion | instance completion: completion ].
	aDictionary at: #hover ifPresent: [ :hover | instance hover: hover ].
	aDictionary
		at: #signatureHelp
		ifPresent: [ :signatureHelp | instance signatureHelp: signatureHelp ].
	aDictionary
		at: #declaration
		ifPresent: [ :declaration | instance declaration: declaration ].
	aDictionary
		at: #definition
		ifPresent: [ :definition | instance definition: definition ].
	aDictionary
		at: #typeDefinition
		ifPresent: [ :typeDefinition | 
		instance typeDefinition: typeDefinition ].
	aDictionary
		at: #implementation
		ifPresent: [ :implementation | 
		instance implementation: implementation ].
	aDictionary
		at: #references
		ifPresent: [ :references | instance references: references ].
	aDictionary
		at: #documentHighlight
		ifPresent: [ :documentHighlight | 
		instance documentHighlight: documentHighlight ].
	aDictionary
		at: #documentSymbol
		ifPresent: [ :documentSymbol | 
		instance documentSymbol: documentSymbol ].
	aDictionary
		at: #codeAction
		ifPresent: [ :codeAction | instance codeAction: codeAction ].
	aDictionary
		at: #codeLens
		ifPresent: [ :codeLens | instance codeLens: codeLens ].
	aDictionary
		at: #documentLink
		ifPresent: [ :documentLink | instance documentLink: documentLink ].
	aDictionary
		at: #colorProvider
		ifPresent: [ :colorProvider | instance colorProvider: colorProvider ].
	aDictionary
		at: #formatting
		ifPresent: [ :formatting | instance formatting: formatting ].
	aDictionary
		at: #rangeFormatting
		ifPresent: [ :rangeFormatting | 
		instance rangeFormatting: rangeFormatting ].
	aDictionary
		at: #onTypeFormatting
		ifPresent: [ :onTypeFormatting | 
		instance onTypeFormatting: onTypeFormatting ].
	aDictionary
		at: #rename
		ifPresent: [ :rename | instance rename: rename ].
	aDictionary
		at: #publishDiagnostics
		ifPresent: [ :publishDiagnostics | 
			instance publishDiagnostics: publishDiagnostics ].
	aDictionary
		at: #foldingRange
		ifPresent: [ :foldingRange | instance foldingRange: foldingRange ].
	aDictionary
		at: #selectionRange
		ifPresent: [ :selectionRange | 
		instance selectionRange: selectionRange ].
	aDictionary
		at: #linkedEditingRange
		ifPresent: [ :linkedEditingRange | 
			instance linkedEditingRange: linkedEditingRange ].
	aDictionary
		at: #callHierarchy
		ifPresent: [ :callHierarchy | instance callHierarchy: callHierarchy ].
	aDictionary
		at: #semanticTokens
		ifPresent: [ :semanticTokens | 
		instance semanticTokens: semanticTokens ].
	aDictionary
		at: #moniker
		ifPresent: [ :moniker | instance moniker: moniker ].
	aDictionary
		at: #typeHierarchy
		ifPresent: [ :typeHierarchy | instance typeHierarchy: typeHierarchy ].
	aDictionary
		at: #inlineValue
		ifPresent: [ :inlineValue | instance inlineValue: inlineValue ].
	aDictionary
		at: #inlayHint
		ifPresent: [ :inlayHint | instance inlayHint: inlayHint ].
	aDictionary
		at: #diagnostic
		ifPresent: [ :diagnostic | instance diagnostic: diagnostic ]
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> callHierarchy [

	^ callHierarchy
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> callHierarchy: anObject [

	callHierarchy := anObject
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> codeAction [

	^ codeAction
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> codeAction: anObject [

	codeAction := anObject
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> codeLens [

	^ codeLens
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> codeLens: anObject [

	codeLens := anObject
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> colorProvider [

	^ colorProvider
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> colorProvider: anObject [

	colorProvider := anObject
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> completion [

	^ completion
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> completion: anObject [

	completion := anObject
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> declaration [

	^ declaration
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> declaration: anObject [

	declaration := anObject
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> definition [

	^ definition
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> definition: anObject [

	definition := anObject
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> diagnostic [

	^ diagnostic
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> diagnostic: anObject [

	diagnostic := anObject
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> documentHighlight [

	^ documentHighlight
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> documentHighlight: anObject [

	documentHighlight := anObject
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> documentLink [

	^ documentLink
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> documentLink: anObject [

	documentLink := anObject
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> documentSymbol [

	^ documentSymbol
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> documentSymbol: anObject [

	documentSymbol := anObject
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> foldingRange [

	^ foldingRange
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> foldingRange: anObject [

	foldingRange := anObject
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> formatting [

	^ formatting
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> formatting: anObject [

	formatting := anObject
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> hover [

	^ hover
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> hover: anObject [

	hover := anObject
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> implementation [

	^ implementation
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> implementation: anObject [

	implementation := anObject
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> inlayHint [

	^ inlayHint
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> inlayHint: anObject [

	inlayHint := anObject
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> inlineValue [

	^ inlineValue
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> inlineValue: anObject [

	inlineValue := anObject
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> linkedEditingRange [

	^ linkedEditingRange
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> linkedEditingRange: anObject [

	linkedEditingRange := anObject
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> moniker [

	^ moniker
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> moniker: anObject [

	moniker := anObject
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> onTypeFormatting [

	^ onTypeFormatting
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> onTypeFormatting: anObject [

	onTypeFormatting := anObject
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> publishDiagnostics [

	^ publishDiagnostics
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> publishDiagnostics: anObject [

	publishDiagnostics := anObject
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> rangeFormatting [

	^ rangeFormatting
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> rangeFormatting: anObject [

	rangeFormatting := anObject
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> references [

	^ references
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> references: anObject [

	references := anObject
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> rename [

	^ rename
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> rename: anObject [

	rename := anObject
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> selectionRange [

	^ selectionRange
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> selectionRange: anObject [

	selectionRange := anObject
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> semanticTokens [

	^ semanticTokens
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> semanticTokens: anObject [

	semanticTokens := anObject
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> signatureHelp [

	^ signatureHelp
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> signatureHelp: anObject [

	signatureHelp := anObject
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> typeDefinition [

	^ typeDefinition
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> typeDefinition: anObject [

	typeDefinition := anObject
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> typeHierarchy [

	^ typeHierarchy
]

{ #category : #accessing }
PLSTextDocumentClientCapabilities >> typeHierarchy: anObject [

	typeHierarchy := anObject
]
