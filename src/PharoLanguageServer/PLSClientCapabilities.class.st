Class {
	#name : #PLSClientCapabilities,
	#superclass : #Object,
	#instVars : [
		'workspace',
		'textDocument',
		'notebookDocument',
		'window',
		'general',
		'experimental'
	],
	#category : #'PharoLanguageServer-Structure-Capabilities'
}

{ #category : #'instance creation' }
PLSClientCapabilities class >> from: aDictionary [

	| instance |
	instance := self new.
	aDictionary
		at: #experimental
		ifPresent: [ :exp | instance experimental: exp ].
	aDictionary
		at: #general
		ifPresent: [ :general | instance general: general ].
	aDictionary
		at: #notebookDocument
		ifPresent: [ :notebookDocument | 
		instance notebookDocument: notebookDocument ].
	aDictionary at: #textDocument ifPresent: [ :textDocument | 
		instance textDocument:
			(PLSTextDocumentClientCapabilities from: textDocument) ].
	aDictionary
		at: #workspace
		ifPresent: [ :workspace | instance workspace: workspace ]
]

{ #category : #accessing }
PLSClientCapabilities >> experimental [

	^ experimental
]

{ #category : #accessing }
PLSClientCapabilities >> experimental: anObject [

	experimental := anObject
]

{ #category : #accessing }
PLSClientCapabilities >> general [

	^ general
]

{ #category : #accessing }
PLSClientCapabilities >> general: anObject [

	general := anObject
]

{ #category : #accessing }
PLSClientCapabilities >> notebookDocument [

	^ notebookDocument
]

{ #category : #accessing }
PLSClientCapabilities >> notebookDocument: anObject [

	notebookDocument := anObject
]

{ #category : #accessing }
PLSClientCapabilities >> textDocument [

	^ textDocument
]

{ #category : #accessing }
PLSClientCapabilities >> textDocument: anObject [

	textDocument := anObject
]

{ #category : #accessing }
PLSClientCapabilities >> window [

	^ window
]

{ #category : #accessing }
PLSClientCapabilities >> window: anObject [

	window := anObject
]

{ #category : #accessing }
PLSClientCapabilities >> workspace [

	^ workspace
]

{ #category : #accessing }
PLSClientCapabilities >> workspace: anObject [

	workspace := anObject
]
