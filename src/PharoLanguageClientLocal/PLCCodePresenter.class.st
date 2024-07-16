Class {
	#name : 'PLCCodePresenter',
	#superclass : 'SpTextPresenter',
	#instVars : [
		'language',
		'plcClient'
	],
	#category : 'PharoLanguageClientLocal-CodePresenter',
	#package : 'PharoLanguageClientLocal',
	#tag : 'CodePresenter'
}

{ #category : 'initialization' }
PLCCodePresenter >> initialize [

	| version  |
	super initialize.
	version := 0.
	plcClient := PLCClient new.
	plcClient
		sendDidOpenTextDocument: (PLPTextDocumentItem new
				 uri: self plpURI;
				 languageId: self language;
				 version: version;
				 text: '')
		for: self
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
