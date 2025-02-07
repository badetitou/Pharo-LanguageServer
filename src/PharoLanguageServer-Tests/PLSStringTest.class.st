Class {
	#name : 'PLSStringTest',
	#superclass : 'TestCase',
	#category : 'PharoLanguageServer-Tests',
	#package : 'PharoLanguageServer-Tests'
}

{ #category : 'tests' }
PLSStringTest >> testPlsLines [

	| strings |
	strings := '[' plsLines.
	self assert: strings first equals: '['.
	self assert: strings size equals: 1
]

{ #category : 'tests' }
PLSStringTest >> testPlsLinesEmpty [

	| strings |
	strings := '' plsLines.
	self assert: strings first equals: ''.
	self assert: strings size equals: 1
]

{ #category : 'tests' }
PLSStringTest >> testPlsLinesTwoEmpty [

	| strings |
	strings := '
' plsLines.
	self assert: strings first equals: '
'.
	self assert: strings second equals: ''.
	self assert: strings size equals: 2
]

{ #category : 'tests' }
PLSStringTest >> testPlsSizeOfLine [

	self assert: ('123456789' plsSizeOfLine: 0) equals: 9
]

{ #category : 'tests' }
PLSStringTest >> testPlsSizeOfLineOverflow [

	self assert: ('123456789' plsSizeOfLine: 12) equals: 9
]

{ #category : 'tests' }
PLSStringTest >> testPlsSizeOfLineSecondLine [

	self assert: ('123456789
12345678911' plsSizeOfLine: 1) equals: 11
]

{ #category : 'tests' }
PLSStringTest >> testPlsSizeOfLineTooFew [

	self assert: ('123456789
12345678911' plsSizeOfLine: -12) equals: 10 "10 because includes the \n"
]

{ #category : 'tests' }
PLSStringTest >> testPlsToPositionNoLine [
	self
		assert:
			(''
				plsToPosition:
					{(#line -> 0).
					(#character -> 0)} asDictionary)
		equals: 0
]

{ #category : 'tests' }
PLSStringTest >> testPlsToPositionOneEmptyLine [
	self
		assert:
			('   '
				plsToPosition:
					{(#line -> 0).
					(#character -> 0)} asDictionary)
		equals: 0
]

{ #category : 'tests' }
PLSStringTest >> testPlsToPositionOutOfBox [
	self
		assert:
			('Object.

hello := true.'
				plsToPosition:
					{(#line -> 10).
					(#character -> 14)} asDictionary)
		equals: 23
]

{ #category : 'tests' }
PLSStringTest >> testPlsToPositionSeveralLines [
	self
		assert:
			('
			
			'
				plsToPosition:
					{(#line -> 0).
					(#character -> 0)} asDictionary)
		equals: 0
]

{ #category : 'tests' }
PLSStringTest >> testPlsToPositionSomeChar [
	self
		assert:
			('Object.

hello := true.'
				plsToPosition:
					{(#line -> 2).
					(#character -> 14)} asDictionary)
		equals: 23
]

{ #category : 'tests' }
PLSStringTest >> testToLineCharacter0 [
	| string |
	string := 'hello
	world
	'.
	self
		assert: (string toLineCharacter: 0)
		equals:
			{(#line -> 0).
			#character -> 0} asDictionary 
]

{ #category : 'tests' }
PLSStringTest >> testToLineCharacterEndBeginSecondLine [
	| string |
	string := 'hello
	world
	'.
	self
		assert: (string toLineCharacter: 7)
		equals:
			{(#line -> 1).
			#character -> 1} asDictionary 
]

{ #category : 'tests' }
PLSStringTest >> testToLineCharacterEndFirstLine [
	| string |
	string := 'hello
	world
	'.
	self
		assert: (string toLineCharacter: 6)
		equals:
			{(#line -> 0).
			#character -> 5} asDictionary 
]

{ #category : 'tests' }
PLSStringTest >> testToLineCharacterEndSecondLine [
	| string |
	string := 'hello
	world'.
	self
		assert: (string toLineCharacter: 12)
		equals:
			{(#line -> 1).
			#character -> 6} asDictionary 
]

{ #category : 'tests' }
PLSStringTest >> testToPLSSnippet [
	| string |
	string := 'hello'.
	self
		assert: (string toPLSSnippet )
		equals: 'hello$0'
]

{ #category : 'tests' }
PLSStringTest >> testToPLSSnippetMultipleKeyword [
	| string |
	string := 'hello:world:'.
	self
		assert: (string toPLSSnippet )
		equals: 'hello: $1 world: $2$0'
]

{ #category : 'tests' }
PLSStringTest >> testToPLSSnippetOneKeyword [
	| string |
	string := 'hello:'.
	self
		assert: (string toPLSSnippet )
		equals: 'hello: $1$0'
]
