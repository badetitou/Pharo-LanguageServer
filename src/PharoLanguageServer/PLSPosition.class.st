"
Position in a text document expressed as zero-based line and zero-based character offset. A position is between two characters like an ‘insert’ cursor in a editor. Special values like for example -1 to denote the end of a line are not supported.
"
Class {
	#name : #PLSPosition,
	#superclass : #Object,
	#instVars : [
		'line',
		'character'
	],
	#category : #'PharoLanguageServer-Structure'
}

{ #category : #accessing }
PLSPosition >> asJRPCJSON [
	^ {(#line -> self line asJRPCJSON).
	(#character -> self character asJRPCJSON)} asDictionary
]

{ #category : #accessing }
PLSPosition >> character [
	"Character offset on a line in a document (zero-based).
	Assuming that the line is represented as a string, the `character` value represents the gap between the `character` and `character + 1`.
	 
	 If the character value is greater than the line length it defaults back to the line length."

	^ character
]

{ #category : #accessing }
PLSPosition >> character: anObject [
	character := anObject
]

{ #category : #accessing }
PLSPosition >> line [
	"Line position in a document (zero-based)."
	^ line
]

{ #category : #accessing }
PLSPosition >> line: anObject [
	line := anObject
]
