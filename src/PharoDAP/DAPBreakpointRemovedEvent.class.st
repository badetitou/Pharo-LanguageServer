Class {
	#name : 'DAPBreakpointRemovedEvent',
	#superclass : 'DAPBreakpointEvent',
	#category : 'PharoDAP-Structure',
	#package : 'PharoDAP',
	#tag : 'Structure'
}

{ #category : 'initialization' }
DAPBreakpointRemovedEvent >> initialize [ 
	super initialize.
	self body at:#reason put:#removed
]
