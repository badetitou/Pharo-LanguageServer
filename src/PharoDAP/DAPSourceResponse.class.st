Class {
	#name : #DAPSourceResponse,
	#superclass : #DAPResponse,
	#category : #'PharoDAP-Structure'
}

{ #category : #initialization }
DAPSourceResponse >> content: string [
	self body at: #content put: string 
]

{ #category : #initialization }
DAPSourceResponse >> initialize [
	super initialize.
	body := Dictionary new
]
