Class {
	#name : #PLSBinder,
	#superclass : #Object,
	#instVars : [
		'compilationBindings'
	],
	#category : #PharoLanguageServer
}

{ #category : #binding }
PLSBinder >> bindingOf: aName [
	(self hasBindingOf: aName)
		ifFalse: [ compilationBindings add: (WorkspaceVariable key: aName asSymbol) ].
	^ compilationBindings associationAt: aName
]

{ #category : #accessing }
PLSBinder >> compilationBindings [
	^ compilationBindings
]

{ #category : #accessing }
PLSBinder >> compilationBindings: anObject [
	compilationBindings := anObject
]

{ #category : #binding }
PLSBinder >> hasBindingOf: aString [
	^ compilationBindings includesKey: aString
]

{ #category : #binding }
PLSBinder >> initialize [
	compilationBindings := Dictionary new.
]

{ #category : #binding }
PLSBinder >> isForScripting [
	^ false
]
