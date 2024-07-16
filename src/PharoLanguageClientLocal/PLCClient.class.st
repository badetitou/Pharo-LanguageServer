Class {
	#name : 'PLCClient',
	#superclass : 'Object',
	#traits : 'TPLCClient',
	#classTraits : 'TPLCClient classTrait',
	#category : 'PharoLanguageClientLocal',
	#package : 'PharoLanguageClientLocal'
}

{ #category : 'plp - answerLoop' }
PLCClient >> answerLoopPriority [

	^ answerLoopPriority ifNil: [
		  answerLoopPriority := Processor userBackgroundPriority ]
]

{ #category : 'lsp - symbol' }
PLCClient >> clientSymbol: items fromRequest: originRequest [

	<jrpc: #'textDocument/documentSymbol'>
	| originUri |
	originUri := originRequest params at: #textDocument at: #uri.
	(context textItem: originUri) applySymbols:
		(items collect: [ :item |
			 | symbol |
			 symbol := PLSDocumentSymbol new.
			 symbol name: (item at: #name).
			 item at: #detail ifPresent: [ :detail | symbol detail: detail ].
			 symbol kind: (item at: #kind).
			 symbol range: (PLSRange
					  start: ((item at: #location at: #range) at: #start)
					  end: ((item at: #location at: #range) at: #end)) ])
]

{ #category : 'api' }
PLCClient >> initialize [

	super initialize
]
