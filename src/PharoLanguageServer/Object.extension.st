Extension { #name : #Object }

{ #category : #'*PharoLanguageServer' }
Object >> plsMimeType [
	"Answer a String whose characters are a description of the receiver. 
	If you want to print without a character limit, use fullPrintString."

	^ 'text/html'
]

{ #category : #'*PharoLanguageServer' }
Object >> plsPrintString [
	"Answer a String whose characters are a description of the receiver. 
	If you want to print without a character limit, use fullPrintString."

	^ self printStringLimitedTo: 50000
]
