Extension { #name : #Exception }

{ #category : #'*PharoLanguageServer' }
Exception >> asPLSCellOutput [

	^ { (PLSCellOutput
		   content: self messageText
		   mimetype: PLSCellMimetype errorType) }
]
