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
	^ compilationBindings at: aName ifAbsentPut: nil
]

{ #category : #binding }
PLSBinder >> initialize [
	compilationBindings := Dictionary new.
]
