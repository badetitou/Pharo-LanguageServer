Extension { #name : #RSCanvas }

{ #category : #'*PLS-Pharo9-Extension' }
RSCanvas >> asPLSCellOutput [

	^ { (PLSCellOutput
		   content:
		   (self createMorph extent: 500 @ 500) asForm plsPrintString
		   mimetype: PLSCellMimetype markdown) }
]
