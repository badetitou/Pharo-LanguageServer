Class {
	#name : #PLCMessageSendHandler,
	#superclass : #JRPCMessageSendHandler,
	#category : #PharoLanguageClient
}

{ #category : #'parameters-checking' }
PLCMessageSendHandler >> checkParametersForRequest: aJRPCRequestObject [

	aJRPCRequestObject params ifNil: [ 
		self parametersCount = 0 ifFalse: [ JRPCInvalidParameters signal ] ].

	(aJRPCRequestObject params ifNil: [ #(  ) ]) size
	<= self parametersCount ifFalse: [ JRPCInvalidParameters signal ].

	(aJRPCRequestObject params isDictionary or: [ 
		 aJRPCRequestObject params isNil ]) ifFalse: [ 
		JRPCInvalidParameters signal ]
]

{ #category : #'parameters-checking' }
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

{ #category : #'parameters-checking' }
PLCMessageSendHandler >> parametersNames [
	^ (self receiver class lookupSelector: self messageSelector) argumentNames
]
