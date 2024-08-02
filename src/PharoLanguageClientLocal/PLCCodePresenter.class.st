Class {
	#name : 'PLCCodePresenter',
	#superclass : 'SpTextPresenter',
	#instVars : [
		'language',
		'plcClient',
		'version'
	],
	#category : 'PharoLanguageClientLocal-CodePresenter',
	#package : 'PharoLanguageClientLocal',
	#tag : 'CodePresenter'
}

{ #category : 'accessing' }
PLCCodePresenter >> applySymbols: listOfSymbols [

	| skinnableText |
	skinnableText := self text asText.
	listOfSymbols do: [ :symbol |
		skinnableText
			addAttribute: (TextColor new color: Color blue)
			from: (self text plsToPosition: symbol range start) +1
			to: (self text plsToPosition: symbol range end) ].
]

{ #category : 'initialization - deprecated' }
PLCCodePresenter >> initializePresenter [

	version := 0.
	language := 'python'.
	self startClient.
	plcClient
		sendDidOpenTextDocument: (PLPTextDocumentItem new
				 uri: self plpURI;
				 languageId: self language;
				 version: version;
				 text: '')
		for: self.
	self whenTextChangedDo: [ :text2 |
		version := version + 1.
		plcClient
			sendDidChangeTextDocument: self versionedTextDocumentIdentifier
			withChanges: { (PLPTextDocumentContentChangeEvent new
					 text: self text asString;
					 yourself) }.
		plcClient sendTextDocumentSymbol:
			self versionedTextDocumentIdentifier ]
]

{ #category : 'accessing' }
PLCCodePresenter >> language [

	^ language
]

{ #category : 'accessing' }
PLCCodePresenter >> language: anObject [

	language := anObject
]

{ #category : 'initialization' }
PLCCodePresenter >> plpURI [

	^ 'plcCodePresenter/' , self identityHash printString
]

{ #category : 'initialization' }
PLCCodePresenter >> startClient [

	plcClient := PLCClient new.
	plcClient language: #python.
	plcClient clientInit.
	plcClient start
]

{ #category : 'initialization - deprecated' }
PLCCodePresenter >> versionedTextDocumentIdentifier [

	^ PLSVersionedTextDocumentIdentifier new
		  uri: self plpURI;
		  version: version;
		  yourself
]

{ #category : 'initialization' }
PLCCodePresenter >> windowIsClosing [

	plcClient stop
]
