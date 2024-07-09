Class {
	#name : 'PLSCodeActionKind',
	#superclass : 'Object',
	#instVars : [
		'string'
	],
	#category : 'PharoLanguageServer-Structure-CodeAction',
	#package : 'PharoLanguageServer',
	#tag : 'Structure-CodeAction'
}

{ #category : 'requirements' }
PLSCodeActionKind class >> codeActionNamed: aString [

	^ self new
		  string: aString;
		  yourself
]

{ #category : 'requirements' }
PLSCodeActionKind class >> empty [
	^ self codeActionNamed: ''
]

{ #category : 'requirements' }
PLSCodeActionKind class >> quickfix [
	^ self codeActionNamed: 'quickfix'
]

{ #category : 'requirements' }
PLSCodeActionKind class >> refactor [
	^ self codeActionNamed: 'refactor'
]

{ #category : 'requirements' }
PLSCodeActionKind class >> refactorExtract [
	^ self codeActionNamed: 'refactor.extract'
]

{ #category : 'requirements' }
PLSCodeActionKind class >> refactorInline [
	^ self codeActionNamed: 'refactor.inline'
]

{ #category : 'requirements' }
PLSCodeActionKind class >> refactorRewrite [
	^ self codeActionNamed: 'refactor.rewrite'
]

{ #category : 'requirements' }
PLSCodeActionKind class >> source [
	^ self codeActionNamed: 'source'
]

{ #category : 'requirements' }
PLSCodeActionKind class >> sourceFixAll [
	^ self codeActionNamed: 'source.fixAll'
]

{ #category : 'requirements' }
PLSCodeActionKind class >> sourceOrganizeImports [
	^ self codeActionNamed: 'source.organizeImports'
]

{ #category : 'converting' }
PLSCodeActionKind >> asJRPCJSON [
	^ string 
]

{ #category : 'accessing' }
PLSCodeActionKind >> string [

	^ string
]

{ #category : 'accessing' }
PLSCodeActionKind >> string: anObject [

	string := anObject
]
