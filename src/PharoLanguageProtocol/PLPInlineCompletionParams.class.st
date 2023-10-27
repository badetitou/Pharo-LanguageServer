Class {
	#name : 'PLPInlineCompletionParams',
	#superclass : 'PLPTextDocumentPositionParams',
	#instVars : [
		'context'
	],
	#category : 'PharoLanguageProtocol-Completion',
	#package : 'PharoLanguageProtocol',
	#tag : 'Completion'
}

{ #category : 'accessing' }
PLPInlineCompletionParams >> asJRPCJSON [

	| dict |
	dict := super asJRPCJSON.
	dict at: 'context' put: self context asJRPCJSON.
	^ dict
]

{ #category : 'accessing' }
PLPInlineCompletionParams >> context [

	^ context
]

{ #category : 'accessing' }
PLPInlineCompletionParams >> context: anObject [

	context := anObject
]
