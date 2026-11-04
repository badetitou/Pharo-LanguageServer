Class {
	#name : 'PLSServerCapabilities',
	#superclass : 'Object',
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
		'inlineCompletionProvider',
		'experimental',
		'workspaceSymbolProvider',
		'referencesProvider',
		'implementationProvider',
		'callHierarchyProvider',
		'typeHierarchyProvider',
		'executeCommandProvider'
	],
	#category : 'PharoLanguageServer-Structure-Capabilities',
	#package : 'PharoLanguageServer',
	#tag : 'Structure-Capabilities'
}

{ #category : 'public' }
PLSServerCapabilities class >> forPharo [

	^ self new
		  codeLens: PLSCodeLensOptions new;
		  completionProvider: PLSCompletionOptions new;
		  documentFormattingProvider: PLSDocumentFormattingOptions new;
		  documentSymbolProvider: PLSDocumentSymbolOptions new;
		  hoverProvider: PLSHoverOptions new;
		  codeActionProvider: (PLSCodeActionOptions new
				   codeActionKinds: { PLSCodeActionKind quickfix };
				   yourself);
		  executeCommandProvider:
			  { (#commands -> { PLSServer critiquesBanCommand }) } asDictionary;
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
		  diagnosticProvider: (PLSDiagnosticOptions new
				   identifier: 'Pharo Language Server';
				   interFileDependencies: true;
				   workspaceDiagnostics: false;
				   yourself) asJRPCJSON;
		  typeDefinitionOptions: PLSTypeDefinitionOptions new;
		  workspaceSymbolProvider: true;
		  referencesProvider: true;
		  implementationProvider: true;
		  callHierarchyProvider: true;
		  typeHierarchyProvider: true;
		  experimental: {
				  (#'pls-env' -> {
					   (#version -> 1).
					   (#didChange -> true).
					   (#edit -> true).
					   (#search -> true).
					   (#history -> true).
					   (#loadProject -> true) } asDictionary).
				  (#'pls-playground' -> {
					   (#version -> 1).
					   (#transcript -> true).
					   (#resetBindings -> true).
					   (#inspectIt -> true) } asDictionary).
				  (#'pls-inspector' -> { (#version -> 1) } asDictionary).
				  (#'pls-system' -> {
					   (#version -> 1).
					   (#processes -> true).
					   (#profile -> true).
					   (#chest -> true) } asDictionary) } asDictionary;
		  yourself
]

{ #category : 'converting' }
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
	self inlineCompletionProvider ifNotNil: [
			dic
				at: #inlineCompletionProvider
				put: self inlineCompletionProvider asJRPCJSON ].
	self workspaceSymbolProvider ifNotNil: [
			dic
				at: #workspaceSymbolProvider
				put: self workspaceSymbolProvider asJRPCJSON ].
	self referencesProvider ifNotNil: [
		dic at: #referencesProvider put: self referencesProvider asJRPCJSON ].
	self implementationProvider ifNotNil: [
			dic
				at: #implementationProvider
				put: self implementationProvider asJRPCJSON ].
	self callHierarchyProvider ifNotNil: [
			dic
				at: #callHierarchyProvider
				put: self callHierarchyProvider asJRPCJSON ].
	self typeHierarchyProvider ifNotNil: [
			dic
				at: #typeHierarchyProvider
				put: self typeHierarchyProvider asJRPCJSON ].
	self executeCommandProvider ifNotNil: [
			dic
				at: #executeCommandProvider
				put: self executeCommandProvider asJRPCJSON ].
	self experimental ifNotNil: [
		dic at: #experimental put: self experimental asJRPCJSON ].
	^ dic
]

{ #category : 'accessing' }
PLSServerCapabilities >> callHierarchyProvider [

	^ callHierarchyProvider
]

{ #category : 'accessing' }
PLSServerCapabilities >> callHierarchyProvider: anObject [

	callHierarchyProvider := anObject
]

{ #category : 'accessing' }
PLSServerCapabilities >> codeActionProvider [

	^ codeActionProvider
]

{ #category : 'accessing' }
PLSServerCapabilities >> codeActionProvider: anObject [

	codeActionProvider := anObject
]

{ #category : 'as yet unclassified' }
PLSServerCapabilities >> codeLens [

	^ codeLens
]

{ #category : 'accessing' }
PLSServerCapabilities >> codeLens: anObject [

	codeLens := anObject
]

{ #category : 'as yet unclassified' }
PLSServerCapabilities >> completionProvider [

	^ completionProvider
]

{ #category : 'accessing' }
PLSServerCapabilities >> completionProvider: anObject [

	completionProvider := anObject
]

{ #category : 'accessing' }
PLSServerCapabilities >> diagnosticProvider [

	^ diagnosticProvider
]

{ #category : 'accessing' }
PLSServerCapabilities >> diagnosticProvider: anObject [

	diagnosticProvider := anObject
]

{ #category : 'converting' }
PLSServerCapabilities >> documentFormattingProvider [

	^ documentFormattingProvider
]

{ #category : 'accessing' }
PLSServerCapabilities >> documentFormattingProvider: anObject [

	documentFormattingProvider := anObject
]

{ #category : 'converting' }
PLSServerCapabilities >> documentSymbolProvider [

	^ documentSymbolProvider
]

{ #category : 'accessing' }
PLSServerCapabilities >> documentSymbolProvider: anObject [

	documentSymbolProvider := anObject
]

{ #category : 'accessing' }
PLSServerCapabilities >> executeCommandProvider [

	^ executeCommandProvider
]

{ #category : 'accessing' }
PLSServerCapabilities >> executeCommandProvider: aDictionary [
	"The commands that the client runs through workspace/executeCommand, as { #commands -> anArray }"

	executeCommandProvider := aDictionary
]

{ #category : 'accessing' }
PLSServerCapabilities >> experimental [

	^ experimental
]

{ #category : 'accessing' }
PLSServerCapabilities >> experimental: anObject [

	experimental := anObject
]

{ #category : 'converting' }
PLSServerCapabilities >> hoverProvider [

	^ hoverProvider
]

{ #category : 'accessing' }
PLSServerCapabilities >> hoverProvider: anObject [

	hoverProvider := anObject
]

{ #category : 'accessing' }
PLSServerCapabilities >> implementationProvider [

	^ implementationProvider
]

{ #category : 'accessing' }
PLSServerCapabilities >> implementationProvider: anObject [

	implementationProvider := anObject
]

{ #category : 'accessing' }
PLSServerCapabilities >> inlineCompletionProvider [

	^ inlineCompletionProvider
]

{ #category : 'accessing' }
PLSServerCapabilities >> inlineCompletionProvider: anObject [

	inlineCompletionProvider := anObject
]

{ #category : 'accessing' }
PLSServerCapabilities >> referencesProvider [

	^ referencesProvider
]

{ #category : 'accessing' }
PLSServerCapabilities >> referencesProvider: anObject [

	referencesProvider := anObject
]

{ #category : 'as yet unclassified' }
PLSServerCapabilities >> signatureHelp [

	^ signatureHelp
]

{ #category : 'accessing' }
PLSServerCapabilities >> signatureHelp: anObject [

	signatureHelp := anObject
]

{ #category : 'converting' }
PLSServerCapabilities >> textDocumentSync [

	^ textDocumentSync
]

{ #category : 'accessing' }
PLSServerCapabilities >> textDocumentSync: anObject [

	textDocumentSync := anObject
]

{ #category : 'converting' }
PLSServerCapabilities >> typeDefinitionOptions [

	^ typeDefinitionOptions
]

{ #category : 'accessing' }
PLSServerCapabilities >> typeDefinitionOptions: anObject [

	typeDefinitionOptions := anObject
]

{ #category : 'accessing' }
PLSServerCapabilities >> typeHierarchyProvider [

	^ typeHierarchyProvider
]

{ #category : 'accessing' }
PLSServerCapabilities >> typeHierarchyProvider: anObject [

	typeHierarchyProvider := anObject
]

{ #category : 'accessing' }
PLSServerCapabilities >> workspaceSymbolProvider [

	^ workspaceSymbolProvider
]

{ #category : 'accessing' }
PLSServerCapabilities >> workspaceSymbolProvider: anObject [

	workspaceSymbolProvider := anObject
]
