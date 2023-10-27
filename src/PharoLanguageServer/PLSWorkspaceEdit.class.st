"
Based on https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#workspaceEdit
"
Class {
	#name : 'PLSWorkspaceEdit',
	#superclass : 'Object',
	#instVars : [
		'changes',
		'documentChanges',
		'changeAnnotations'
	],
	#category : 'PharoLanguageServer-Structure-Workspace',
	#package : 'PharoLanguageServer',
	#tag : 'Structure-Workspace'
}

{ #category : 'accessing' }
PLSWorkspaceEdit >> asJRPCJSON [

	| dic |
	dic := Dictionary new.
	self changeAnnotations ifNotNil: [ :changeAnnots |
		dic at: #changeAnnotations put: changeAnnots asJRPCJSON ].
	self changes ifNotNil: [ :chgs |
		dic at: #changes put: chgs asJRPCJSON ].
	self documentChanges ifNotNil: [ :docChanges |
		dic at: #documentChanges put: docChanges asJRPCJSON ].
	^ dic
]

{ #category : 'accessing' }
PLSWorkspaceEdit >> changeAnnotations [

	^ changeAnnotations
]

{ #category : 'accessing' }
PLSWorkspaceEdit >> changeAnnotations: anObject [

	changeAnnotations := anObject
]

{ #category : 'accessing' }
PLSWorkspaceEdit >> changes [

	^ changes
]

{ #category : 'accessing' }
PLSWorkspaceEdit >> changes: anObject [

	changes := anObject
]

{ #category : 'accessing' }
PLSWorkspaceEdit >> documentChanges [

	^ documentChanges
]

{ #category : 'accessing' }
PLSWorkspaceEdit >> documentChanges: anObject [

	documentChanges := anObject
]
