"
I am the source of one method of a document, as Renraku critiques it, or the definition of a class when my source is nil.
I map the indexes of my source to the indexes of the text of my document: the whole text of a method document, or the selector line and the body of a method in a Tonel file.
"
Class {
	#name : 'PLSCritiqueSource',
	#superclass : 'Object',
	#instVars : [
		'document',
		'behavior',
		'source',
		'headerSize',
		'headerStart',
		'bodyStart'
	],
	#category : 'PharoLanguageServer-Structure-Diagnostic',
	#package : 'PharoLanguageServer',
	#tag : 'Structure-Diagnostic'
}

{ #category : 'instance creation' }
PLSCritiqueSource class >> document: aDocument behavior: aBehavior source: aString [
	"The source of a method that is the whole text of aDocument"

	^ self
		  document: aDocument
		  behavior: aBehavior
		  source: aString
		  headerSize: aString lines first size
		  headerStart: 1
		  bodyStart: nil
]

{ #category : 'instance creation' }
PLSCritiqueSource class >> document: aDocument behavior: aBehavior source: aString headerSize: headerSize headerStart: headerStart bodyStart: bodyStart [
	"The headerSize first characters of aString are at the index headerStart of the text of aDocument, the others at bodyStart.
	 A nil aString stands for the definition of aBehavior; a nil bodyStart for a source that is the whole text of aDocument"

	^ self new
		  setDocument: aDocument
		  behavior: aBehavior
		  source: aString
		  headerSize: headerSize
		  headerStart: headerStart
		  bodyStart: bodyStart
]

{ #category : 'critiques' }
PLSCritiqueSource >> bannableEntity [
	"Answer the entity of the image whose banLevelCandidates can ban a critique of mine: my method once installed, else my behavior"

	| selector |
	source ifNil: [ ^ behavior ].
	selector := [ RBParser parseMethodPattern: source ]
		            on: Error
		            do: [ ^ behavior ].
	^ behavior compiledMethodAt: selector ifAbsent: [ behavior ]
]

{ #category : 'critiques' }
PLSCritiqueSource >> bans: aRule [
	"Answer whether the manifest of my package bans aRule for my method or my class"

	| builder entity |
	builder := TheManifestBuilder new.
	entity := self bannableEntity.
	(builder manifestOf: entity) ifNil: [ ^ false ].
	^ entity banChecksForValidation anySatisfy: [ :level |
		  builder bansRule: aRule for: level ]
]

{ #category : 'critiques' }
PLSCritiqueSource >> critiques [
	"Answer the Renraku critiques of my method, compiled without installing it, or of my behavior when I have no source.
	 Renraku checks the bans of the method it critiques, which is not the installed one: those of the installed method and of its class are checked here"

	| entity |
	entity := source ifNil: [ behavior ] ifNotNil: [
			          behavior compiler
				          source:
					          (source copyReplaceAll: String lf with: String cr);
				          failBlock: [ ^ #(  ) ];
				          compile ].
	^ ([ entity critiques ]
		   on: Error
		   do: [ #(  ) ]) select: [ :each |
		  each isCritique and: [ (self bans: each rule) not ] ]
]

{ #category : 'positions' }
PLSCritiqueSource >> definitionRange [
	"Answer the range of the selector line of my method, or of the name of my class"

	^ self rangeFrom: headerStart to: headerStart + headerSize - 1
]

{ #category : 'positions' }
PLSCritiqueSource >> documentIndexOf: anIndex [
	"Answer the index in the text of my document of the character at anIndex in my source"

	(bodyStart isNil or: [ anIndex <= headerSize ]) ifTrue: [
		^ headerStart + anIndex - 1 ].
	^ bodyStart + anIndex - headerSize - 1
]

{ #category : 'positions' }
PLSCritiqueSource >> intervalOf: aCritique [
	"Answer the interval of my source that aCritique is about, or nil if it is about the whole of my method or class.
	 A critique replacing a node is about this node rather than its source anchor, which is the selector"

	source ifNil: [ ^ nil ].
	(aCritique class hasInstVarNamed: #oldNode) ifTrue: [
			(aCritique instVarNamed: #oldNode) ifNotNil: [ :node |
				^ node sourceInterval ] ].
	^ aCritique sourceAnchor providesInterval
		  ifTrue: [ aCritique sourceAnchor interval ]
		  ifFalse: [ nil ]
]

{ #category : 'edition' }
PLSCritiqueSource >> lineEnding [

	| text |
	text := document text.
	(text includesSubstring: String crlf) ifTrue: [ ^ String crlf ].
	(text includes: Character lf) ifTrue: [ ^ String lf ].
	^ String cr
]

{ #category : 'positions' }
PLSCritiqueSource >> rangeFrom: start to: stop [
	"Answer the range of the text of my document from its index start to its index stop"

	^ PLSRange
		  start: (document text toLineCharacter: start - 1)
		  end: (document text toLineCharacter: stop)
]

{ #category : 'positions' }
PLSCritiqueSource >> rangeOf: aCritique [
	"Answer the range of the text of my document that aCritique is about"

	| interval |
	interval := self intervalOf: aCritique.
	(interval isNil or: [ interval isEmpty ]) ifTrue: [
		^ self definitionRange ].
	^ self
		  rangeFrom: (self documentIndexOf: interval first)
		  to: (self documentIndexOf: interval last)
]

{ #category : 'initialization' }
PLSCritiqueSource >> setDocument: aDocument behavior: aBehavior source: aString headerSize: anInteger headerStart: aHeaderStart bodyStart: aBodyStart [

	document := aDocument.
	behavior := aBehavior.
	source := aString.
	headerSize := anInteger.
	headerStart := aHeaderStart.
	bodyStart := aBodyStart
]

{ #category : 'edition' }
PLSCritiqueSource >> textEditFor: aMethodSource [
	"Answer the edit of the text of my document that replaces my method by aMethodSource, with the line endings of my document.
	 In a Tonel file, the selector line stays: only the body is replaced"

	| newText start stop |
	newText := bodyStart
		           ifNil: [ aMethodSource ]
		           ifNotNil: [
		           aMethodSource allButFirst: aMethodSource lines first size ].
	start := bodyStart ifNil: [ headerStart ].
	stop := bodyStart
		        ifNil: [ headerStart + source size - 1 ]
		        ifNotNil: [ bodyStart + source size - headerSize - 1 ].
	^ PLSTextEdit new
		  range: (self rangeFrom: start to: stop);
		  newText: (newText withLineEndings: self lineEnding);
		  yourself
]
