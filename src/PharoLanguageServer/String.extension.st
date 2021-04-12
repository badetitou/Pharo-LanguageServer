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
String >> plsToPosition: aLineCharacter [
	^ (((self lines first: ((aLineCharacter at: #line))) sum: #size)
		+ aLineCharacter
		at:
			#character)
				+
					((self includes: Character lf)
						ifTrue: [ ((aLineCharacter at: #line) + 1) ]
						ifFalse: [ 0 ])
				+
					((self includes: Character cr)
						ifTrue: [ ((aLineCharacter at: #line) + 1) ]
						ifFalse: [ 0 ])
]

{ #category : #'*PharoLanguageServer' }
String >> toLineCharacter: position [
	"given a position, return a dictionnary with the line and character of the cursor at this position"

	| copy |
	copy := (self first: (position min: self size)) lines.
	copy
		ifEmpty: [ ^ {(#line -> 0).
			(#character -> 0)} asDictionary ].
	^ {(#line -> (copy size - 1)).
	(#character -> (copy last size max: 0))} asDictionary
]

{ #category : #'*PharoLanguageServer' }
String >> toPLSSnippet [
	| idx number |
	idx := 1.
	number := 1.
	^ (self class
		new: self size
		streamContents: [ :stream | 
			| foundIdx |
			[ (foundIdx := self findString: ':' startingAt: idx) isZero ]
				whileFalse: [ stream
						next: foundIdx - idx putAll: self startingAt: idx;
						nextPutAll: ': $';
						nextPutAll: number printString;
						nextPut: Character space.
					number := number + 1.
					idx := foundIdx + 1].
			idx <= self size
				ifTrue:
					[ stream next: self size - idx + 1 putAll: self startingAt: idx ] ]) trimRight 
		, '$0'
]

{ #category : #'*PharoLanguageServer' }
String >> wordAt: anIndex [
	"('word before index' wordAt: 4) >>> 'word'"

	"('word before index' wordAt: 15)  >>> 'index'"
	
	"('word before index.hello' wordAt: 15)  >>> 'index'"

	| sepBefore sepAfter tokBefore tokAfter index |
	index := (anIndex max: 1).
	tokBefore := false.
	sepBefore := index.
	sepAfter := index.
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
