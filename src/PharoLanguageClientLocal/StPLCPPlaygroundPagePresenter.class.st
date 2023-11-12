Class {
	#name : #StPLCPPlaygroundPagePresenter,
	#superclass : #StPlaygroundPagePresenter,
	#instVars : [
		'version'
	],
	#category : #'PharoLanguageClientLocal-GraphicalStack'
}

{ #category : #'event handling' }
StPLCPPlaygroundPagePresenter >> clientInlineCompletionFrom: items [

	text setInlineCompletionWith: ((items anyOne at: #insertText) asText
			 addAttribute: TextGhost new;
			 yourself)
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

{ #category : #initialization }
StPLCPPlaygroundPagePresenter >> initializePresenters [

	self initializeToolbar.
	self initializeStatusbar.

	(text := self instantiate: SpPLCCodePresenter)
		interactionModel: StPlaygroundInteractionModel new;
		lineNumbers: self showLineNumbers;
		overridingContextMenu;
		withEditionContextMenu;
		contextMenu: [ (self menuActionsFor: text) asMenuPresenter ];
		contextKeyBindings: (self menuActionsFor: text) asKMCategory;
		whenTextChangedDo: [ :aString | page contents: aString ].

	text announcer
		when: SpCodeWillBeEvaluatedAnnouncement
		send: #ensureContentsFlushed
		to: self.

	text eventHandler
		whenKeyUpDo: [ :event | self updateLineNumber ];
		whenMouseUpDo: [ :event | self updateLineNumber ];
		"before taking focus position will be nil, ensure I have the correct one"
		whenFocusReceivedDo: [ self updateLineNumber ].
	text whenTextChangedDo: [ :aString |
		version := version + 1.
		'text change' recordInfo.
		self clientInlineCompletionFrom:
			{ { (#insertText -> 'hello') } asDictionary }
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
