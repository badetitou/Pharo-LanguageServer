Class {
	#name : 'PLPDummyServer',
	#superclass : 'PLSServer',
	#category : 'PharoLanguageProtocol-Tests',
	#package : 'PharoLanguageProtocol-Tests'
}

{ #category : 'lsp - completion' }
PLPDummyServer >> longServerMethod [

	<jrpc: #'plptest/longServerMethod'>
	'hello' traceCr.
	30 second wait.
	^ { (#answer -> 'until the end') } asDictionary asJRPCJSON
]

{ #category : 'lsp - completion' }
PLPDummyServer >> serverAnwserWithAccent [

	<jrpc: #'plptest/frenchAccent'>
	^ { (#answer -> 'écrit du çode bizarre') } asDictionary asJRPCJSON
]

{ #category : 'lsp - completion' }
PLPDummyServer >> textDocumentInlineCompletionWithContext: context position: position textDocument: textDocument [

	<jrpc: #'textDocument/inlineCompletion'>
	'hello' traceCr.
	30 second wait.
	^ { (#answer -> 'until the end') } asDictionary asJRPCJSON
]
