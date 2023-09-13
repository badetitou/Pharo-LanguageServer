Trait {
	#name : #TPLPCommon,
	#instVars : [
		'currentId'
	],
	#category : #PharoLanguageProtocol
}

{ #category : #accessing }
TPLPCommon >> currentId [

	^ currentId
]

{ #category : #accessing }
TPLPCommon >> currentId: anObject [

	currentId := anObject
]

{ #category : #accessing }
TPLPCommon >> nextId [

	^ currentId := currentId + 1
]
