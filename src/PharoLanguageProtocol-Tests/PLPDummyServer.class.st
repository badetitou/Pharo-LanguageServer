Class {
	#name : #PLPDummyServer,
	#superclass : #PLSServer,
	#category : #'PharoLanguageProtocol-Tests'
}

{ #category : #'lsp - completion' }
PLPDummyServer >> longServerMethod [

	<jrpc: #'plptest/longServerMethod'>
	'hello' traceCr.
	5 second wait.
	^ { (#answer -> 'until the end') } asDictionary asJRPCJSON
]
