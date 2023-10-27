Class {
	#name : 'PLCLRubScrolledTextMorph',
	#superclass : 'SpRubScrolledTextMorph',
	#classTraits : 'TPLCClient classTrait',
	#instVars : [
		'version'
	],
	#category : 'PharoLanguageClientLocal',
	#package : 'PharoLanguageClientLocal'
}

{ #category : 'lsp - completion' }
PLCLRubScrolledTextMorph >> clientInlineCompletionFrom: items [

	self scrollPane setTextWith: (self text append: ((items anyOne at: #insertText) asText
				  addAttribute: TextGhost new;
				  yourself))
]

{ #category : 'initialization' }
PLCLRubScrolledTextMorph >> initialize [

	version := 0.
	"PLCClient default sendDidOpenTextDocument: (PLPTextDocumentItem new
			 uri: self plpURI;
			 languageId: 'smalltalk';
			 version: version;
			 text: '') for: self."

	super initialize
]

{ #category : 'event handling' }
PLCLRubScrolledTextMorph >> plpURI [

	^ 'workspace/' , self identityHash printString
]

{ #category : 'event handling' }
PLCLRubScrolledTextMorph >> versionedTextDocumentIdentifier [

	^ PLSVersionedTextDocumentIdentifier new
		  uri: self plpURI;
		  version: version;
		  yourself
]

{ #category : 'event handling' }
PLCLRubScrolledTextMorph >> whenTextChangedInTextArea: anAnnouncement [

	| txt |
	super whenTextChangedInTextArea: anAnnouncement.
	version := version + 1.
	"PLCClient default
		sendDidChangeTextDocument: self versionedTextDocumentIdentifier
		withChanges: { (PLPTextDocumentContentChangeEvent new
				 text: self text asString;
				 yourself) }.
	txt := self text.
	txt := txt withIndexSelect: [ :val :idx |
		       (txt runs at: idx) anySatisfy: [ :el |
			       (el isKindOf: TextGhost) not ] ].
	self scrollPane setTextWith: txt.
	PLCClient default
		sendTextDocument: self versionedTextDocumentIdentifier
		inlineCompletionAt:
		(anAnnouncement text asString toLineCharacter: anAnnouncement start)"
]
