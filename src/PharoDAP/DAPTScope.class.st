Class {
	#name : #DAPTScope,
	#superclass : #Object,
	#instVars : [
		'scope',
		'inCache'
	],
	#category : #'PharoDAP-Types-Extension'
}

{ #category : #'as yet unclassified' }
DAPTScope >> getDAPVariablesInContent: context [
	^ self scope tempVars
		collect: [ :tempVar | 
			| result |
			result := tempVar readFromLocalContext: context.
			self inCache
				at: tempVar hash
				put:
					{(#context -> context).
					(#scope
						->
							(DAPTVariableScope new
								scope: result;
								inCache: self inCache;
								yourself))} asDictionary.


			"Create a DAP variable with the variable name and value"
			DAPVariable new
				name: tempVar name;
				value: result printString;
				variablesReference:
					(result class allInstVarNames
						ifEmpty: [ 0 ]
						ifNotEmpty: [ tempVar hash ]);
				yourself ]
]

{ #category : #accessing }
DAPTScope >> inCache [
	^ inCache
]

{ #category : #accessing }
DAPTScope >> inCache: anObject [
	inCache := anObject
]

{ #category : #accessing }
DAPTScope >> scope [
	^ scope
]

{ #category : #accessing }
DAPTScope >> scope: anObject [
	scope := anObject
]
