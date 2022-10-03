Extension { #name : #RSCanvas }

{ #category : #'*PLS-Pharo9-Extension' }
RSCanvas >> asPLSCellOutput [

	| string |
	string := (self createMorph extent: 500 @ 500) asForm plsPrintString.
	^ { 
		  (PLSCellOutput content: string mimetype: PLSCellMimetype markdown).
		  (PLSCellOutput content: string mimetype: PLSCellMimetype html) }
]
