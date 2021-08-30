Class {
	#name : #DAPBreakpointCreatedEvent,
	#superclass : #DAPBreakpointEvent,
	#category : #'PharoDAP-Structure'
}

{ #category : #initialization }
DAPBreakpointCreatedEvent >> initialize [ 
	super initialize.
	self body at:#reason put:#new
]
