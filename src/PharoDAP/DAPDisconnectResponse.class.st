Class {
	#name : #DAPDisconnectResponse,
	#superclass : #DAPResponse,
	#category : #'PharoDAP-Structure'
}

{ #category : #accessing }
DAPDisconnectResponse >> asDAPJSON [
	^ Dictionary new
]
