Class {
	#name : #PLSHoverOptions,
	#superclass : #Object,
	#category : #'PharoLanguageServer-Structure-Capabilities'
}

{ #category : #converting }
PLSHoverOptions >> asJRPCJSON [
	^ {(#workDoneProgress -> false asJRPCJSON)} asDictionary
]
