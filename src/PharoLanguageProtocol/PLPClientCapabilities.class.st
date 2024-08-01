Class {
	#name : 'PLPClientCapabilities',
	#superclass : 'Object',
	#instVars : [
		'workspace',
		'textDocument',
		'notebookDocument',
		'window',
		'general',
		'experimental'
	],
	#category : 'PharoLanguageProtocol-Initialize',
	#package : 'PharoLanguageProtocol',
	#tag : 'Initialize'
}

{ #category : 'instance creation' }
PLPClientCapabilities class >> from: aDictionary [

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
		ifPresent: [ :workspace | instance workspace: workspace ].
	^ instance
]

{ #category : 'accessing' }
PLPClientCapabilities >> asJRPCJSON [

	| dic |
	dic := Dictionary new.
	self experimental ifNotNil: [ :el | 
		dic at: #experimental put: el asJRPCJSON ].
	self general ifNotNil: [ :el | dic at: #general put: el asJRPCJSON ].
	self notebookDocument ifNotNil: [ :el | 
		dic at: #notebookDocument put: el asJRPCJSON ].
	self textDocument ifNotNil: [ :el | 
		dic at: #textDocument put: el asJRPCJSON ].
	self window ifNotNil: [ :el | dic at: #window put: el asJRPCJSON ].
	self workspace ifNotNil: [ :el | 
		dic at: #workspace put: el asJRPCJSON ].
	^ dic
]

{ #category : 'accessing' }
PLPClientCapabilities >> experimental [

	^ experimental
]

{ #category : 'accessing' }
PLPClientCapabilities >> experimental: anObject [

	experimental := anObject
]

{ #category : 'accessing' }
PLPClientCapabilities >> general [

	^ general
]

{ #category : 'accessing' }
PLPClientCapabilities >> general: anObject [

	general := anObject
]

{ #category : 'accessing' }
PLPClientCapabilities >> notebookDocument [

	^ notebookDocument
]

{ #category : 'accessing' }
PLPClientCapabilities >> notebookDocument: anObject [

	notebookDocument := anObject
]

{ #category : 'accessing' }
PLPClientCapabilities >> textDocument [

	^ textDocument
]

{ #category : 'accessing' }
PLPClientCapabilities >> textDocument: anObject [

	textDocument := anObject
]

{ #category : 'accessing' }
PLPClientCapabilities >> window [

	^ window
]

{ #category : 'accessing' }
PLPClientCapabilities >> window: anObject [

	window := anObject
]

{ #category : 'accessing' }
PLPClientCapabilities >> workspace [

	^ workspace
]

{ #category : 'accessing' }
PLPClientCapabilities >> workspace: anObject [

	workspace := anObject
]
