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

{ #category : 'comparing' }
TextGhost >> hash [
	^ color hash
]

{ #category : 'printing' }
TextGhost >> printOn: aStream [

	super printOn: aStream
]
