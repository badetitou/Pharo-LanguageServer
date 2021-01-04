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

{ #category : #binding }
PLSBinder >> hasBindingOf: aString [
	^ compilationBindings includesKey: aString
]

{ #category : #binding }
PLSBinder >> initialize [
	compilationBindings := Dictionary new.
]
