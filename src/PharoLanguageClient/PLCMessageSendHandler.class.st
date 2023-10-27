Class {
	#name : 'PLCMessageSendHandler',
	#superclass : 'JRPCMessageSendHandler',
	#category : 'PharoLanguageClient',
	#package : 'PharoLanguageClient'
}

{ #category : 'parameters-checking' }
PLCMessageSendHandler >> checkParametersForRequest: aJRPCRequestObject [

	aJRPCRequestObject params ifNil: [ 
		self parametersCount = 0 ifFalse: [ JRPCInvalidParameters signal ] ].

	(aJRPCRequestObject params ifNil: [ #(  ) ]) size
	<= self parametersCount ifFalse: [ JRPCInvalidParameters signal ].

	(aJRPCRequestObject params isDictionary or: [ 
		 aJRPCRequestObject params isNil ]) ifFalse: [ 
		JRPCInvalidParameters signal ]
]

{ #category : 'evaluation' }
PLCMessageSendHandler >> executeWithArguments: anArrayOrDictionary [

	| arguments |
	arguments := anArrayOrDictionary.

	anArrayOrDictionary ifNil: [ arguments := #(  ) ].

	anArrayOrDictionary isDictionary ifTrue: [ 
		arguments := OrderedCollection new.
		self parametersNames do: [ :name |
			arguments add: (anArrayOrDictionary at: name ifAbsent: [ nil ]) ].
		arguments := arguments asArray ].

	^ self send: self messageSelector to: self receiver with: arguments
]

{ #category : 'accessing' }
PLCMessageSendHandler >> parametersNames [

	^ (self receiver class lookupSelector: self messageSelector)
		  argumentNames
]
