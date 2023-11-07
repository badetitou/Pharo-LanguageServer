Class {
	#name : #PLSCodeAction,
	#superclass : #Object,
	#instVars : [
		'title',
		'kind',
		'diagnostics',
		'isPreferred',
		'disabled',
		'edit',
		'command',
		'data'
	],
	#category : 'PharoLanguageServer-Structure-CodeAction'
}

{ #category : #accessing }
PLSCodeAction >> asJRPCJSON [

	| dictionary |
	dictionary := { (#title -> self title) } asDictionary.
	self kind ifNotNil: [ dictionary at: #kind put: self kind asJRPCJSON ].
	self diagnostics ifNotNil: [ 
		dictionary at: #diagnostics put: self diagnostics asJRPCJSON ].
	self isPreferred ifNotNil: [ 
		dictionary at: #isPreferred put: self isPreferred asJRPCJSON ].
	self disabled ifNotNil: [ 
		dictionary at: #disabled put: self disabled asJRPCJSON ].
	self edit ifNotNil: [ dictionary at: #edit put: self edit asJRPCJSON ].
	self command ifNotNil: [ 
		dictionary at: #command put: self command asJRPCJSON ].
	self data ifNotNil: [ dictionary at: #data put: self data asJRPCJSON ].
	^ dictionary
]

{ #category : #accessing }
PLSCodeAction >> command [

	^ command
]

{ #category : #accessing }
PLSCodeAction >> command: anObject [

	command := anObject
]

{ #category : #accessing }
PLSCodeAction >> data [

	^ data
]

{ #category : #accessing }
PLSCodeAction >> data: anObject [

	data := anObject
]

{ #category : #accessing }
PLSCodeAction >> diagnostics [

	^ diagnostics
]

{ #category : #accessing }
PLSCodeAction >> diagnostics: anObject [

	diagnostics := anObject
]

{ #category : #accessing }
PLSCodeAction >> disabled [

	^ disabled
]

{ #category : #accessing }
PLSCodeAction >> disabled: anObject [

	disabled := anObject
]

{ #category : #accessing }
PLSCodeAction >> edit [

	^ edit
]

{ #category : #accessing }
PLSCodeAction >> edit: anObject [

	edit := anObject
]

{ #category : #accessing }
PLSCodeAction >> isPreferred [

	^ isPreferred
]

{ #category : #accessing }
PLSCodeAction >> isPreferred: anObject [

	isPreferred := anObject
]

{ #category : #accessing }
PLSCodeAction >> kind [

	^ kind
]

{ #category : #accessing }
PLSCodeAction >> kind: anObject [

	kind := anObject
]

{ #category : #accessing }
PLSCodeAction >> title [

	^ title
]

{ #category : #accessing }
PLSCodeAction >> title: anObject [

	title := anObject
]
