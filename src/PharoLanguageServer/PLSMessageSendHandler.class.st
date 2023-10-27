Class {
	#name : 'PLSMessageSendHandler',
	#superclass : 'JRPCMessageSendHandler',
	#category : 'PharoLanguageServer-Handler',
	#package : 'PharoLanguageServer',
	#tag : 'Handler'
}

{ #category : 'parameters-checking' }
PLSMessageSendHandler >> checkParametersForRequest: aJRPCRequestObject [

	aJRPCRequestObject params ifNil: [ 
		self parametersCount = 0 ifFalse: [ JRPCInvalidParameters signal ] ].

	(aJRPCRequestObject params ifNil: [ #(  ) ]) size
	<= self parametersCount ifFalse: [ JRPCInvalidParameters signal ].

	(aJRPCRequestObject params isDictionary or: [ 
		 aJRPCRequestObject params isNil ]) ifFalse: [ 
		JRPCInvalidParameters signal ]
]

{ #category : 'parameters-checking' }
PLSMessageSendHandler >> executeWithArguments: anArrayOrDictionary [

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

{ #category : 'parameters-checking' }
PLSMessageSendHandler >> parametersNames [
	^ (self receiver class lookupSelector: self messageSelector) argumentNames
]
