Extension { #name : 'SocketStream' }

{ #category : '*PharoLanguageProtocol' }
SocketStream >> waitForData [

	[ self isDataAvailable ] whileFalse
]
