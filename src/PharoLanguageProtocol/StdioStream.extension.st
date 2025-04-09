Extension { #name : 'StdioStream' }

{ #category : '*PharoLanguageProtocol' }
StdioStream >> plpNext: numberOfData [

	^ (self next: numberOfData) asString
]
