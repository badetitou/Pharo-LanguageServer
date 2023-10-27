Class {
	#name : 'PLPInlineCompletionContext',
	#superclass : 'Object',
	#instVars : [
		'triggerKind',
		'selectedCompletionInfo'
	],
	#category : 'PharoLanguageProtocol-Completion',
	#package : 'PharoLanguageProtocol',
	#tag : 'Completion'
}

{ #category : 'converting' }
PLPInlineCompletionContext >> asJRPCJSON [

	| dic |
	dic := Dictionary new.
	dic at: #triggerKind put: self triggerKind asJRPCJSON.
	self selectedCompletionInfo ifNotNil: [ :el | 
		dic at: #selectedCompletionInfo put: el ].
	^ dic
]

{ #category : 'accessing' }
PLPInlineCompletionContext >> selectedCompletionInfo [

	^ selectedCompletionInfo
]

{ #category : 'accessing' }
PLPInlineCompletionContext >> selectedCompletionInfo: anObject [

	selectedCompletionInfo := anObject
]

{ #category : 'accessing' }
PLPInlineCompletionContext >> triggerKind [

	^ triggerKind
]

{ #category : 'accessing' }
PLPInlineCompletionContext >> triggerKind: anObject [

	triggerKind := anObject
]
