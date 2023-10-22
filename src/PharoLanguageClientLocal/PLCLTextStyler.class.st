Class {
	#name : #PLCLTextStyler,
	#superclass : #SHRBTextStyler,
	#classTraits : 'TRBProgramNodeVisitor classTrait',
	#category : #PharoLanguageClientLocal
}

{ #category : #accessing }
PLCLTextStyler >> style: aText [
	aText ifEmpty: [ ^ self ].
	self terminateBackgroundStylingProcess.
	stylingEnabled
		ifFalse: [ ^ self ].
	text := aText copy.
	self privateStyle: text.
	self 
		addAttributesFrom: aText runs 
		satisfying: [ :each| each isKindOf: TextGhost ]
		to: text.
	view ifNotNil: [ :view2 | view2 stylerStyled: text ]
]
