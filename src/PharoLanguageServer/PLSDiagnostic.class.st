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
		'source'
	],
	#category : #'PharoLanguageServer-Structure-Diagnostic'
}

{ #category : #accessing }
PLSDiagnostic >> asJRPCJSON [
	^ {(#message -> self message asJRPCJSON).
	(#range -> self range asJRPCJSON).
	(#source -> self source asJRPCJSON)} asDictionary
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
