Class {
	#name : #PLSCompletion,
	#superclass : #Object,
	#instVars : [
		'completionContext',
		'source',
		'position'
	],
	#category : #PharoLanguageServer
}

{ #category : #accessing }
PLSCompletion >> completionContext [
	^ completionContext
]

{ #category : #accessing }
PLSCompletion >> completionContext: anObject [
	completionContext := anObject
]

{ #category : #initialization }
PLSCompletion >> entries [
	completionContext := CompletionContext
		engine: CompletionEngine new
		class: nil
		source: self source
		position: self position.
	^ self completionContext entries
		collectWithIndex: [ :entry :index |
			PLSCompletionItem new
				label: entry contents;
				kind: entry asPLSCompletionItemKind;
				data: index;
				yourself ]
]

{ #category : #initialization }
PLSCompletion >> position [
	^ position
]

{ #category : #initialization }
PLSCompletion >> position: aDictionaryLineCharacter [
	| current |
	current := 0.
	self source
		lineIndicesDo: [ :start :end :endDelimiter | 
			current = (aDictionaryLineCharacter at: #line)
				ifTrue:
					[ ^ position := start - 1 + (aDictionaryLineCharacter at: #character) ].
			current := current + 1 ].
	^ -1
]

{ #category : #initialization }
PLSCompletion >> source [
	^ source
]

{ #category : #initialization }
PLSCompletion >> source: aSource [
	source := aSource
]
