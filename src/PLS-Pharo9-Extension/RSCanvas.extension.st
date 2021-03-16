Extension { #name : #RSCanvas }

{ #category : #'*PLS-Pharo9-Extension' }
RSCanvas >> plsMimeType [
	"Answer a String whose characters are a description of the receiver. 
	If you want to print without a character limit, use fullPrintString."

	^ 'image/png'
]

{ #category : #'*PLS-Pharo9-Extension' }
RSCanvas >> plsPrintString [

	^ (self createMorph extent: 500 @ 500) asForm plsPrintString
]
