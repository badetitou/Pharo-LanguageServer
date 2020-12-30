"
A PLSFormaterTest is a test class for testing the behavior of PLSFormater
"
Class {
	#name : #PLSFormaterTest,
	#superclass : #TestCase,
	#category : #'PharoLanguageServer-Tests'
}

{ #category : #test }
PLSFormaterTest >> testFormated [
	| source formatter |
	source := '| i j |
	i ifTrue: [ j = 0].'.
	formatter := PLSFormater new
		sourceCode: source;
		yourself.
	self assert: formatter formated equals: (RBProgramNode formatterClass format: (RBParser parseExpression: source))
]
