Class {
	#name : #PLPInitializeParams,
	#superclass : #Object,
	#instVars : [
		'processId',
		'clientInfo',
		'capabilities'
	],
	#category : #'PharoLanguageProtocol-Initialize'
}

{ #category : #accessing }
PLPInitializeParams >> asJRPCJSON [

	| dic |
	dic := Dictionary new.
	dic at: #capabilities put: self capabilities asJRPCJSON.
	self clientInfo ifNotNil: [ :cI | 
		dic at: #clientInfo put: cI asJRPCJSON ].
	self processId ifNotNil: [ :cI | 
		dic at: #processId put: cI asJRPCJSON ].
	^ dic
]

{ #category : #accessing }
PLPInitializeParams >> capabilities [

	^ capabilities
]

{ #category : #accessing }
PLPInitializeParams >> capabilities: anObject [

	capabilities := anObject
]

{ #category : #accessing }
PLPInitializeParams >> clientInfo [

	^ clientInfo
]

{ #category : #accessing }
PLPInitializeParams >> clientInfo: anObject [

	clientInfo := anObject
]

{ #category : #accessing }
PLPInitializeParams >> processId [

	^ processId
]

{ #category : #accessing }
PLPInitializeParams >> processId: anObject [

	processId := anObject
]
