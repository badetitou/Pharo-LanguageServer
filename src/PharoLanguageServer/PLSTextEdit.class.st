"
A textual edit applicable to a text document.
"
Class {
	#name : #PLSTextEdit,
	#superclass : #Object,
	#instVars : [
		'newText',
		'range'
	],
	#category : 'PharoLanguageServer-Structure'
}

{ #category : #accessing }
PLSTextEdit >> asJRPCJSON [
	^ {(#range -> self range asJRPCJSON).
	(#newText -> self newText asJRPCJSON)} asDictionary
]

{ #category : #accessing }
PLSTextEdit >> newText [
	"The string to be inserted. For delete operations use an empty string."
	^ newText
]

{ #category : #accessing }
PLSTextEdit >> newText: anObject [
	newText := anObject
]

{ #category : #accessing }
PLSTextEdit >> range [
	"The range of the text document to be manipulated. To insert text into a document create a range where start === end."
	^ range
]

{ #category : #accessing }
PLSTextEdit >> range: anObject [
	range := anObject
]
