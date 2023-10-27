Extension { #name : 'Form' }

{ #category : '*PharoLanguageServer' }
Form >> asPLSCellOutput [

	^ { 
		  (PLSCellOutput
			   content: self plsPrintString
			   mimetype: PLSCellMimetype markdown).
		  (PLSCellOutput
			   content: self plsPrintString
			   mimetype: PLSCellMimetype html) }
]

{ #category : '*PharoLanguageServer' }
Form >> plsPrintString [

	^ '![png tester2](data:image/png;base64,'
	  , (ByteArray streamContents: [ :stream | 
			   PNGReadWriter putForm: self onStream: stream ]) base64Encoded
	  , ')'
]
