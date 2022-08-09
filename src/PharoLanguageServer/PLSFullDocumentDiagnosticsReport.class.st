Class {
	#name : #PLSFullDocumentDiagnosticsReport,
	#superclass : #Object,
	#instVars : [
		'kind',
		'resultId',
		'items'
	],
	#category : #'PharoLanguageServer-Structure-Diagnostic'
}

{ #category : #initialization }
PLSFullDocumentDiagnosticsReport >> asJRPCJSON [

	| dic |
	dic := { 
		       (#kind -> self kind asJRPCJSON).
		       (#items -> self items asJRPCJSON) } asDictionary.
	self resultId ifNotNil: [ 
		dic at: #resultId put: self resultId asJRPCJSON ].
	^ dic
]

{ #category : #initialization }
PLSFullDocumentDiagnosticsReport >> initialize [
	super initialize.
	self kind: 'full'
]

{ #category : #accessing }
PLSFullDocumentDiagnosticsReport >> items [

	^ items
]

{ #category : #accessing }
PLSFullDocumentDiagnosticsReport >> items: anObject [

	items := anObject
]

{ #category : #accessing }
PLSFullDocumentDiagnosticsReport >> kind [

	^ kind
]

{ #category : #accessing }
PLSFullDocumentDiagnosticsReport >> kind: anObject [

	kind := anObject
]

{ #category : #accessing }
PLSFullDocumentDiagnosticsReport >> resultId [

	^ resultId
]

{ #category : #accessing }
PLSFullDocumentDiagnosticsReport >> resultId: anObject [

	resultId := anObject
]
