Class {
	#name : #PLSHover,
	#superclass : #Object,
	#instVars : [
		'source',
		'position',
		'context'
	],
	#category : #PharoLanguageServer
}

{ #category : #accessing }
PLSHover >> contents [
	| word |
	word := self source wordAt: self position.
	"can be a class"
	^ Smalltalk globals
		at: word asSymbol
		ifPresent: [ :class | 
			class isClass
				ifTrue: [ class comment" asByteArray utf8Decoded" ]
				ifFalse: [ '' ] ]
		ifAbsent: [ "nil will be replace by the text URI in the future"
			((self context compilationBindingsAt: nil) hasBindingOf: word)
				ifTrue: [ ((self context compilationBindingsAt: nil) bindingOf: word) value printString ]
				ifFalse: [ '' ] ]
]

{ #category : #accessing }
PLSHover >> context [
	^ context
]

{ #category : #accessing }
PLSHover >> context: anObject [
	context := anObject
]

{ #category : #accessing }
PLSHover >> position [
	^ position
]

{ #category : #accessing }
PLSHover >> position: aDictionaryLineCharacter [
	| current |
	current := 0.
	self source
		lineIndicesDo: [ :start :end :endDelimiter | 
			current = (aDictionaryLineCharacter at: #line)
				ifTrue:
					[ ^ position := start - 1 + (aDictionaryLineCharacter at: #character) ].
			current := current + 1 ].
	^ -1
]

{ #category : #accessing }
PLSHover >> source [
	^ source
]

{ #category : #accessing }
PLSHover >> source: anObject [
	source := anObject
]
