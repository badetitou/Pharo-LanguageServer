Class {
	#name : 'PLSCodeActionTriggerKind',
	#superclass : 'Object',
	#category : 'PharoLanguageServer-Structure-CodeAction',
	#package : 'PharoLanguageServer',
	#tag : 'Structure-CodeAction'
}

{ #category : 'events' }
PLSCodeActionTriggerKind class >> automatic [
	^ 2
]

{ #category : 'events' }
PLSCodeActionTriggerKind class >> invoked [
	^ 1
]
