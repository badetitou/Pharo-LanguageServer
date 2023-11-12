Class {
	#name : #PLCClient,
	#superclass : #Object,
	#traits : 'TPLCClient',
	#classTraits : 'TPLCClient classTrait',
	#classInstVars : [
		'default'
	],
	#category : #PharoLanguageClientLocal
}

{ #category : #accessing }
PLCClient class >> default [

	^ default ifNil: [ default := self new ]
]

{ #category : #accessing }
PLCClient class >> default: aPLCClient [

	default := aPLCClient
]

{ #category : #accessing }
PLCClient class >> inspect [

	<script>
	self default inspect
]

{ #category : #accessing }
PLCClient class >> reset [

	<script>
	default ifNotNil: [ default stop ].
	self default: nil
]

{ #category : #'lsp - completion' }
PLCClient >> clientInlineCompletionFrom: items fromRequest: originRequest [

	<jrpc: #'textDocument/inlineCompletion'>
	| originUri |
	originUri := originRequest params at: #textDocument at: #uri.
	(context textItem: originUri) clientInlineCompletionFrom: items
]

{ #category : #initialization }
PLCClient >> initialize [

	self startWithLocalServer.
	super initialize
]

{ #category : #'lsp - initialization' }
PLCClient >> sendInitialize [

	self
		callMethod: 'initialize'
		arguments: (PLPInitializeParams new
				 capabilities: (PLPClientCapabilities new textDocument:
							  (PLPTextDocumentClientCapabilities new
								   inlineCompletion: true;
								   yourself));
				 clientInfo: { 
						 (#name -> 'PLCClient').
						 (#version -> 'beta') } asDictionary;
				 processId: nil;
				 yourself) asJRPCJSON
		withId: self nextId
]
