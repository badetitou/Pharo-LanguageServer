Extension { #name : 'ReadWriteStream' }

{ #category : '*PharoLanguageProtocol' }
ReadWriteStream >> waitForData [
	[ position < readLimit ] whileFalse
]
