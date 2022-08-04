Class {
	#name : #PLSCodeActionContext,
	#superclass : #Object,
	#instVars : [
		'diagnostics',
		'only',
		'triggerKind'
	],
	#category : #'PharoLanguageServer-Structure-CodeAction'
}

{ #category : #accessing }
PLSCodeActionContext >> diagnostics [

	^ diagnostics
]

{ #category : #accessing }
PLSCodeActionContext >> diagnostics: anObject [

	diagnostics := anObject
]

{ #category : #accessing }
PLSCodeActionContext >> only [

	^ only
]

{ #category : #accessing }
PLSCodeActionContext >> only: anObject [

	only := anObject
]

{ #category : #accessing }
PLSCodeActionContext >> triggerKind [

	^ triggerKind
]

{ #category : #accessing }
PLSCodeActionContext >> triggerKind: anObject [

	triggerKind := anObject
]
