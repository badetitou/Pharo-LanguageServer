Class {
	#name : #DAPThreadsResponse,
	#superclass : #DAPResponse,
	#instVars : [
		'threads'
	],
	#category : #'PharoDAP-Structure'
}

{ #category : #initialization }
DAPThreadsResponse >> asDAPJSON [
	| dic |
	self body at: #threads put: threads asArray.
	dic := super asDAPJSON.
	^ dic
]

{ #category : #initialization }
DAPThreadsResponse >> initialize [
	super initialize.
	body := Dictionary new.
	threads := OrderedCollection new.
]

{ #category : #accessing }
DAPThreadsResponse >> threads [
	^ threads
]

{ #category : #accessing }
DAPThreadsResponse >> threads: anObject [
	threads := anObject
]
