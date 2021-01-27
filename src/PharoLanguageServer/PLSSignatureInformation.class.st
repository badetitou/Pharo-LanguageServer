Class {
	#name : #PLSSignatureInformation,
	#superclass : #Object,
	#instVars : [
		'label',
		'documentation',
		'parameters',
		'activeParameter'
	],
	#category : #'PharoLanguageServer-Structure-Signature'
}

{ #category : #accessing }
PLSSignatureInformation >> activeParameter [
	^ activeParameter
]

{ #category : #accessing }
PLSSignatureInformation >> activeParameter: anObject [
	activeParameter := anObject
]

{ #category : #accessing }
PLSSignatureInformation >> asJRPCJSON [
	^ {(#label -> self label asJRPCJSON).
	(#documentation -> self documentation asJRPCJSON).
	(#parameters -> self parameters asJRPCJSON)} asDictionary
]

{ #category : #accessing }
PLSSignatureInformation >> documentation [
	^ documentation
]

{ #category : #accessing }
PLSSignatureInformation >> documentation: anObject [
	documentation := anObject
]

{ #category : #accessing }
PLSSignatureInformation >> label [
	^ label
]

{ #category : #accessing }
PLSSignatureInformation >> label: anObject [
	label := anObject
]

{ #category : #accessing }
PLSSignatureInformation >> parameters [
	^ parameters
]

{ #category : #accessing }
PLSSignatureInformation >> parameters: anObject [
	parameters := anObject
]
