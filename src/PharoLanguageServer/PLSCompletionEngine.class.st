Class {
	#name : 'PLSCompletionEngine',
	#superclass : 'CompletionEngine',
	#instVars : [
		'scripting'
	],
	#category : 'PharoLanguageServer',
	#package : 'PharoLanguageServer'
}

{ #category : 'testing' }
PLSCompletionEngine >> isScripting [
	"The source is a script unless told it is a method"

	^ scripting ifNil: [ true ]
]

{ #category : 'testing' }
PLSCompletionEngine >> scripting: aBoolean [

	scripting := aBoolean
]
