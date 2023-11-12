Class {
	#name : #PLCLRubScrolledTextMorph,
	#superclass : #SpRubScrolledTextMorph,
	#classTraits : 'TPLCClient classTrait',
	#instVars : [
		'version'
	],
	#category : #'PharoLanguageClientLocal-GraphicalStack'
}

{ #category : #accessing }
PLCLRubScrolledTextMorph >> beForSmalltalkScripting [

	self textArea beForSmalltalkScripting.
	self textArea shoutStyler styler: PLCLTextStyler new.
	self textArea font: StandardFonts codeFont
]

{ #category : #'lsp - completion' }
PLCLRubScrolledTextMorph >> resetInlineCompletion [

	self textArea updateTextWith: self textWithoutGhost
]

{ #category : #'lsp - completion' }
PLCLRubScrolledTextMorph >> setInlineCompletionWith: aText [

	self updateTextWith: (self textWithoutGhost append: (aText asText
				  addAttribute: TextGhost new;
				  yourself))
]

{ #category : #'lsp - completion' }
PLCLRubScrolledTextMorph >> textWithoutGhost [

	^ self getText withIndexSelect: [ :val :idx |
		  (self getText runs at: idx) noneSatisfy: [ :run |
			  run isKindOf: TextGhost ] ]
]
