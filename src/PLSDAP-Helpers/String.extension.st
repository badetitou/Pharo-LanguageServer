Extension { #name : #String }

{ #category : #'*PLSDAP-Helpers' }
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
