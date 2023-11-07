Class {
	#name : #PLSLocation,
	#superclass : #Object,
	#instVars : [
		'uri',
		'range'
	],
	#category : 'PharoLanguageServer-Structure'
}

{ #category : #accessing }
PLSLocation >> asJRPCJSON [
	^ {(#uri -> self uri asJRPCJSON).
	(#range -> self range asJRPCJSON)} asDictionary
]

{ #category : #accessing }
PLSLocation >> range [
	^ range
]

{ #category : #accessing }
PLSLocation >> range: anObject [
	range := anObject
]

{ #category : #accessing }
PLSLocation >> uri [
	^ uri
]

{ #category : #accessing }
PLSLocation >> uri: anObject [
	uri := anObject
]
