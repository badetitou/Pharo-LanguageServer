Class {
	#name : #PLSErroredMCMethodDefinition,
	#superclass : #PLSMCMethodDefinition,
	#category : #'PharoLanguageServer-TonelUtils'
}

{ #category : #testing }
PLSErroredMCMethodDefinition >> isErrorDefinition [
	^ true
]

{ #category : #testing }
PLSErroredMCMethodDefinition >> load [
	self inform: #'problem with at least one method definition'
]
