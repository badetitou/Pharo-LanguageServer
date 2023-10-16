"
[Documentation](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#cancelRequest)
"
Class {
	#name : #PLPCancelParams,
	#superclass : #Object,
	#instVars : [
		'id'
	],
	#category : #'PharoLanguageProtocol-BaseProtocol'
}

{ #category : #converting }
PLPCancelParams >> asJRPCJSON [

	| dic |
	dic := Dictionary new.
	dic at: #id put: self id asJRPCJSON.
	^ dic
]

{ #category : #accessing }
PLPCancelParams >> id [

	^ id
]

{ #category : #accessing }
PLPCancelParams >> id: anObject [

	id := anObject
]
