Class {
	#name : #DAPOupsDebuggerSelector,
	#superclass : #OupsSingleDebuggerSelector,
	#category : #'PharoDAP-Oups'
}

{ #category : #iterating }
DAPOupsDebuggerSelector >> nextDebugger [
	Transcript crShow: 'dap next debugger'.
	^ debuggers first
]

{ #category : #iterating }
DAPOupsDebuggerSelector >> with: blabla [
	
]
