Class {
	#name : #PLSCodeActionOptions,
	#superclass : #Object,
	#instVars : [
		'codeActionKinds',
		'resolveProvider'
	],
	#category : 'PharoLanguageServer-Structure-CodeAction'
}

{ #category : #accessing }
PLSCodeActionOptions >> asJRPCJSON [

	| dic |
	dic := Dictionary new.
	self codeActionKinds ifNotNil: [ 
		dic at: #codeActionKinds put: self codeActionKinds asJRPCJSON ].
	self resolveProvider ifNotNil: [ 
		dic at: #resolveProvider put: self resolveProvider asJRPCJSON ].
	^ dic
]

{ #category : #accessing }
PLSCodeActionOptions >> codeActionKinds [

	^ codeActionKinds
]

{ #category : #accessing }
PLSCodeActionOptions >> codeActionKinds: anObject [

	codeActionKinds := anObject
]

{ #category : #accessing }
PLSCodeActionOptions >> resolveProvider [

	^ resolveProvider
]

{ #category : #accessing }
PLSCodeActionOptions >> resolveProvider: anObject [

	resolveProvider := anObject
]
