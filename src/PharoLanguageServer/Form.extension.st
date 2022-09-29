Extension { #name : #Form }

{ #category : #'*PharoLanguageServer' }
Form >> plsMimeType [
	"Answer a String whose characters are a description of the receiver. 
	If you want to print without a character limit, use fullPrintString."

	^ 'text/markdown'
]

{ #category : #'*PharoLanguageServer' }
Form >> plsPrintString [

	^ '![png tester2](data:image/png;base64,'
	  , (ByteArray streamContents: [ :stream | 
			   PNGReadWriter putForm: self onStream: stream ]) base64Encoded
	  , ')'
]
