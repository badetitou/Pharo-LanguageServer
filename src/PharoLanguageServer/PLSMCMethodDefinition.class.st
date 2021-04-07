Class {
	#name : #PLSMCMethodDefinition,
	#superclass : #MCMethodDefinition,
	#instVars : [
		'startPos',
		'endPos'
	],
	#category : #'PharoLanguageServer-TonelUtils'
}

{ #category : #accessing }
PLSMCMethodDefinition >> endPos [
	^ endPos
]

{ #category : #accessing }
PLSMCMethodDefinition >> endPos: anObject [
	endPos := anObject
]

{ #category : #accessing }
PLSMCMethodDefinition >> startPos [
	^ startPos
]

{ #category : #accessing }
PLSMCMethodDefinition >> startPos: anObject [
	startPos := anObject
]
