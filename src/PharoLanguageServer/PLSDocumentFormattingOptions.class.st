Class {
	#name : #PLSDocumentFormattingOptions,
	#superclass : #Object,
	#category : #'PharoLanguageServer-Structure-Capabilities'
}

{ #category : #converting }
PLSDocumentFormattingOptions >> asJRPCJSON [
	^ {(#workDoneProgress -> false asJRPCJSON)} asDictionary
]
