Class {
	#name : #PLSDiagnosticOptions,
	#superclass : #Object,
	#instVars : [
		'identifier',
		'interFileDependencies',
		'workspaceDiagnostics'
	],
	#category : #'PharoLanguageServer-Structure-Capabilities'
}

{ #category : #accessing }
PLSDiagnosticOptions >> asJRPCJSON [

	| dic |
	dic := { 
		       (#workspaceDiagnostics
		        -> self workspaceDiagnostics asJRPCJSON).
		       (#interFileDependencies
		        -> self interFileDependencies asJRPCJSON) } asDictionary.
	self identifier ifNotNil: [ 
		dic at: #identifier put: self identifier asJRPCJSON ].
	^ dic
]

{ #category : #accessing }
PLSDiagnosticOptions >> identifier [

	^ identifier
]

{ #category : #accessing }
PLSDiagnosticOptions >> identifier: anObject [

	identifier := anObject
]

{ #category : #accessing }
PLSDiagnosticOptions >> interFileDependencies [

	^ interFileDependencies
]

{ #category : #accessing }
PLSDiagnosticOptions >> interFileDependencies: anObject [

	interFileDependencies := anObject
]

{ #category : #accessing }
PLSDiagnosticOptions >> workspaceDiagnostics [

	^ workspaceDiagnostics
]

{ #category : #accessing }
PLSDiagnosticOptions >> workspaceDiagnostics: anObject [

	workspaceDiagnostics := anObject
]
