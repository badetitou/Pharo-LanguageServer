"
I let a debug point stop only on some of its hits, as the hit condition of a breakpoint of VS Code: `5` or `==5` the fifth hit, `>5`, `>=5`, `<5`, `<=5`, and `%5` every fifth hit. I count the hits that pass the other checks of the debug point before me (its condition).
"
Class {
	#name : 'PLSHitConditionBehavior',
	#superclass : 'DebugPointCheckBehavior',
	#instVars : [
		'hits',
		'condition'
	],
	#category : 'PharoLanguageServer-Debug',
	#package : 'PharoLanguageServer',
	#tag : 'Debug'
}

{ #category : 'execution' }
PLSHitConditionBehavior >> accepts: aHitNumber [
	"Answer whether the hit of number aHitNumber satisfies my condition. A condition that is not understood never stops, rather than always"

	| operator count |
	operator := #( '==' '>=' '<=' '>' '<' '%' )
		            detect: [ :each | condition beginsWith: each ]
		            ifNone: [ '==' ].
	count := Integer
		         readFrom: ((condition beginsWith: operator)
				          ifTrue: [ condition allButFirst: operator size ]
				          ifFalse: [ condition ]) trimBoth
		         ifFail: [ ^ false ].
	operator = '==' ifTrue: [ ^ aHitNumber = count ].
	operator = '>=' ifTrue: [ ^ aHitNumber >= count ].
	operator = '<=' ifTrue: [ ^ aHitNumber <= count ].
	operator = '>' ifTrue: [ ^ aHitNumber > count ].
	operator = '<' ifTrue: [ ^ aHitNumber < count ].
	^ count > 0 and: [ aHitNumber \\ count = 0 ]
]

{ #category : 'accessing' }
PLSHitConditionBehavior >> condition [

	^ condition
]

{ #category : 'accessing' }
PLSHitConditionBehavior >> condition: aString [
	"The hit condition of VS Code: a number, or a number after ==, >, >=, <, <= or %"

	condition := aString trimBoth
]

{ #category : 'execution' }
PLSHitConditionBehavior >> execute [
	"Count the hit and answer whether the debug point goes on with it"

	hits := self hits + 1.
	^ self accepts: hits
]

{ #category : 'accessing' }
PLSHitConditionBehavior >> hits [

	^ hits ifNil: [ 0 ]
]

{ #category : 'initialization' }
PLSHitConditionBehavior >> initialize [

	super initialize.
	self priority: 20.
	hits := 0
]
