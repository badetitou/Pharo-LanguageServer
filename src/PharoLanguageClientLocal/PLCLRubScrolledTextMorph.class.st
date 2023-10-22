Class {
	#name : #PLCLRubScrolledTextMorph,
	#superclass : #SpRubScrolledTextMorph,
	#traits : 'TPLCClient',
	#classTraits : 'TPLCClient classTrait',
	#category : #PharoLanguageClientLocal
}

{ #category : #'lsp - completion' }
PLCLRubScrolledTextMorph >> clientInlineCompletiongFrom: items [

	<jrpc: #'textDocument/inlineCompletion'>
	self scrollPane setTextWith: (self text append: (items anyOne asText
				  addAttribute: TextGhost new;
				  yourself))
]

{ #category : #'lsp - initialization' }
PLCLRubScrolledTextMorph >> sendInitialize [

	self
		callMethod: 'initialize'
		arguments: (PLPInitializeParams new
				 capabilities: (PLPClientCapabilities new textDocument:
							  (PLPTextDocumentClientCapabilities new
								   inlineCompletion: true;
								   yourself));
				 clientInfo: { 
						 (#name -> 'PLCClient').
						 (#version -> 'beta') } asDictionary;
				 processId: nil;
				 yourself) asJRPCJSON
		withId: self nextId
]

{ #category : #'event handling' }
PLCLRubScrolledTextMorph >> whenTextChangedInTextArea: anAnnouncement [

	| txt |
	super whenTextChangedInTextArea: anAnnouncement.
	txt := self text.
	txt := txt withIndexSelect: [ :val :idx | 
		       (txt runs at: idx) anySatisfy: [ :el | 
			       (el isKindOf: TextGhost) not ] ].
	self scrollPane setTextWith: txt.

	anAnnouncement text = '$²' ifTrue: [ 
		self sendTextDocumentInlineCompletionAt:
			(anAnnouncement text toLineCharacter:
				 (anAnnouncement text size min: anAnnouncement stop)) ]
]
