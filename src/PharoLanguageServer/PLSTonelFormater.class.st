Class {
	#name : #PLSTonelFormater,
	#superclass : #Object,
	#instVars : [
		'sourceCode'
	],
	#category : 'PharoLanguageServer-Structure-Formater'
}

{ #category : #accessing }
PLSTonelFormater >> formated [
	| definitions |
	definitions := (PLSTonelParser parseString: sourceCode asByteArray utf8Decoded).
	definitions select: #isMethodDefinition thenDo: [ :somethingParsed | somethingParsed source: (PLSFormater new sourceCode: somethingParsed source) formatedMethod ]. 
	definitions do: #load.
	^ String streamContents: [ :stream | TonelWriter exportClass: definitions anyOne actualClass on: stream ]
]

{ #category : #accessing }
PLSTonelFormater >> sourceCode [
	^ sourceCode
]

{ #category : #accessing }
PLSTonelFormater >> sourceCode: anObject [
	sourceCode := anObject
]
