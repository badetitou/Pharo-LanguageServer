Trait {
	#name : #TPLPCommon,
	#instVars : [
		'currentId'
	],
	#category : #PharoLanguageProtocol
}

{ #category : #id }
TPLPCommon >> currentId [

	^ currentId
]

{ #category : #id }
TPLPCommon >> currentId: anObject [

	currentId := anObject
]

{ #category : #'plp - send message' }
TPLPCommon >> getHeaderFor: answer into: aStream [

	aStream << 'Content-Length: ' << answer size asString << String crlf
	<< String crlf
]

{ #category : #id }
TPLPCommon >> nextId [

	^ currentId := currentId + 1
]
