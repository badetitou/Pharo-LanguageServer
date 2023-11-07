"
Defines whether the insert text in a completion item should be interpreted as plain text or a snippet.
"
Class {
	#name : #PLSInsertTextFormat,
	#superclass : #Object,
	#category : 'PharoLanguageServer-Structure-Completion'
}

{ #category : #'as yet unclassified' }
PLSInsertTextFormat class >> plainText [
	"The primary text to be inserted is treated as a plain string."
	^ 1
]

{ #category : #'as yet unclassified' }
PLSInsertTextFormat class >> snippet [
	"The primary text to be inserted is treated as a snippet.
	 
	 A snippet can define tab stops and placeholders with `$1`, `$2`
	 and `${3:foo}`. `$0` defines the final tab stop, it defaults to
	 the end of the snippet. Placeholders with equal identifiers are linked,
	 that is typing in one will update others too."

	^ 2
]
