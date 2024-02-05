Class {
	#name : #PLPTests,
	#superclass : #TestCase,
	#instVars : [
		'client',
		'server',
		'serverProcess'
	],
	#category : #'PharoLanguageProtocol-Tests'
}

{ #category : #running }
PLPTests >> plpURI [

	^ '#test/plp'
]

{ #category : #running }
PLPTests >> setUp [

	| openPort |
	super setUp.

	client := PLPDummyClient new.
	server := PLPDummyServer new.
	server debugMode: true.
	server serverLoopPriority: Processor activeProcess priority.
	client answerLoopPriority: Processor activeProcess priority.
	serverProcess := [ server start ]
		forkAt: Processor activeProcess priority
		named: 'Test PLS server'.

	[ server port = 0 ] whileTrue.
	openPort := server port.
	client port: openPort
]

{ #category : #running }
PLPTests >> tearDown [

	serverProcess terminate.
	server stop.
	super tearDown
]

{ #category : #running }
PLPTests >> testCancelRequest [
	"I test that the client can cancel a long processing request of the server"

	client start.
	client sendLongServerMethod.
	client sendCancelRequest: client currentId.
	[ client answerProcessor answerHandlers isEmpty ] whileFalse.
	[ server context messageProcesses isEmpty ] whileFalse
]

{ #category : #running }
PLPTests >> testDidChangeTextDocument [
	"I test that the client can cancel a long processing request of the server"

	| documentIdentifier |
	self testDidOpenTextDocument.
	documentIdentifier := PLSVersionedTextDocumentIdentifier new
		                      uri: self plpURI;
		                      version: 43;
		                      yourself.
	client
		sendDidChangeTextDocument: documentIdentifier
		withChanges: { (PLPTextDocumentContentChangeEvent new
				 text: 'Hello world 43';
				 yourself) }.
	[ client answerProcessor answerHandlers isEmpty ] whileFalse.
	[ (server context textItem: self plpURI) version = 43 ] whileFalse.

	self
		assert: (server context textItem: self plpURI) text
		equals: 'Hello world 43'
]

{ #category : #running }
PLPTests >> testDidChangeTextDocumentCancelLongInlineCompletion [
	"I test that the client can cancel a long processing request of the server"

	| documentIdentifier documentIdentifier42 |
	self testDidOpenTextDocument.

	documentIdentifier42 := PLSVersionedTextDocumentIdentifier new
		                        uri: self plpURI;
		                        version: 42;
		                        yourself.

	client sendTextDocument: documentIdentifier42 inlineCompletionAt: {
			(#line -> 0).
			(#character -> 0) } asDictionary.

	documentIdentifier := PLSVersionedTextDocumentIdentifier new
		                      uri: self plpURI;
		                      version: 43;
		                      yourself.
	client
		sendDidChangeTextDocument: documentIdentifier
		withChanges: { (PLPTextDocumentContentChangeEvent new
				 text: 'Hello world 43';
				 yourself) }.
	[ client answerProcessor answerHandlers isEmpty ] whileFalse.
	[ (server context textItem: self plpURI) version = 43 ] whileFalse
]

{ #category : #running }
PLPTests >> testDidOpenTextDocument [
	"I test that the client can cancel a long processing request of the server"

	| obj document |
	obj := Object new.
	document := PLPTextDocumentItem new
		            uri: self plpURI;
		            languageId: 'smalltalk';
		            version: 42;
		            text: ''.
	client start.
	client sendDidOpenTextDocument: document for: obj.
	[ client answerProcessor answerHandlers isEmpty ] whileFalse.
	[
	server context messageProcesses isEmpty and: [
		(server context
			 textItem: self plpURI
			 ifAbsent: [ PLPTextDocumentItem new ]) version = 42 ] ] whileFalse.
	self assert: (client context textItem: self plpURI) equals: obj.
	self assert: (server context textItem: self plpURI) text equals: ''.
	self
		assert: (server context textItem: self plpURI) uri
		equals: '#test/plp'
]

{ #category : #running }
PLPTests >> testInitialize [

	client start.
	[ client answerProcessor answerHandlers isEmpty ] whileFalse.
	self
		assert: (server context clientContext clientInfo at: #name)
		equals: 'PLCClient'.
	self
		assert: (client serverContext at: #name)
		equals: 'Pharo Language Server'
]
