"
I am signaled when a pls-env:compile or pls-env:remove request expects a version of an entity that the image no longer holds: someone else changed or removed the entity since the client read it.
The client receives the error code 32001 (negative), with the id and the current version of the entity (null when it was removed) as data.
"
Class {
	#name : 'PLSEntityConflict',
	#superclass : 'JRPCError',
	#instVars : [
		'id',
		'currentVersion'
	],
	#category : 'PharoLanguageServer',
	#package : 'PharoLanguageServer'
}

{ #category : 'accessing' }
PLSEntityConflict class >> errorCode [

	^ -32001
]

{ #category : 'converting' }
PLSEntityConflict >> asJRPCResponseWithId: anInteger [

	^ JRPCErrorResponseObject id: anInteger error: (JRPCErrorObject
			   code: self class errorCode
			   message: self messageText
			   data: {
					   (#id -> id).
					   (#currentVersion -> currentVersion) } asDictionary)
]

{ #category : 'accessing' }
PLSEntityConflict >> currentVersion [

	^ currentVersion
]

{ #category : 'accessing' }
PLSEntityConflict >> currentVersion: aString [

	currentVersion := aString
]

{ #category : 'accessing' }
PLSEntityConflict >> id [

	^ id
]

{ #category : 'accessing' }
PLSEntityConflict >> id: aString [

	id := aString
]

{ #category : 'accessing' }
PLSEntityConflict >> messageText [

	^ id , (currentVersion
		   ifNil: [ ' was removed from the image' ]
		   ifNotNil: [ ' changed in the image' ])
]
