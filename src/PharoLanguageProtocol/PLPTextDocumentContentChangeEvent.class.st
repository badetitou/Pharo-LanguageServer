Class {
	#name : #PLPTextDocumentContentChangeEvent,
	#superclass : #Object,
	#instVars : [
		'text',
		'range'
	],
	#category : 'PharoLanguageProtocol-TextDocument'
}

{ #category : #accessing }
PLPTextDocumentContentChangeEvent >> asJRPCJSON [

	| dic |
	dic := { (#text -> self text) } asDictionary.
	self range ifNotNil: [ :r | dic at: #range put: r asJRPCJSON ].
	^ dic
]

{ #category : #accessing }
PLPTextDocumentContentChangeEvent >> range [

	^ range
]

{ #category : #accessing }
PLPTextDocumentContentChangeEvent >> range: anObject [

	range := anObject
]

{ #category : #accessing }
PLPTextDocumentContentChangeEvent >> text [

	^ text
]

{ #category : #accessing }
PLPTextDocumentContentChangeEvent >> text: anObject [

	text := anObject
]
