Class {
	#name : #PLSMessageProcessor,
	#superclass : #JRPCMessageProcessor,
	#category : 'PharoLanguageServer-Handler'
}

{ #category : #initialization }
PLSMessageProcessor >> addHandler: aJRPCHandler [

	(self handlers includes: aJRPCHandler) ifTrue: [ "handler has been override" 
		^ self ].

	handlers add: aJRPCHandler
]

{ #category : #initialization }
PLSMessageProcessor >> addHandlersFromPragmasIn: anObject [
	(anObject class withAllSuperclasses select: [ :class | 
		 (class inheritsFrom: PLSAbstractServer) or: [ 
			 class == PLSAbstractServer ] ]) do: [ :class | 
		(Pragma allNamed: #jrpc: in: class) do: [ :pragma | 
			self addHandler: (PLSMessageSendHandler new
					 receiver: anObject;
					 methodName: pragma arguments first;
					 messageSelector: pragma methodSelector;
					 yourself) ] ]
]

{ #category : #'as yet unclassified' }
PLSMessageProcessor >> handleJRPCSuccessResponseObject: aJRPCSuccessResponseObject [ 
	^ JRPCEmptyResponseObject new
]

{ #category : #initialization }
PLSMessageProcessor >> handleJSON: jrpcMessage [
	"Gets aJSONString being a request or notification serialized in JSON format as input
	 and returns a JSON string being the answer serialized in JSON format.
	"

	| jrpcResponse |
	jrpcResponse := [ jrpcMessage beHandledBy: self ]
		on: Error
		do: [ :error | 
			self debugMode
				ifTrue: [ error pass ]
				ifFalse: [ error return: error asJRPCResponse ] ].
	^ jrpcResponse beConvertedBy: self
]
