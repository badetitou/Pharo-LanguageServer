Class {
	#name : #DAPResponse,
	#superclass : #DAPMessage,
	#instVars : [
		'request_seq',
		'success',
		'command',
		'message',
		'body'
	],
	#category : #'PharoDAP-Structure'
}

{ #category : #accessing }
DAPResponse >> asDAPJSON [
	| dic |
	dic := super asDAPJSON.
	self body ifNotNil: [ dic add: #body -> self body asDAPJSON ].
	self command ifNotNil: [ dic add: #command -> self command ].
	self message ifNotNil: [ dic add: #message -> self message ].
	self request_seq ifNotNil: [ dic add: #request_seq -> self request_seq ].
	self success ifNotNil: [ dic add: #success -> self success ].
	^ dic
]

{ #category : #accessing }
DAPResponse >> body [
	^ body
]

{ #category : #accessing }
DAPResponse >> body: anObject [
	body := anObject
]

{ #category : #accessing }
DAPResponse >> command [
	^ command
]

{ #category : #accessing }
DAPResponse >> command: anObject [
	command := anObject
]

{ #category : #initialization }
DAPResponse >> initialize [
	super initialize.
	type := 'response'.
	success := true
]

{ #category : #accessing }
DAPResponse >> message [
	^ message
]

{ #category : #accessing }
DAPResponse >> message: anObject [
	message := anObject
]

{ #category : #accessing }
DAPResponse >> request_seq [
	^ request_seq
]

{ #category : #accessing }
DAPResponse >> request_seq: anObject [
	request_seq := anObject
]

{ #category : #accessing }
DAPResponse >> success [
	^ success
]

{ #category : #accessing }
DAPResponse >> success: anObject [
	success := anObject
]
