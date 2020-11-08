Class {
	#name : #PLSServerCapabilities,
	#superclass : #Object,
	#category : #'PharoLanguageServer-Structure'
}

{ #category : #converting }
PLSServerCapabilities >> asJRPCJSON [
	^ {(#completionProvider -> self completionProvider asJRPCJSON)}
		asDictionary
]

{ #category : #'as yet unclassified' }
PLSServerCapabilities >> completionProvider [
	^ PLSCompletionOptions new
]
