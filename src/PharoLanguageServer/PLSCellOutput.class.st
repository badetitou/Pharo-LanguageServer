Class {
	#name : #PLSCellOutput,
	#superclass : #Object,
	#instVars : [
		'mimetype',
		'content'
	],
	#category : 'PharoLanguageServer-Structure-Moosebook'
}

{ #category : #'as yet unclassified' }
PLSCellOutput class >> content: content mimetype: aPLSCellMimetypeValue [
	^ self new
		content: content;
		mimetype: aPLSCellMimetypeValue;
		yourself
]

{ #category : #converting }
PLSCellOutput >> asJRPCJSON [
	^ {(#mimetype -> self mimetype asJRPCJSON).
	(#content -> self content asJRPCJSON)} asDictionary
]

{ #category : #accessing }
PLSCellOutput >> content [

	^ content
]

{ #category : #accessing }
PLSCellOutput >> content: anObject [

	content := anObject
]

{ #category : #accessing }
PLSCellOutput >> mimetype [

	^ mimetype
]

{ #category : #accessing }
PLSCellOutput >> mimetype: anObject [

	mimetype := anObject
]
