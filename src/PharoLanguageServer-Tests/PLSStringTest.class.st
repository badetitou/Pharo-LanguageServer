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
			{(#line -> 0).
			#character -> 0} asDictionary 
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
			{(#line -> 1).
			#character -> 1} asDictionary 
]

{ #category : #tests }
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

{ #category : #tests }
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
