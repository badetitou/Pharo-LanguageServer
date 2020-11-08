Class {
	#name : #PLSCompletionList,
	#superclass : #Object,
	#category : #'PharoLanguageServer-Structure-Completion'
}

{ #category : #testing }
PLSCompletionList >> asJRPCJSON [
	^ { #'isIncomplete' -> self isIncomplete asJRPCJSON.
	#'items' -> self completionItems asJRPCJSON } asDictionary
]

{ #category : #testing }
PLSCompletionList >> isIncomplete [
	^ true
]
