Extension { #name : #String }

{ #category : #'*PharoLanguageServer' }
String >> findCloseBracesFor: startIndex [

	| pos nestLevel |
	pos := startIndex + 1.
	nestLevel := 1.
	[ pos <= self size ]
		whileTrue: [ (self at: pos) = ${
				ifTrue: [ nestLevel := nestLevel + 1 ].
			(self at: pos) = $}
				ifTrue: [ nestLevel := nestLevel - 1 ].
			nestLevel = 0
				ifTrue: [ ^ pos ].
			pos := pos + 1 ].
	^ 0
]

{ #category : #'*PharoLanguageServer' }
String >> wordAt: anIndex [
	"('word before index' wordAt: 4) >>> 'word'"

	"('word before index' wordAt: 15)  >>> 'index'"
	
	"('word before index.hello' wordAt: 15)  >>> 'index'"

	| sepBefore sepAfter tokBefore tokAfter |
	tokBefore := false.
	sepBefore := anIndex.
	sepAfter := anIndex.
	[ sepBefore > 0 and: [ ((self at: sepBefore) isSeparator or: [ (self at: sepBefore) isOtherPunctuation ]) not ] ]
		whileTrue: [ tokBefore := true.
			sepBefore := sepBefore - 1 ].
	[ sepAfter < (self size + 1) and: [ ((self at: sepAfter) isSeparator or: [ (self at: sepAfter) isOtherPunctuation ]) not ] ]
		whileTrue: [ tokAfter := true.
			sepAfter := sepAfter + 1 ].
	^ (tokBefore and: [ tokAfter ])
		ifTrue: [ self copyFrom: sepBefore + 1 to: sepAfter - 1 ]
		ifFalse: [ String new ]
]
