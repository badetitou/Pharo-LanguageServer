Class {
	#name : 'DAPBreakpointCreatedEvent',
	#superclass : 'DAPBreakpointEvent',
	#category : 'PharoDAP-Structure',
	#package : 'PharoDAP',
	#tag : 'Structure'
}

{ #category : 'initialization' }
DAPBreakpointCreatedEvent >> initialize [ 
	super initialize.
	self body at:#reason put:#new
]
