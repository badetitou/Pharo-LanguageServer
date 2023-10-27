Class {
	#name : 'TextGhost',
	#superclass : 'TextAttribute',
	#instVars : [
		'color'
	],
	#category : 'PharoLanguageClientLocal',
	#package : 'PharoLanguageClientLocal'
}

{ #category : 'comparing' }
TextGhost >> = other [

	^ other class == self class
]

{ #category : 'scanning' }
TextGhost >> dominates: other [
"Only one color attribute on a same portion of text."
	^ true
]

{ #category : 'printing' }
TextGhost >> emphasizeScanner: scanner [
	"Set the emphasis for text scanning"

	scanner addEmphasis: 2.
	scanner textColor: color
]

{ #category : 'comparing' }
TextGhost >> hash [
	^ color hash
]

{ #category : 'comparing' }
TextGhost >> initialize [
	super initialize.
	color := Color lightGray
]

{ #category : 'printing' }
TextGhost >> printOn: aStream [

	super printOn: aStream
]
