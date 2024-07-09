Class {
	#name : 'PLSUnchangedDocumentDiagnosticReport',
	#superclass : 'Object',
	#instVars : [
		'kind',
		'resultId'
	],
	#category : 'PharoLanguageServer-Structure-Diagnostic',
	#package : 'PharoLanguageServer',
	#tag : 'Structure-Diagnostic'
}

{ #category : 'accessing' }
PLSUnchangedDocumentDiagnosticReport >> asJRPCJSON [

	^ { 
		  (#kind -> self kind asJRPCJSON).
		  (#resultId -> self resultId asJRPCJSON) } asDictionary
]

{ #category : 'accessing' }
PLSUnchangedDocumentDiagnosticReport >> initialize [
	super initialize.
	self kind: 'unchanged'
]

{ #category : 'accessing' }
PLSUnchangedDocumentDiagnosticReport >> kind [

	^ kind
]

{ #category : 'accessing' }
PLSUnchangedDocumentDiagnosticReport >> kind: anObject [

	kind := anObject
]

{ #category : 'accessing' }
PLSUnchangedDocumentDiagnosticReport >> resultId [

	^ resultId
]

{ #category : 'accessing' }
PLSUnchangedDocumentDiagnosticReport >> resultId: anObject [

	resultId := anObject
]
