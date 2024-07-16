Class {
	#name : 'PLCLocalClient',
	#superclass : 'Object',
	#traits : 'TPLCClient',
	#classTraits : 'TPLCClient classTrait',
	#classInstVars : [
		'default'
	],
	#category : 'PharoLanguageClientLocal',
	#package : 'PharoLanguageClientLocal'
}

{ #category : 'accessing' }
PLCLocalClient class >> default [

	^ default ifNil: [ default := self new ]
]

{ #category : 'accessing' }
PLCLocalClient class >> default: aPLCClient [

	default := aPLCClient
]

{ #category : 'accessing' }
PLCLocalClient class >> initialize [

	Smalltalk addToStartUpList: self.
	self reset
]

{ #category : 'accessing' }
PLCLocalClient class >> inspect [

	<script>
	self default inspect
]

{ #category : 'accessing' }
PLCLocalClient class >> menuCommandOn: aBuilder [
	<worldMenu>
	
	(aBuilder item: #PharoLanguageClient)
		order: 410
]

{ #category : 'accessing' }
PLCLocalClient class >> reset [

	<script>
	default ifNotNil: [ default stop ].
	self default: nil
]

{ #category : 'accessing' }
PLCLocalClient class >> startUp: isImageStarting [

	isImageStarting ifTrue: [ self reset ]
]

{ #category : 'lsp - completion' }
PLCLocalClient >> clientInlineCompletionFrom: items fromRequest: originRequest [

	<jrpc: #'textDocument/inlineCompletion'>
	| originUri |
	originUri := originRequest params at: #textDocument at: #uri.
	(context textItem: originUri) clientInlineCompletionFrom: items
]

{ #category : 'initialization' }
PLCLocalClient >> initialize [

	self startWithLocalServer.
	super initialize
]

{ #category : 'lsp - initialization' }
PLCLocalClient >> sendInitialize [

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
