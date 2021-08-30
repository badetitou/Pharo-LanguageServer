Class {
	#name : #DAPTVariableScope,
	#superclass : #DAPTScope,
	#category : #'PharoDAP-Types-Extension'
}

{ #category : #'as yet unclassified' }
DAPTVariableScope >> getDAPVariablesInContent: context [
	^ self scope class allInstVarNames
		collectWithIndex: [ :ivName :index | 
			| result |
			result := context object: self scope instVarAt: index.
			self inCache
				at: (DAPServer pluggableHashBlock value:result) 
				put:
					{(#context -> context).
					(#scope
						->
							(self class new
								scope: result;
								inCache: self inCache;
								yourself))} asDictionary.
			DAPVariable new
				name: ivName;
				value: result printString;
				variablesReference:
					(result class allInstVarNames
						ifEmpty: [ 0 ]
						ifNotEmpty: [ DAPServer pluggableHashBlock value:result ]);
				yourself ]
]
