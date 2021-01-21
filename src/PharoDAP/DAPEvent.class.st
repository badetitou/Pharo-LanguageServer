Class {
	#name : #DAPEvent,
	#superclass : #DAPMessage,
	#instVars : [
		'event',
		'body'
	],
	#category : #'PharoDAP-Structure'
}

{ #category : #converting }
DAPEvent >> asDAPJSON [
	| dic |
	dic := super asDAPJSON.
	self body ifNotNil: [ dic add: #body -> self body asDAPJSON ].
	self event ifNotNil: [ dic add: #event -> self event ].
	^ dic
]

{ #category : #accessing }
DAPEvent >> body [
	^ body
]

{ #category : #accessing }
DAPEvent >> body: anObject [
	body := anObject
]

{ #category : #accessing }
DAPEvent >> event [
	^ event
]

{ #category : #accessing }
DAPEvent >> event: anObject [
	event := anObject
]

{ #category : #'as yet unclassified' }
DAPEvent >> initialize [
	super initialize.
	type := 'event'
]
