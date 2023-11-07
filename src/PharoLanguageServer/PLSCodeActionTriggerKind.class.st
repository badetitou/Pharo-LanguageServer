Class {
	#name : #PLSCodeActionTriggerKind,
	#superclass : #Object,
	#category : 'PharoLanguageServer-Structure-CodeAction'
}

{ #category : #events }
PLSCodeActionTriggerKind class >> automatic [
	^ 2
]

{ #category : #events }
PLSCodeActionTriggerKind class >> invoked [
	^ 1
]
