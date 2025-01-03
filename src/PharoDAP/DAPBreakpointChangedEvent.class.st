Class {
	#name : 'DAPBreakpointChangedEvent',
	#superclass : 'DAPBreakpointEvent',
	#category : 'PharoDAP-Structure',
	#package : 'PharoDAP',
	#tag : 'Structure'
}

{ #category : 'initialization' }
DAPBreakpointChangedEvent >> initialize [ 
	super initialize.
	self body at:#reason put:#changed
]
