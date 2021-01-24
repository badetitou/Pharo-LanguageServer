Class {
	#name : #DAPContinueResponse,
	#superclass : #DAPResponse,
	#instVars : [
		'allThreadsContinued'
	],
	#category : #'PharoDAP-Structure'
}

{ #category : #accessing }
DAPContinueResponse >> allThreadsContinued [
	"If true, the 'continue' request has ignored the specified thread and continued all threads instead.
     If this attribute is missing a value of 'true' is assumed for backward compatibility."

	^ allThreadsContinued
]

{ #category : #accessing }
DAPContinueResponse >> allThreadsContinued: anObject [
	allThreadsContinued := anObject
]

{ #category : #accessing }
DAPContinueResponse >> asDAPJSON [
	| dic |
	self body at: #allThreadsContinued put: self allThreadsContinued.
	dic := super asDAPJSON.
	^ dic
]

{ #category : #initialization }
DAPContinueResponse >> initialize [
	super initialize.
	body := Dictionary new.
	"set to true by default until we can undle multi thread debugging"
	allThreadsContinued := true
]
