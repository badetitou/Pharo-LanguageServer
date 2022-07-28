Class {
	#name : #PLSMessageProcessor,
	#superclass : #JRPCMessageProcessor,
	#category : #'PharoLanguageServer-Handler'
}

{ #category : #initialization }
PLSMessageProcessor >> addHandlersFromPragmasIn: anObject [

	( Pragma allNamed: #jrpc: in: anObject class )
		do: [ :pragma | 
			self
				addHandler:
					( PLSMessageSendHandler new
						receiver: anObject;
						methodName: pragma arguments first;
						messageSelector: pragma methodSelector;
						yourself )
			]
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
