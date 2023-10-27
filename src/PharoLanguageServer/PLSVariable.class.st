Class {
	#name : 'PLSVariable',
	#superclass : 'Object',
	#instVars : [
		'name',
		'value',
		'variableReference',
		'isDirectory'
	],
	#category : 'PharoLanguageServer-Structure-Variables',
	#package : 'PharoLanguageServer',
	#tag : 'Structure-Variables'
}

{ #category : 'accessing' }
PLSVariable >> asJRPCJSON [
	^ {(#name -> self name asJRPCJSON).
	(#value -> self value1 asJRPCJSON).
	(#variableReference -> self variableReference asJRPCJSON).
	(#isDirectory -> self isDirectory asJRPCJSON)} asDictionary
]

{ #category : 'accessing' }
PLSVariable >> isDirectory [
	"Does this variable has subvariables"
	^ isDirectory
]

{ #category : 'accessing' }
PLSVariable >> isDirectory: anObject [
	isDirectory := anObject
]

{ #category : 'accessing' }
PLSVariable >> name [
	^ name
]

{ #category : 'accessing' }
PLSVariable >> name: anObject [
	name := anObject
]

{ #category : 'accessing' }
PLSVariable >> value1 [
	^ value
]

{ #category : 'accessing' }
PLSVariable >> value: anObject [
	value := anObject
]

{ #category : 'accessing' }
PLSVariable >> variableReference [
	^ variableReference
]

{ #category : 'accessing' }
PLSVariable >> variableReference: anObject [
	variableReference := anObject
]
