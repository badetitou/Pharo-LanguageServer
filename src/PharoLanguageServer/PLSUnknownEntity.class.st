"
I am signaled when a pls-env:* request names an entity the image does not hold, or an id that is not well formed.
The client receives an Invalid params error whose message names the entity.
"
Class {
	#name : 'PLSUnknownEntity',
	#superclass : 'JRPCError',
	#category : 'PharoLanguageServer',
	#package : 'PharoLanguageServer'
}

{ #category : 'converting' }
PLSUnknownEntity >> asJRPCResponseWithId: anInteger [

	^ JRPCErrorResponseObject id: anInteger error: (JRPCErrorObject
			   code: JRPCErrorObject invalidParams code
			   message: self messageText)
]
