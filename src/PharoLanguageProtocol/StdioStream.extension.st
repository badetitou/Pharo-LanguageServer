Extension { #name : 'StdioStream' }

{ #category : '*PharoLanguageProtocol' }
StdioStream >> plpNext: numberOfData [
	self waitForData.
	^ self next: numberOfData
]
