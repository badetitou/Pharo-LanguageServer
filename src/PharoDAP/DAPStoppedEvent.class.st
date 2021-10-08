Class {
	#name : #DAPStoppedEvent,
	#superclass : #DAPEvent,
	#instVars : [
		'description',
		'reason',
		'threadId',
		'preserveFocusHint',
		'text',
		'allThreadsStopped'
	],
	#category : #'PharoDAP-Structure'
}

{ #category : #accessing }
DAPStoppedEvent >> allThreadsStopped [
	^ allThreadsStopped ifNil:[ allThreadsStopped := true ]
]

{ #category : #accessing }
DAPStoppedEvent >> allThreadsStopped: anObject [
	allThreadsStopped := anObject
]

{ #category : #'as yet unclassified' }
DAPStoppedEvent >> asDAPJSON [
	| dic |
	self body at: #reason put: self reason.
	self body at: #description put: self description printString.
	self body at: #threadId put: self threadId.
	self body at: #allThreadsStopped put: self allThreadsStopped.
	dic := super asDAPJSON.
	^ dic
]

{ #category : #accessing }
DAPStoppedEvent >> description [
	^ description
]

{ #category : #accessing }
DAPStoppedEvent >> description: anObject [
	description := anObject
]

{ #category : #'as yet unclassified' }
DAPStoppedEvent >> initialize [
	super initialize.
	body := Dictionary new.
	event := 'stopped'
]

{ #category : #accessing }
DAPStoppedEvent >> preserveFocusHint [
	^ preserveFocusHint
]

{ #category : #accessing }
DAPStoppedEvent >> preserveFocusHint: anObject [
	preserveFocusHint := anObject
]

{ #category : #accessing }
DAPStoppedEvent >> reason [
	"'step' | 'breakpoint' | 'exception' | 'pause' | 'entry' | 'goto'
        | 'function breakpoint' | 'data breakpoint' | 'instruction breakpoint'
        | string"

	^ reason
]

{ #category : #accessing }
DAPStoppedEvent >> reason: anObject [
	reason := anObject
]

{ #category : #accessing }
DAPStoppedEvent >> text [
	^ text
]

{ #category : #accessing }
DAPStoppedEvent >> text: anObject [
	text := anObject
]

{ #category : #accessing }
DAPStoppedEvent >> threadId [
	^ threadId
]

{ #category : #accessing }
DAPStoppedEvent >> threadId: anObject [
	threadId := anObject
]
