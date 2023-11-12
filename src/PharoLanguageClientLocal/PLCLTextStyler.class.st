Class {
	#name : #PLCLTextStyler,
	#superclass : #SHRBTextStyler,
	#category : #'PharoLanguageClientLocal-GraphicalStack'
}

{ #category : #attributes }
PLCLTextStyler class >> formatIncompleteIdentifiers [
	^ SHRBTextStyler formatIncompleteIdentifiers
]

{ #category : #attributes }
PLCLTextStyler class >> styleTable [
	^ SHRBTextStyler styleTable
]

{ #category : #attributes }
PLCLTextStyler class >> textAttributesByPixelHeight [
	^ SHRBTextStyler textAttributesByPixelHeight
]

{ #category : #styling }
PLCLTextStyler >> style: aText [

	aText ifEmpty: [ ^ self ].
	stylingEnabled ifFalse: [ ^ self ].
	text := aText copy.
	self privateStyle: text.
	self
		addAttributesFrom: aText runs
		satisfying: [ :each | each isKindOf: TextGhost ]
		to: text.
	view ifNotNil: [ :view2 | view2 stylerStyled: text ]
]
