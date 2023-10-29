Extension { #name : #Behavior }

{ #category : #'*PharoLanguageClientLocal' }
Behavior >> syntaxHighlighter [
	"Answer a compiler appropriate for source methods of this class."

	^ PLCLTextStyler new
		classOrMetaClass: self;
		yourself
]
