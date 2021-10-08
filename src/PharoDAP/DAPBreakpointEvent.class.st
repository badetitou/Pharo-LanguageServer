Class {
	#name : #DAPBreakpointEvent,
	#superclass : #DAPEvent,
	#category : #'PharoDAP-Structure'
}

{ #category : #'instance creation' }
DAPBreakpointEvent class >> newFromABreakpoint: aBpDictionary [
	| i |
	i:= self new.
	i body at:#breakpoint put:aBpDictionary.
	^ i
				
]

{ #category : #initialization }
DAPBreakpointEvent >> initialize [
	super initialize.
	self event: 'breakpoint'.
	self body: Dictionary new
]
