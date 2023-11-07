Class {
	#name : #PLSApplyWorkspaceEditParams,
	#superclass : #Object,
	#instVars : [
		'label',
		'edit'
	],
	#category : 'PharoLanguageServer-Structure-Workspace'
}

{ #category : #accessing }
PLSApplyWorkspaceEditParams >> asJRPCJSON [

	| dic |
	dic := { (#edit -> self edit asJRPCJSON) } asDictionary.
	self label ifNotNil: [ :lab | dic at: #label put: lab asJRPCJSON ].
	^ dic
]

{ #category : #accessing }
PLSApplyWorkspaceEditParams >> edit [

	^ edit
]

{ #category : #accessing }
PLSApplyWorkspaceEditParams >> edit: anObject [

	edit := anObject
]

{ #category : #accessing }
PLSApplyWorkspaceEditParams >> label [

	^ label
]

{ #category : #accessing }
PLSApplyWorkspaceEditParams >> label: anObject [

	label := anObject
]
