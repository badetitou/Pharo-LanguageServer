Extension { #name : #String }

{ #category : #'*PharoLanguageServer' }
String >> plsLineIndicesDo: aBlock [
	"execute aBlock with 3 arguments for each line:
	- start index of line
	- end index of line without line delimiter
	- end index of line including line delimiter(s) CR, LF or CRLF"

	| cr lf start sz nextLF nextCR |
	start := 1.
	sz := self size.
	cr := Character cr.
	nextCR := self indexOf: cr startingAt: 1.
	lf := Character lf.
	nextLF := self indexOf: lf startingAt: 1.
	sz = 0
		ifTrue: [ aBlock value: sz value: sz value: sz.
			^ self ].
	[ start <= sz ]
		whileTrue: [ (nextLF = 0 and: [ nextCR = 0 ])
				ifTrue: [ "No more CR, nor LF, the string is over"
					aBlock value: start value: sz value: sz.
					^ self ].
			(nextCR = 0 or: [ 0 < nextLF and: [ nextLF < nextCR ] ])
				ifTrue: [ "Found a LF"
					aBlock value: start value: nextLF - 1 value: nextLF.
					start := 1 + nextLF.
					nextLF := self indexOf: lf startingAt: start ]
				ifFalse: [ 1 + nextCR = nextLF
						ifTrue: [ "Found a CR-LF pair"
							aBlock value: start value: nextCR - 1 value: nextLF.
							start := 1 + nextLF.
							nextCR := self indexOf: cr startingAt: start.
							nextLF := self indexOf: lf startingAt: start ]
						ifFalse: [ "Found a CR"
							aBlock value: start value: nextCR - 1 value: nextCR.
							start := 1 + nextCR.
							nextCR := self indexOf: cr startingAt: start ] ] ].
	aBlock value: start value: sz value: sz
]

{ #category : #'*PharoLanguageServer' }
String >> plsLines [
	"Same as lines but empty line exist"
	^Array new: (self size // 60 max: 16)
            streamContents: [:lines | self plsLinesDo: [:aLine | lines nextPut: aLine]]
]

{ #category : #'*PharoLanguageServer' }
String >> plsLinesDo: aBlock [
	"Same as linesDo but empty line exist"

	self
		plsLineIndicesDo: [ :start :endWithoutDelimiters :end |
			| begin |
			"endWithoutDelimiters = start
				ifTrue: [ aBlock value: '' ]
				ifFalse: [" 
					begin := (start = 0) ifTrue: [ 1 ] ifFalse: [ start ].  
					aBlock value: (self copyFrom: begin to: end) "]" ]
]

{ #category : #'*PharoLanguageServer' }
String >> plsToPosition: aLineCharacter [
	| sum currentLine lines |
	sum := aLineCharacter at: #character.
	currentLine := 0.
	lines := self plsLines.
	[ currentLine < aLineCharacter at: #line ]
		whileTrue: [ sum := sum + (lines at: currentLine + 1) size.
			currentLine := currentLine + 1 ].
	^ sum
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
