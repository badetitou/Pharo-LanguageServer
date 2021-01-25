Extension { #name : #String }

{ #category : #'*PLS-DAP-Helper' }
String >> toLineColumn: position [
	"given a position, return a dictionnary with the line and column of the cursor at this position"

	| copy |
	copy := (self copyFrom: 1 to: position) lines.
	^ {(#line -> copy size).
	(#column -> copy last size)} asDictionary
]
