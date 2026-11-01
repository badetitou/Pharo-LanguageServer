"
I represent a document inside the server.

I do have many API endpoint for easy extension such as
- `diagnostics`
- `codeLens`
- `symbols`

You can extend them if you want to create several kind of document and analysis by document.
But **do not modify** it in this class. It is the default format, so you will modify the analysis for every format possible
"
Class {
	#name : 'PLSDocument',
	#superclass : 'Object',
	#instVars : [
		'version',
		'text',
		'languageId',
		'uri',
		'binder',
		'server',
		'savedText',
		'critiques',
		'critiquesText'
	],
	#category : 'PharoLanguageServer-Document',
	#package : 'PharoLanguageServer',
	#tag : 'Document'
}

{ #category : 'instance creation' }
PLSDocument class >> extractUriFrom: aPseudoURIString [
	"I extract additional element of URI for good usage"

	^ aPseudoURIString copyUpTo: $?
]

{ #category : 'instance creation' }
PLSDocument class >> from: aTextDocument [
	"return a script document or a tonel document with the built from the textDocument dictionary"

	| clazz |
	clazz := self allSubclasses
		         detect: [ :subclass |
		         subclass supportDocument: aTextDocument ]
		         ifNone: [ self ].
	^ clazz fromDocumentDictionary: aTextDocument
]

{ #category : 'instance creation' }
PLSDocument class >> fromDocumentDictionary: aDocumentDictionary [

	^ self new
		  version: (aDocumentDictionary at: #version);
		  text: (aDocumentDictionary at: #text ifAbsent: '');
		  languageId: (aDocumentDictionary at: #languageId ifAbsent: '');
		  uri: (aDocumentDictionary at: #uri);
		  yourself
]

{ #category : 'instance creation' }
PLSDocument class >> fromURI: aTextDocumentURI [
	"this is a backup solution"

	| clazz |
	clazz := self allSubclasses
		         detect: [ :subclass |
			         subclass supportDocumentUri:
				         (self extractUriFrom: aTextDocumentURI) ]
		         ifNone: [ self ].
	^ clazz new
		  uri: (self extractUriFrom: aTextDocumentURI);
		  yourself
]

{ #category : 'instance creation' }
PLSDocument class >> isTonelDocument: textDocument [

	| uri |
	uri := self extractUriFrom: (textDocument at: #uri).
	^ (uri endsWith: 'class.st') or: [ uri endsWith: 'extension.st' ]
]

{ #category : 'instance creation' }
PLSDocument class >> supportDocument: aTextDocument [
	"return true if this class can host this kind of textDocument"

	^ self subclassResponsibility
]

{ #category : 'instance creation' }
PLSDocument class >> supportDocumentUri: aTextDocumentUri [
	"return true if this class can host this kind of textDocument"

	^ self subclassResponsibility
]

{ #category : 'accessing' }
PLSDocument >> binder [
	^ binder
]

{ #category : 'code lens' }
PLSDocument >> codeLens [
	^ {}
]

{ #category : 'accessing' }
PLSDocument >> completionClass [
	"Answer the class in which completion takes place, or nil for a script"

	^ nil
]

{ #category : 'critiques' }
PLSDocument >> computeCritiques [

	| stamp all |
	stamp := PLSCritique nextStamp.
	all := OrderedCollection new.
	self critiqueSources do: [ :critiqueSource |
			critiqueSource critiques do: [ :critique |
					all add: (PLSCritique
							 critique: critique
							 source: critiqueSource
							 index: all size + 1
							 stamp: stamp) ] ].
	critiques := all asArray.
	critiquesText := text
]

{ #category : 'critiques' }
PLSDocument >> critiqueAt: anIndex stamp: aStamp [
	"Answer the critique at anIndex of the computation aStamp, or nil if my critiques were computed again since"

	^ (critiques ifNil: [ #(  ) ])
		  detect: [ :each |
		  each index = anIndex and: [ each stamp = aStamp ] ]
		  ifNone: [ nil ]
]

{ #category : 'critiques' }
PLSDocument >> critiqueSources [
	"Answer the PLSCritiqueSource of the methods and classes of my text that Renraku critiques"

	^ #(  )
]

{ #category : 'critiques' }
PLSDocument >> critiques [
	"Answer my PLSCritique. They are computed again when my text changed and is at rest; until then, the former ones stay"

	(critiquesText ~= text and: [ self isAtRest ]) ifTrue: [
		self computeCritiques ].
	^ critiques ifNil: [ #(  ) ]
]

{ #category : 'critiques' }
PLSDocument >> critiquesAreCurrent [
	"Answer whether my critiques were computed on my current text, so that their ranges are right"

	^ critiques notNil and: [ critiquesText = text ]
]

{ #category : 'diagnostics' }
PLSDocument >> diagnostics [
	"return a collection of diagnostic"

	^ {  }
]

{ #category : 'accessing' }
PLSDocument >> formattedText [

	^ (PLSFormater new sourceCode: self text) formated
]

{ #category : 'initialization' }
PLSDocument >> initialize [
	binder := PLSBinder new
]

{ #category : 'critiques' }
PLSDocument >> isAtRest [
	"Answer whether my text is the one opened or saved. My critiques are computed only then, so that typing does not compute them"

	^ text notNil and: [ text = savedText ]
]

{ #category : 'accessing' }
PLSDocument >> isMethodSource [
	"Answer whether my text is the source of one method of completionClass"

	^ false
]

{ #category : 'accessing' }
PLSDocument >> languageId [
	^ languageId
]

{ #category : 'accessing' }
PLSDocument >> languageId: anObject [
	languageId := anObject
]

{ #category : 'lsp - accessing' }
PLSDocument >> nodeAt: aPosition [
	self parsed
]

{ #category : 'critiques' }
PLSDocument >> resetCritiques [
	"Compute my critiques again the next time my text is at rest"

	critiquesText := nil
]

{ #category : 'critiques' }
PLSDocument >> savedText [
	"Answer my text when the client opened or saved me last"

	^ savedText
]

{ #category : 'critiques' }
PLSDocument >> savedText: aString [

	savedText := aString
]

{ #category : 'accessing' }
PLSDocument >> server [

	^ server
]

{ #category : 'accessing' }
PLSDocument >> server: anObject [

	server := anObject
]

{ #category : 'lsp - accessing' }
PLSDocument >> symbols [

	^ {  }
]

{ #category : 'accessing' }
PLSDocument >> text [
	^ text
]

{ #category : 'accessing' }
PLSDocument >> text: anObject [
	text := anObject
]

{ #category : 'accessing' }
PLSDocument >> uri [
	^ uri
]

{ #category : 'accessing' }
PLSDocument >> uri: anObject [
	uri := anObject
]

{ #category : 'accessing' }
PLSDocument >> version [
	^ version
]

{ #category : 'accessing' }
PLSDocument >> version: anObject [
	version := anObject
]
