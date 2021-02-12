Extension { #name : #RTView }

{ #category : #'*PLS-Pharo8-Extension' }
RTView >> plsPrintString [
	^ String streamContents: [ :stream | (RTSVGExporter new view: self) exportOnStream: stream ]
]
