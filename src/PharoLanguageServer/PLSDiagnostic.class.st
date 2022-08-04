"
I am the Diagnotic structure.
I report an error with an error message, at a position, with a message
"
Class {
	#name : #PLSDiagnostic,
	#superclass : #Object,
	#instVars : [
		'range',
		'message',
		'source',
		'codeDescription',
		'data',
		'code'
	],
	#category : #'PharoLanguageServer-Structure-Diagnostic'
}

{ #category : #accessing }
PLSDiagnostic >> asJRPCJSON [

	| dic |
	dic := { 
		       (#message -> self message asJRPCJSON).
		       (#range -> self range asJRPCJSON).
		       (#source -> self source asJRPCJSON) } asDictionary.
	self codeDescription ifNotNil: [ 
		dic at: #codeDescription put: self codeDescription asJRPCJSON ].
	self code ifNotNil: [ dic at: #code put: self code asJRPCJSON ].
	self data ifNotNil: [ dic at: #data put: self data asJRPCJSON ].
	^ dic
]

{ #category : #accessing }
PLSDiagnostic >> code [

	^ code
]

{ #category : #accessing }
PLSDiagnostic >> code: anObject [

	code := anObject
]

{ #category : #accessing }
PLSDiagnostic >> codeDescription [

	^ codeDescription
]

{ #category : #accessing }
PLSDiagnostic >> codeDescription: anObject [

	codeDescription := anObject
]

{ #category : #accessing }
PLSDiagnostic >> data [

	^ data
]

{ #category : #accessing }
PLSDiagnostic >> data: anObject [

	data := anObject
]

{ #category : #accessing }
PLSDiagnostic >> initialize [
	super initialize.
	source := 'Pharo Language Server'
]

{ #category : #accessing }
PLSDiagnostic >> message [
	^ message
]

{ #category : #accessing }
PLSDiagnostic >> message: anObject [
	message := anObject
]

{ #category : #accessing }
PLSDiagnostic >> range [
	^ range
]

{ #category : #accessing }
PLSDiagnostic >> range: anObject [
	range := anObject
]

{ #category : #accessing }
PLSDiagnostic >> source [
	^ source
]

{ #category : #accessing }
PLSDiagnostic >> source: anObject [
	source := anObject
]
