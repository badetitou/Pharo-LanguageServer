Class {
	#name : #PLSStringTest,
	#superclass : #TestCase,
	#category : #'PharoLanguageServer-Tests'
}

{ #category : #tests }
PLSStringTest >> testToLineCharacter0 [
	| string |
	string := 'hello
	world
	'.
	self
		assert: (string toLineCharacter: 0)
		equals:
			{(#line -> 1).
			#character ->1} asDictionary 
]

{ #category : #tests }
PLSStringTest >> testToLineCharacterEndBeginSecondLine [
	| string |
	string := 'hello
	world
	'.
	self
		assert: (string toLineCharacter: 7)
		equals:
			{(#line -> 2).
			#character -> 1} asDictionary 
]

{ #category : #tests }
PLSStringTest >> testToLineCharacterEndFirstLine [
	| string |
	string := 'hello
	world
	'.
	self
		assert: (string toLineCharacter: 5)
		equals:
			{(#line -> 1).
			#character -> 5} asDictionary 
]

{ #category : #tests }
PLSStringTest >> testToLineCharacterEndSecondLine [
	| string |
	string := 'hello
	world'.
	self
		assert: (string toLineCharacter: 13)
		equals:
			{(#line -> 2).
			#character -> 6} asDictionary 
]
