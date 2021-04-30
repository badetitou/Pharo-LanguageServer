Class {
	#name : #PLSTonelParser,
	#superclass : #TonelParser,
	#category : #'PharoLanguageServer-TonelUtils'
}

{ #category : #'private factory' }
PLSTonelParser >> methodDef [
	^ [ self
		newMethodDefinitionFrom:
			{stream position.
			self separator.
			(self try: [ self metadata ]).
			self separator.
			self method.
			stream position.
			self methodBody.
			stream position} ]
		on: Error
		do: [ ^ PLSErroredMCMethodDefinition new
				startPos: stream position;
				endPos: stream position;
				yourself ]
]

{ #category : #'private factory' }
PLSTonelParser >> newClassDefinitionFrom: anArray [
	| metadata |

	metadata := anArray sixth.
	^ MCClassDefinition
		name: (metadata at: #name)
		superclassName: (metadata at: #superclass)
		traitComposition: (metadata at: #traits ifAbsent: [ '{}' ])
		classTraitComposition: (metadata at: #classTraits ifAbsent: [ '{}' ])
		category: (metadata at: #category)
		instVarNames: (metadata at: #instVars ifAbsent: [ #() ])
		classVarNames: (metadata at: 'classVars' ifAbsent: [ #() ])
		poolDictionaryNames: (metadata at: 'pools' ifAbsent: [ #() ])
		classInstVarNames: (metadata at: 'classInstVars' ifAbsent: [ #() ])
		type: (metadata at: #type ifAbsent: [ #normal ]) asSymbol
		comment: (anArray second ifNil: [ '' ])
		commentStamp: nil
]

{ #category : #'private factory' }
PLSTonelParser >> newMethodDefinitionFrom: anArray [
	| metadata className meta selector source startPos endPos |
	startPos := anArray first.
	metadata := anArray third ifNil: [ Dictionary new ].
	className := anArray fifth first first.
	meta := anArray fifth first second notNil.
	selector := self extractSelector: anArray fifth second trimBoth.
	source := String
		streamContents: [ :s | 
			s << anArray fifth second.
			anArray seventh ifNotEmpty: [ :src | s << src ] ].
	endPos := anArray last.
	^ (PLSMCMethodDefinition
		className: className
		classIsMeta: meta
		selector: selector
		category: (metadata at: #category ifAbsent: [ '' ])
		timeStamp: nil
		source: source)
		startPos: startPos;
		endPos: endPos;
		bodyStartPos: anArray sixth;
		yourself
]
