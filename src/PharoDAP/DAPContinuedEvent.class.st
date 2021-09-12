Class {
	#name : #DAPContinuedEvent,
	#superclass : #DAPEvent,
	#instVars : [
		'threadId',
		'allThreadsContinued'
	],
	#category : #'PharoDAP-Structure'
}

{ #category : #accessing }
DAPContinuedEvent >> allThreadsContinued [

	^ allThreadsContinued ifNil:[ allThreadsContinued := true ]
]

{ #category : #accessing }
DAPContinuedEvent >> allThreadsContinued: anObject [

	allThreadsContinued := anObject
]

{ #category : #'as yet unclassified' }
DAPContinuedEvent >> asDAPJSON [
	| dic |

	self body at: #threadId put: self threadId.
	self body at: #allThreadsContinued put: self allThreadsContinued.
	dic := super asDAPJSON.
	^ dic
]

{ #category : #'as yet unclassified' }
DAPContinuedEvent >> initialize [
	super initialize.
	body := Dictionary new.
	event := 'continued'
]

{ #category : #accessing }
DAPContinuedEvent >> threadId [
	^ threadId
]

{ #category : #accessing }
DAPContinuedEvent >> threadId: anObject [
	threadId := anObject
]
