Class {
	#name : 'PLSParameterInformation',
	#superclass : 'Object',
	#instVars : [
		'label',
		'documentation'
	],
	#category : 'PharoLanguageServer-Structure-Signature',
	#package : 'PharoLanguageServer',
	#tag : 'Structure-Signature'
}

{ #category : 'converting' }
PLSParameterInformation >> asJRPCJSON [
	^ {(#label -> self label asJRPCJSON)} asDictionary
]

{ #category : 'accessing' }
PLSParameterInformation >> documentation [
	^ documentation
]

{ #category : 'accessing' }
PLSParameterInformation >> documentation: anObject [
	documentation := anObject
]

{ #category : 'accessing' }
PLSParameterInformation >> label [
	^ label
]

{ #category : 'accessing' }
PLSParameterInformation >> label: anObject [
	label := anObject
]
