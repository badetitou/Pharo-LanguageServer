Class {
	#name : #SpMorphicPLCCodeAdapter,
	#superclass : #SpMorphicCodeAdapter,
	#instVars : [
		'version'
	],
	#category : #'PharoLanguageClientLocal-GraphicalStack'
}

{ #category : #factory }
SpMorphicPLCCodeAdapter >> buildWidget [
	| newWidget |
	
	newWidget := (PLCLRubScrolledTextMorph on: self)
		getTextSelector: #getText;
		setTextSelector: #accept:notifying:;
		getSelectionSelector: #readSelection;
		menuProvider: self selector: #codePaneMenu:shifted:;
		setSelectionSelector: #setSelection:;
		ghostText: self placeholder;
		beWrapped;
		askBeforeDiscardingEdits: self askBeforeDiscardingEdits;
		autoAccept: true;
		vResizing: #spaceFill;
		hResizing: #spaceFill;
		setBalloonText: self help;
		dragEnabled: self dragEnabled;
		dropEnabled: self dropEnabled;
		registerScrollChanges: #scrollValueChanged:;
		hScrollbarShowWhenNeeded;
		yourself.

	self setEnabled: self presenter isEnabled to: newWidget.	
	self setEditable: self presenter isEditable to: newWidget.
	self setEditingModeFor: newWidget.
	self setText: self presenter text to: newWidget.
	self presenter selectionInterval 
		ifNotNil: [  :anInterval | self selectionInterval: anInterval on: newWidget ].

	self setWrapWord: self presenter isWrapWord to: newWidget.	
	self setUndoRedo: self presenter hasUndoRedoHistory to: newWidget. 
	self presenter whenTextChangedDo: [ :text | 
		self setText: text to: newWidget ].
	self presenter whenSelectionChangedDo: [ :selectionInterval | 
		self selectionInterval: selectionInterval ].
	self presenter whenPlaceholderChangedDo: [ :text | 
		self setGhostText: text to: newWidget ].
	self presenter whenEditableChangedDo: [ :value | 
		self setEditable: value to: newWidget ].
	self presenter whenWrapWordChangedDo: [ :value | 
		self setWrapWord: value to: newWidget ].
	
	
	self presenter hasLineNumbers ifTrue: [ 
		newWidget withLineNumbers ].
	self presenter interactionModel ifNotNil: [ :im | 
		self setInteractionModel: im to: newWidget ].
	self presenter whenLineNumbersChangedDo: [ :hasLineNumbers | 
		self changeLineNumbers: hasLineNumbers to: newWidget ].
	self presenter whenSyntaxHighlightChangedDo: [ :hasSyntaxHighlight | 
		self setEditingModeFor: newWidget ].
	self presenter whenSmartCharactersChangedDo: [ :hasSmartCharacters | 
		self setSmartCharactersFor: newWidget ].
	
	self presenter syntaxHighlightTheme ifNotNil: [ 
		self setSyntaxHighlightThemeFor: newWidget ].
	self presenter whenSyntaxHighlightThemeChangedDo: [ :value |
		self setSyntaxHighlightThemeFor: newWidget ].
	
	^ newWidget
]

{ #category : #'*PharoLanguageClientLocal' }
SpMorphicPLCCodeAdapter >> resetInlineCompletion [

	self widget resetInlineCompletion
]

{ #category : #'*PharoLanguageClientLocal' }
SpMorphicPLCCodeAdapter >> setInlineCompletionWith: aText [

	self widget setInlineCompletionWith: aText
]
