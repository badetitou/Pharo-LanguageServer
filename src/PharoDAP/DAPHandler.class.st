Class {
	#name : #DAPHandler,
	#superclass : #Object,
	#instVars : [
		'methodName',
		'receiver',
		'messageSelector'
	],
	#category : #PharoDAP
}

{ #category : #accessing }
DAPHandler >> checkParametersForRequest: aDAPRequestObject [ 
	aDAPRequestObject arguments
		ifNil: [
			self parametersCount = 0
				ifFalse: [ DAPInvalidParameters signal ] ].
	
	(aDAPRequestObject arguments ifNil: [ #() ]) size = self parametersCount
		ifFalse: [ DAPInvalidParameters signal ].
		
	(aDAPRequestObject arguments isDictionary
		and: [ ((aDAPRequestObject params keys union: self parametersNames) size ~= self parametersCount) ])
			ifTrue: [ DAPInvalidParameters signal ]
]

{ #category : #accessing }
DAPHandler >> executeWithArguments: anArrayOrDictionary [
	| arguments |
	arguments := anArrayOrDictionary.
	
	anArrayOrDictionary ifNil: [ 
		arguments := #() ].
	
	anArrayOrDictionary isDictionary
		ifTrue: [
			arguments := (anArrayOrDictionary associations sorted: [ :a :b |
				(self parametersNames indexOf: a key) < (self parametersNames indexOf: b key) ])
					collect: #value ].
		
	^ self send: self messageSelector to: self receiver with: arguments
]

{ #category : #accessing }
DAPHandler >> getMethodSelectorFromPragma [
	"Returns the selector corresponding to the method to execute as behaviour of the handler.
	 This method is retrieved by searching for <jrpc> pragma.
	"
	| pragmas |
	pragmas := (Pragma allNamed: #dap in: self receiver class).
	
	pragmas size = 1
		ifFalse: [ self error: 'Only one method should be tagged with <dap> pragma.' ].
		
	^ pragmas first methodSelector
]

{ #category : #accessing }
DAPHandler >> initialize [
	super initialize.
	self receiver: self.
	self messageSelector: self getMethodSelectorFromPragma
]

{ #category : #accessing }
DAPHandler >> messageSelector [
	^ messageSelector
]

{ #category : #accessing }
DAPHandler >> messageSelector: anObject [
	messageSelector := anObject
]

{ #category : #accessing }
DAPHandler >> methodName [
	^ methodName
]

{ #category : #accessing }
DAPHandler >> methodName: anObject [
	methodName := anObject
]

{ #category : #accessing }
DAPHandler >> parametersCount [
	"Returns the number of parameters expected by the handler."
	^ self parametersNames size
]

{ #category : #accessing }
DAPHandler >> parametersNames [
	^ (self receiver class >> self messageSelector) argumentNames
]

{ #category : #accessing }
DAPHandler >> receiver [
	^ receiver
]

{ #category : #accessing }
DAPHandler >> receiver: anObject [
	receiver := anObject
]

{ #category : #accessing }
DAPHandler >> send: aSelector to: aReceiver with: arguments [
	^ aReceiver perform: aSelector withArguments: arguments
]
