Extension { #name : 'JRPCSuccessResponseObject' }

{ #category : '*PharoLanguageServer' }
JRPCSuccessResponseObject >> beHandledBy: aPLSMessageProcessor [ 
	^ aPLSMessageProcessor handleJRPCSuccessResponseObject: self
]
