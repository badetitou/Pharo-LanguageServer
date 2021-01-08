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
DAPHandler >> receiver [
	^ receiver
]

{ #category : #accessing }
DAPHandler >> receiver: anObject [
	receiver := anObject
]
