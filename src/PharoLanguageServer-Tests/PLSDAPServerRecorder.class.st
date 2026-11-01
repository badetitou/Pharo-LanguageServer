"
I am a DAP server that keeps the messages it sends instead of writing them to a socket, for the tests.
"
Class {
	#name : 'PLSDAPServerRecorder',
	#superclass : 'DAPServer',
	#instVars : [
		'messages'
	],
	#category : 'PharoLanguageServer-Tests',
	#package : 'PharoLanguageServer-Tests'
}

{ #category : 'handlers management' }
PLSDAPServerRecorder >> addHandlersFromPragmasIn: handlerInstance [
	"The handlers are the methods of DAPServer"

	(Pragma allNamed: #dap: from: handlerInstance class to: DAPServer)
		do: [ :pragma |
				self addHandler: (DAPHandler new
						 receiver: handlerInstance;
						 methodName: pragma arguments first;
						 messageSelector: pragma methodSelector;
						 yourself) ]
]

{ #category : 'running' }
PLSDAPServerRecorder >> events: name [

	^ self messages select: [ :message |
			  (message at: #type ifAbsent: [ nil ]) = 'event' and: [
				  (message at: #event ifAbsent: [ nil ]) = name ] ]
]

{ #category : 'running' }
PLSDAPServerRecorder >> messages [

	^ messages ifNil: [ messages := OrderedCollection new ]
]

{ #category : 'running' }
PLSDAPServerRecorder >> request: command arguments: arguments [
	"Handle a request and answer the response to it, if any"

	| request |
	request := DAPRequest new
		           seq: 1000 + self messages size;
		           command: command;
		           arguments: arguments asDictionary;
		           yourself.
	self handleRequest: request.
	^ self messages
		  detect: [ :message |
				  (message at: #type ifAbsent: [ nil ]) = 'response' and: [
					  (message at: #request_seq ifAbsent: [ nil ]) = request seq ] ]
		  ifNone: [ nil ]
]

{ #category : 'running' }
PLSDAPServerRecorder >> sendMessage: aDAPMessage [
	"Keep the message as the client reads it"

	self messages add:
		(STONJSON fromString: (STONJSON toString: aDAPMessage asDAPJSON))
]

{ #category : 'running' }
PLSDAPServerRecorder >> stop [
	"No socket to close"

	
]
