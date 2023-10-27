Class {
	#name : 'PLSMCMethodDefinition',
	#superclass : 'MCMethodDefinition',
	#instVars : [
		'startPos',
		'endPos',
		'bodyStartPos'
	],
	#category : 'PharoLanguageServer-TonelUtils',
	#package : 'PharoLanguageServer',
	#tag : 'TonelUtils'
}

{ #category : 'accessing' }
PLSMCMethodDefinition >> bodyStartPos [
	^ bodyStartPos
]

{ #category : 'accessing' }
PLSMCMethodDefinition >> bodyStartPos: anObject [
	bodyStartPos := anObject
]

{ #category : 'accessing' }
PLSMCMethodDefinition >> endPos [
	^ endPos
]

{ #category : 'accessing' }
PLSMCMethodDefinition >> endPos: anObject [
	endPos := anObject
]

{ #category : 'accessing' }
PLSMCMethodDefinition >> isErrorDefinition [
	^ false
]

{ #category : 'accessing' }
PLSMCMethodDefinition >> startPos [
	^ startPos
]

{ #category : 'accessing' }
PLSMCMethodDefinition >> startPos: anObject [
	startPos := anObject
]
