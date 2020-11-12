Class {
	#name : #PLSFormater,
	#superclass : #Object,
	#instVars : [
		'sourceCode'
	],
	#category : #PharoLanguageServer
}

{ #category : #accessing }
PLSFormater >> formated [
	^ self formatterClass format: (self parserClass parseFaultyExpression: self sourceCode)
]

{ #category : #accessing }
PLSFormater >> formatterClass [
	^ RBProgramNode formatterClass
]

{ #category : #accessing }
PLSFormater >> parserClass [
	^ RBParser
]

{ #category : #accessing }
PLSFormater >> sourceCode [
	^ sourceCode
]

{ #category : #accessing }
PLSFormater >> sourceCode: anObject [
	sourceCode := anObject
]
