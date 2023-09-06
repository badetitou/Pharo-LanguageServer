"
Based on https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#workspaceEdit
"
Class {
	#name : #PLSWorkspaceEdit,
	#superclass : #Object,
	#instVars : [
		'changes',
		'documentChanges',
		'changeAnnotations'
	],
	#category : #'PharoLanguageServer-Structure-Workspace'
}

{ #category : #accessing }
PLSWorkspaceEdit >> changeAnnotations [

	^ changeAnnotations
]

{ #category : #accessing }
PLSWorkspaceEdit >> changeAnnotations: anObject [

	changeAnnotations := anObject
]

{ #category : #accessing }
PLSWorkspaceEdit >> changes [

	^ changes
]

{ #category : #accessing }
PLSWorkspaceEdit >> changes: anObject [

	changes := anObject
]

{ #category : #accessing }
PLSWorkspaceEdit >> documentChanges [

	^ documentChanges
]

{ #category : #accessing }
PLSWorkspaceEdit >> documentChanges: anObject [

	documentChanges := anObject
]
