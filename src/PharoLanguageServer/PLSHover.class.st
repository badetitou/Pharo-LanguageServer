Class {
	#name : #PLSHover,
	#superclass : #Object,
	#instVars : [
		'source',
		'position',
		'context'
	],
	#category : 'PharoLanguageServer'
}

{ #category : #accessing }
PLSHover >> contents [
	| word |
	word := self source text wordAt: (self source text plsToPosition: position).
	"can be a class"
	^ Smalltalk globals
		at: word asSymbol
		ifPresent: [ :class | 
			class isClass
				ifTrue: [ class comment	" asByteArray utf8Decoded" ]
				ifFalse: [ '' ] ]
		ifAbsent: [ "nil will be replace by the text URI in the future"
			(self source binder hasBindingOf: word)
				ifTrue: [ (self source binder bindingOf: word) value printString ]
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
	position := aDictionaryLineCharacter
]

{ #category : #accessing }
PLSHover >> source [
	^ source
]

{ #category : #accessing }
PLSHover >> source: anObject [
	source := anObject
]
