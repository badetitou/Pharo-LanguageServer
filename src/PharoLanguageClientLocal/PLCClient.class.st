Class {
	#name : 'PLCClient',
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
PLCClient class >> default [

	^ default ifNil: [ default := self new ]
]

{ #category : 'accessing' }
PLCClient class >> default: aPLCClient [

	default := aPLCClient
]

{ #category : 'accessing' }
PLCClient class >> reset [

	<script>
	self default stop.
	self default: nil
]

{ #category : 'initialization' }
PLCClient >> initialize [

	self startWithLocalServer.
	super initialize
]

{ #category : 'lsp - initialization' }
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
