"
I am signaled when pls-env:loadProject cannot load a baseline: the folder is not a working copy holding it, or Metacello failed (a missing dependency, a conflict, a network error).
The client receives an Internal error whose message is the reason given by Metacello.
"
Class {
	#name : 'PLSProjectLoadFailed',
	#superclass : 'JRPCError',
	#category : 'PharoLanguageServer',
	#package : 'PharoLanguageServer'
}

{ #category : 'converting' }
PLSProjectLoadFailed >> asJRPCResponseWithId: anInteger [

	^ JRPCErrorResponseObject id: anInteger error: (JRPCErrorObject
			   code: JRPCErrorObject internalError code
			   message: self messageText)
]
