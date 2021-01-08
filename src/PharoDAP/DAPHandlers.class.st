"
I contain the handlers called by the dap server
"
Class {
	#name : #DAPHandlers,
	#superclass : #Object,
	#category : #PharoDAP
}

{ #category : #'as yet unclassified' }
DAPHandlers >> dapInitialize [
	<dap: #'initialize'>
	1h.
	^ DAPInitializeResponse new
]
