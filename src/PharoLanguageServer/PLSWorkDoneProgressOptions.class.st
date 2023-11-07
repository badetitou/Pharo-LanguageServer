Class {
	#name : #PLSWorkDoneProgressOptions,
	#superclass : #Object,
	#category : 'PharoLanguageServer-Structure'
}

{ #category : #'as yet unclassified' }
PLSWorkDoneProgressOptions >> asJRPCJSON [
	^ { #'workDoneProgress' -> self workDoneProgress asJRPCJSON } asDictionary
]

{ #category : #'as yet unclassified' }
PLSWorkDoneProgressOptions >> workDoneProgress [
	^ false
]
