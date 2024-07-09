Class {
	#name : 'PLSCompletionList',
	#superclass : 'Object',
	#instVars : [
		'completionItems'
	],
	#category : 'PharoLanguageServer-Structure-Completion',
	#package : 'PharoLanguageServer',
	#tag : 'Structure-Completion'
}

{ #category : 'testing' }
PLSCompletionList >> asJRPCJSON [
	^ { #'isIncomplete' -> self isIncomplete asJRPCJSON.
	#'items' -> self completionItems asJRPCJSON } asDictionary
]

{ #category : 'accessing' }
PLSCompletionList >> completionItems [
	^ completionItems
]

{ #category : 'accessing' }
PLSCompletionList >> completionItems: anObject [
	completionItems := anObject
]

{ #category : 'testing' }
PLSCompletionList >> isIncomplete [
	^ true
]
