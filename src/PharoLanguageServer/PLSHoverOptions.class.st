Class {
	#name : 'PLSHoverOptions',
	#superclass : 'Object',
	#category : 'PharoLanguageServer-Structure-Capabilities',
	#package : 'PharoLanguageServer',
	#tag : 'Structure-Capabilities'
}

{ #category : 'converting' }
PLSHoverOptions >> asJRPCJSON [
	^ {(#workDoneProgress -> false asJRPCJSON)} asDictionary
]
