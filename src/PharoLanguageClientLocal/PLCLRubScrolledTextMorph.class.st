Class {
	#name : #PLCLRubScrolledTextMorph,
	#superclass : #SpRubScrolledTextMorph,
	#traits : 'TPLCClient',
	#classTraits : 'TPLCClient classTrait',
	#category : #PharoLanguageClientLocal
}

{ #category : #'event handling' }
PLCLRubScrolledTextMorph >> whenKeystrokeInTextArea: anAnnouncement [

	| txt |
	super whenKeystrokeInTextArea: anAnnouncement.
	txt := self text.

	txt := txt withIndexSelect: [ :val :idx | 
		       (txt runs at: idx) anySatisfy: [ :el | 
			       (el isKindOf: TextGhost) not ] ].
"	self scrollPane setTextWith: (txt append:
			 (('""char : ' , anAnnouncement event keyString , '""') asText
				  addAttribute: TextGhost new;
				  yourself)) ""hello"""
]
