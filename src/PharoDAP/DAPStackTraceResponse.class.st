Class {
	#name : #DAPStackTraceResponse,
	#superclass : #DAPResponse,
	#instVars : [
		'stackFrames',
		'totalFrames'
	],
	#category : #'PharoDAP-Structure'
}

{ #category : #initialization }
DAPStackTraceResponse >> asDAPJSON [
	| dic |
	self body at: #stackFrames put: self stackFrames asArray.
	dic := super asDAPJSON.
	^ dic
]

{ #category : #initialization }
DAPStackTraceResponse >> initialize [
	super initialize.
	body := Dictionary new.
	stackFrames := OrderedCollection new.
]

{ #category : #accessing }
DAPStackTraceResponse >> stackFrames [
	^ stackFrames
]

{ #category : #accessing }
DAPStackTraceResponse >> stackFrames: anObject [
	stackFrames := anObject
]
