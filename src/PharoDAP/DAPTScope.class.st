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
	| localVars bindingVars |

	bindingVars := OrderedDictionary new.
	(context receiver respondsTo:#bindings) ifTrue:[
		context receiver bindings associationsDo:[ : aBindingVar |
			
		self inCache
				at: aBindingVar value hash
				put:
					{(#context -> context).
					(#scope
						->
							(DAPTVariableScope new
								scope: aBindingVar value;
								inCache: self inCache;
								yourself))} asDictionary.
		bindingVars at:aBindingVar key put: (DAPVariable new
				name: aBindingVar key;
				value: ([aBindingVar value printString] on:Exception do:['?']);
				variablesReference:
					(aBindingVar value class  allInstVarNames
						ifEmpty: [ 0 ]
						ifNotEmpty: [ aBindingVar value hash ]);
				yourself) 
		] ].
	localVars :=self scope tempVars
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
				value: ([result printString] on:Exception do:['?']);
				variablesReference:
					(result class allInstVarNames
						ifEmpty: [ 0 ]
						ifNotEmpty: [ tempVar hash ]);
				yourself ].
	^ localVars addAll: bindingVars;yourself 
		
	


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
