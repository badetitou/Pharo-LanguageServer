"
I am signaled when the client answers a request of the language server with an error (for instance a client that does not know the request: code -32601), or when the request is cancelled before the client answered (code nil).
"
Class {
	#name : 'PLSClientRequestFailed',
	#superclass : 'Error',
	#instVars : [
		'code'
	],
	#category : 'PharoLanguageServer-Messaging',
	#package : 'PharoLanguageServer',
	#tag : 'Messaging'
}

{ #category : 'accessing' }
PLSClientRequestFailed >> code [
	"The JSON-RPC error code the client answered, or nil when the request was cancelled"

	^ code
]

{ #category : 'accessing' }
PLSClientRequestFailed >> code: anInteger [

	code := anInteger
]
