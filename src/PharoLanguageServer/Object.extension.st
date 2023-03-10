Extension { #name : #Object }

{ #category : #'*PharoLanguageServer' }
Object >> asPLSCellOutput [

	^ { (PLSCellOutput
		   content: (self printStringLimitedTo: 50000)
		   mimetype: PLSCellMimetype html) }
]

{ #category : #'*PharoLanguageServer' }
Object >> plsPrintString [
	^ String streamContents: [ :stream | self printOn: stream ]
]
