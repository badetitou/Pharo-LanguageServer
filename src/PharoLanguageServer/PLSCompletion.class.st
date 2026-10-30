Class {
	#name : 'PLSCompletion',
	#superclass : 'Object',
	#instVars : [
		'completionContext',
		'source',
		'position',
		'sourceClass',
		'sourceIsMethod'
	],
	#category : 'PharoLanguageServer',
	#package : 'PharoLanguageServer'
}

{ #category : 'accessing' }
PLSCompletion >> completionContext [
	^ completionContext
]

{ #category : 'accessing' }
PLSCompletion >> completionContext: anObject [
	completionContext := anObject
]

{ #category : 'initialization' }
PLSCompletion >> entries [

	completionContext := CompletionContext
		                     engine: (PLSCompletionEngine new
				                      scripting: self sourceIsMethod not;
				                      yourself)
		                     class: self sourceClass
		                     source: self source
		                     position: self position.
	^ self completionContext entries collectWithIndex: [ :entry :index |
			  PLSCompletionItem new
				  label: entry contents;
				  insertTextFormat: PLSInsertTextFormat snippet;
				  insertText: entry contents toPLSSnippet;
				  kind: entry asPLSCompletionItemKind;
				  data: index;
				  "documentation: entry description description;"yourself ]
]

{ #category : 'initialization' }
PLSCompletion >> position [
	^ position
]

{ #category : 'initialization' }
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

{ #category : 'initialization' }
PLSCompletion >> source [
	^ source
]

{ #category : 'initialization' }
PLSCompletion >> source: aSource [
	source := aSource
]

{ #category : 'accessing' }
PLSCompletion >> sourceClass [
	^ sourceClass
]

{ #category : 'accessing' }
PLSCompletion >> sourceClass: anObject [
	sourceClass := anObject
]

{ #category : 'accessing' }
PLSCompletion >> sourceIsMethod [

	^ sourceIsMethod ifNil: [ false ]
]

{ #category : 'accessing' }
PLSCompletion >> sourceIsMethod: aBoolean [
	"Tell whether the source is a method of sourceClass rather than a script"

	sourceIsMethod := aBoolean
]
