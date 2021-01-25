Class {
	#name : #DAPStackFrame,
	#superclass : #DAPJsonableObject,
	#instVars : [
		'id',
		'name',
		'line',
		'column',
		'source',
		'endLine',
		'endColumn',
		'instructionPointerReference',
		'moduleId',
		'presentationHint'
	],
	#category : #'PharoDAP-Types'
}

{ #category : #initialization }
DAPStackFrame >> asDAPJSON [
	| dic |
	dic := super asDAPJSON
		at: #id put: self id;
		at: #name put: self name;
		at: #line put: self line;
		yourself.
	self source ifNotNil: [ dic at: #source put: self source asDAPJSON ].
	self column ifNotNil: [ dic at: #column put: self column asDAPJSON ].
	
	^ dic
]

{ #category : #accessing }
DAPStackFrame >> column [
	^ column
]

{ #category : #accessing }
DAPStackFrame >> column: anObject [
	column := anObject
]

{ #category : #accessing }
DAPStackFrame >> id [
	^ id
]

{ #category : #accessing }
DAPStackFrame >> id: anObject [
	id := anObject
]

{ #category : #initialization }
DAPStackFrame >> initialize [
	super initialize.
	line := 0.
	column := 0
]

{ #category : #accessing }
DAPStackFrame >> line [
	^ line
]

{ #category : #accessing }
DAPStackFrame >> line: anObject [
	line := anObject
]

{ #category : #accessing }
DAPStackFrame >> name [
	^ name
]

{ #category : #accessing }
DAPStackFrame >> name: anObject [
	name := anObject
]

{ #category : #accessing }
DAPStackFrame >> source [
	^ source
]

{ #category : #accessing }
DAPStackFrame >> source: anObject [
	source := anObject
]
