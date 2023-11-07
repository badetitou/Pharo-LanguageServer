Class {
	#name : #PLSSignatureHelp,
	#superclass : #Object,
	#instVars : [
		'signatures'
	],
	#category : 'PharoLanguageServer-Structure-Signature'
}

{ #category : #accessing }
PLSSignatureHelp >> asJRPCJSON [
	^ {(#signatures -> self signatures asJRPCJSON)} asDictionary
]

{ #category : #accessing }
PLSSignatureHelp >> signatures [
	^ signatures
]

{ #category : #accessing }
PLSSignatureHelp >> signatures: anObject [
	signatures := anObject
]
