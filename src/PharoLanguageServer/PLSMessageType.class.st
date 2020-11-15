Class {
	#name : #PLSMessageType,
	#superclass : #Object,
	#category : #'PharoLanguageServer-Structure'
}

{ #category : #'error handling' }
PLSMessageType class >> error [
	^ 1
]

{ #category : #'error handling' }
PLSMessageType class >> info [
	^ 3
]

{ #category : #'error handling' }
PLSMessageType class >> log [
	^ 4
]

{ #category : #'error handling' }
PLSMessageType class >> warning [
	^ 2
]
