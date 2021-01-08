Class {
	#name : #DAPServer,
	#superclass : #Object,
	#instVars : [
		'port'
	],
	#category : #PharoDAP
}

{ #category : #accessing }
DAPServer >> port [
	^ port
]

{ #category : #accessing }
DAPServer >> port: anObject [
	port := anObject
]
