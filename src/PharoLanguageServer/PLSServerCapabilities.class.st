Class {
	#name : #PLSServerCapabilities,
	#superclass : #Object,
	#category : #'PharoLanguageServer-Structure-Capabilities'
}

{ #category : #converting }
PLSServerCapabilities >> asJRPCJSON [
	^ {(#completionProvider -> self completionProvider asJRPCJSON).
	(#textDocumentSync -> self textDocumentSync asJRPCJSON).
	(#hoverProvider -> self hoverProvider asJRPCJSON).
	(#documentFormattingProvider
		-> self documentFormattingProvider asJRPCJSON).
	(#signatureHelpProvider -> self signatureHelp asJRPCJSON).
	(#codeLensProvider -> self codeLens asJRPCJSON).
	(#typeDefinitionProvider -> self typeDefinitionOptions asJRPCJSON).
	(#documentSymbolProvider -> self documentSymbolProvider asJRPCJSON)} asDictionary
]

{ #category : #'as yet unclassified' }
PLSServerCapabilities >> codeLens [
	^ PLSCodeLensOptions new
]

{ #category : #'as yet unclassified' }
PLSServerCapabilities >> completionProvider [
	^ PLSCompletionOptions new
]

{ #category : #converting }
PLSServerCapabilities >> documentFormattingProvider [
	^ PLSDocumentFormattingOptions new
		
]

{ #category : #converting }
PLSServerCapabilities >> documentSymbolProvider [
	^ PLSDocumentSymbolOptions new
]

{ #category : #converting }
PLSServerCapabilities >> hoverProvider [
	^ PLSHoverOptions new
]

{ #category : #'as yet unclassified' }
PLSServerCapabilities >> signatureHelp [
	^ PLSSignatureHelpClientCapabilities new
		triggerCharacters: ':';
		retriggerCharacters: ':';
		yourself
]

{ #category : #converting }
PLSServerCapabilities >> textDocumentSync [
	^ PLSTextDocumentSyncOptions new
		openClose: true;
		willSave: false;
		save: {(#includeText -> true)} asDictionary;
		willSaveWaitUntil: false;
		change: PLSTextDocumentSyncKind full;
		yourself
]

{ #category : #converting }
PLSServerCapabilities >> typeDefinitionOptions [
	^ PLSTypeDefinitionOptions new
]
