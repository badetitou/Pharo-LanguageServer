Class {
	#name : 'PLCAnswerProcessor',
	#superclass : 'Object',
	#instVars : [
		'answerHandlers',
		'client'
	],
	#category : 'PharoLanguageClient',
	#package : 'PharoLanguageClient'
}

{ #category : 'instance creation' }
PLCAnswerProcessor class >> for: aTPLCClient [

	^ self new
		  client: aTPLCClient;
		  yourself
]

{ #category : 'adding' }
PLCAnswerProcessor >> addHandlerFor: aRequest [

	(Pragma allNamed: #jrpc: in: client class)
		detect: [ :pragma |
		(pragma argumentNamed: #jrpc:) = aRequest method ]
		ifFound: [ :pragma |
			self answerHandlers
				at: aRequest id
				put: (PLSMessageSendHandler new
						 receiver: client;
						 methodName: pragma arguments first;
						 messageSelector: pragma methodSelector;
						 originRequest: aRequest;
						 yourself) ]
]

{ #category : 'accessing' }
PLCAnswerProcessor >> answerHandlers [

	^ answerHandlers
]

{ #category : 'accessing' }
PLCAnswerProcessor >> answerHandlers: anObject [

	answerHandlers := anObject
]

{ #category : 'accessing' }
PLCAnswerProcessor >> client [

	^ client
]

{ #category : 'accessing' }
PLCAnswerProcessor >> client: anObject [

	client := anObject
]

{ #category : 'adding' }
PLCAnswerProcessor >> handle: aRequest [

	| serializedRequest |
	serializedRequest := STONJSON fromString: aRequest.
	serializedRequest
		at: #id
		ifPresent: [ :id |
			self answerHandlers at: id ifPresent: [ :h |
				self answerHandlers removeKey: id.
				h executeWithArguments: (serializedRequest at: #result) ] ]
		ifAbsent: [
			(Pragma allNamed: #jrpc: in: client class)
				detect: [ :pragma |
					(pragma argumentNamed: #jrpc:) = (serializedRequest at: #method) ]
				ifFound: [ :pragma |
					PLSMessageSendHandler new
						receiver: client;
						methodName: pragma arguments first;
						messageSelector: pragma methodSelector;
						executeWithArguments: (serializedRequest at: #params) ]
				ifNone: [  ] ]
]

{ #category : 'initialization' }
PLCAnswerProcessor >> initialize [

	super initialize.
	self answerHandlers: Dictionary new
]

{ #category : 'adding' }
PLCAnswerProcessor >> removeHandlerWithId: anID [

	self answerHandlers removeKey: anID ifAbsent: [  ]
]
