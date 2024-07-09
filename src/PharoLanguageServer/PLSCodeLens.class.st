"
A code lens represents a command that should be shown along with source text, like the number of references, a way to run tests, *etc.*

A code lens is _unresolved_ when no command is associated to it.
For performance reasons the creation of a code lens and resolving should be done in two stages.
"
Class {
	#name : 'PLSCodeLens',
	#superclass : 'Object',
	#instVars : [
		'range',
		'command',
		'data'
	],
	#category : 'PharoLanguageServer-Structure-Lens',
	#package : 'PharoLanguageServer',
	#tag : 'Structure-Lens'
}

{ #category : 'accessing' }
PLSCodeLens >> asJRPCJSON [
	| dic |
	dic := Dictionary new.
	self command ifNotNil: [ dic at: #command put: self command asJRPCJSON ].
	self data ifNotNil: [ dic at: #data put: self data asJRPCJSON ].
	"Range is mandatory"
	dic at: #range put: self range asJRPCJSON.
	^ dic
]

{ #category : 'accessing' }
PLSCodeLens >> command [
	^ command
]

{ #category : 'accessing' }
PLSCodeLens >> command: anObject [
	command := anObject
]

{ #category : 'accessing' }
PLSCodeLens >> data [
	^ data
]

{ #category : 'accessing' }
PLSCodeLens >> data: anObject [
	data := anObject
]

{ #category : 'accessing' }
PLSCodeLens >> range [
	^ range
]

{ #category : 'accessing' }
PLSCodeLens >> range: anObject [
	range := anObject
]
