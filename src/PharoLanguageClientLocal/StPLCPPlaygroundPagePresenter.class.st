Class {
	#name : #StPLCPPlaygroundPagePresenter,
	#superclass : #StPlaygroundPagePresenter,
	#instVars : [
		'version'
	],
	#category : #PharoLanguageClientLocal
}

{ #category : #'event handling' }
StPLCPPlaygroundPagePresenter >> clientInlineCompletionFrom: items [

	text setTextWith:
		(self text append: ((items anyOne at: #insertText) asText
				  addAttribute: TextGhost new;
				  yourself))
]

{ #category : #initialization }
StPLCPPlaygroundPagePresenter >> initialize [

	version := 0.
	"PLCClient default sendDidOpenTextDocument: (PLPTextDocumentItem new
			 uri: self plpURI;
			 languageId: 'smalltalk';
			 version: version;
			 text: '') for: self."

	super initialize
]

{ #category : #'event handling' }
StPLCPPlaygroundPagePresenter >> initializePresenters [

	super initializePresenters.
	text whenTextChangedDo: [ :aString |
		version := version + 1
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
		(anAnnouncement text asString toLineCharacter: anAnnouncement start)" ]
]

{ #category : #'event handling' }
StPLCPPlaygroundPagePresenter >> plpURI [

	^ 'workspace/' , self identityHash printString
]

{ #category : #'event handling' }
StPLCPPlaygroundPagePresenter >> versionedTextDocumentIdentifier [

	^ PLSVersionedTextDocumentIdentifier new
		  uri: self plpURI;
		  version: version;
		  yourself
]
