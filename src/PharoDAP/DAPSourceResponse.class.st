Class {
	#name : 'DAPSourceResponse',
	#superclass : 'DAPResponse',
	#category : 'PharoDAP-Structure',
	#package : 'PharoDAP',
	#tag : 'Structure'
}

{ #category : 'initialization' }
DAPSourceResponse >> content: string [
	self body at: #content put: string 
]

{ #category : 'initialization' }
DAPSourceResponse >> initialize [
	super initialize.
	body := Dictionary new
]

{ #category : 'initialization' }
DAPSourceResponse >> mimeType: string [
	self body at: #mimeType put: string 
]
