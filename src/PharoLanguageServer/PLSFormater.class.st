Class {
	#name : 'PLSFormater',
	#superclass : 'Object',
	#instVars : [
		'sourceCode'
	],
	#category : 'PharoLanguageServer-Structure-Formater',
	#package : 'PharoLanguageServer',
	#tag : 'Structure-Formater'
}

{ #category : 'accessing' }
PLSFormater >> formated [
	^ self formatterClass format: (self parserClass parseFaultyExpression: self sourceCode)
]

{ #category : 'accessing' }
PLSFormater >> formatedMethod [
	^ self formatterClass format: (self parserClass parseMethod: self sourceCode)
]

{ #category : 'accessing' }
PLSFormater >> formatterClass [
	^ RBProgramNode formatterClass
]

{ #category : 'accessing' }
PLSFormater >> parserClass [
	^ RBParser
]

{ #category : 'accessing' }
PLSFormater >> sourceCode [
	^ sourceCode
]

{ #category : 'accessing' }
PLSFormater >> sourceCode: anObject [
	sourceCode := anObject
]
