Class {
	#name : #DAPScope,
	#superclass : #DAPJsonableObject,
	#instVars : [
		'name',
		'variablesReference',
		'expensive'
	],
	#category : #'PharoDAP-Types'
}

{ #category : #accessing }
DAPScope >> asDAPJSON [
	^ super asDAPJSON
		at: #expensive put: self expensive;
		at: #name put: self name;
		at: #variablesReference put: self variablesReference;
		yourself
]

{ #category : #accessing }
DAPScope >> expensive [
	^ expensive
]

{ #category : #accessing }
DAPScope >> expensive: anObject [
	expensive := anObject
]

{ #category : #accessing }
DAPScope >> initialize [ 
	super initialize.
	expensive := false
]

{ #category : #accessing }
DAPScope >> name [
	^ name
]

{ #category : #accessing }
DAPScope >> name: anObject [
	name := anObject
]

{ #category : #accessing }
DAPScope >> variablesReference [
	"the variables of this scope can be retrieved by passing the value of variablesReference to the VariablesRequest."
	^ variablesReference
]

{ #category : #accessing }
DAPScope >> variablesReference: anObject [
	variablesReference := anObject
]
