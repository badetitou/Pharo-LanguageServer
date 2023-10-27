Class {
	#name : 'PLPInitializeParams',
	#superclass : 'Object',
	#instVars : [
		'trace',
		'processId',
		'locale',
		'clientInfo',
		'rootPath',
		'workspaceFolders',
		'capabilities',
		'rootUri'
	],
	#category : 'PharoLanguageProtocol-Initialize',
	#package : 'PharoLanguageProtocol',
	#tag : 'Initialize'
}

{ #category : 'accessing' }
PLPInitializeParams >> asJRPCJSON [

	| dic |
	dic := Dictionary new.
	dic at: #capabilities put: self capabilities asJRPCJSON.

	dic at: #clientInfo put: self clientInfo asJRPCJSON.
	dic at: #locale put: self locale asJRPCJSON.

	dic at: #processId put: self processId asJRPCJSON.
	dic at: #rootPath put: self rootPath asJRPCJSON.
	dic at: #rootUri put: self rootUri asJRPCJSON.
	dic at: #trace put: self trace1 asJRPCJSON.

	dic at: #workspaceFolders put: self workspaceFolders asJRPCJSON.
	^ dic
]

{ #category : 'accessing' }
PLPInitializeParams >> capabilities [

	^ capabilities
]

{ #category : 'accessing' }
PLPInitializeParams >> capabilities: anObject [

	capabilities := anObject
]

{ #category : 'accessing' }
PLPInitializeParams >> clientInfo [

	^ clientInfo
]

{ #category : 'accessing' }
PLPInitializeParams >> clientInfo: anObject [

	clientInfo := anObject
]

{ #category : 'accessing' }
PLPInitializeParams >> locale [

	^ locale
]

{ #category : 'accessing' }
PLPInitializeParams >> locale: anObject [

	locale := anObject
]

{ #category : 'accessing' }
PLPInitializeParams >> processId [

	^ processId
]

{ #category : 'accessing' }
PLPInitializeParams >> processId: anObject [

	processId := anObject
]

{ #category : 'accessing' }
PLPInitializeParams >> rootPath [

	^ rootPath
]

{ #category : 'accessing' }
PLPInitializeParams >> rootPath: anObject [

	rootPath := anObject
]

{ #category : 'accessing' }
PLPInitializeParams >> rootUri [

	^ rootUri
]

{ #category : 'accessing' }
PLPInitializeParams >> rootUri: anObject [

	rootUri := anObject
]

{ #category : 'accessing' }
PLPInitializeParams >> trace1 [

	^ trace
]

{ #category : 'accessing' }
PLPInitializeParams >> trace1: anObject [

	trace := anObject
]

{ #category : 'accessing' }
PLPInitializeParams >> workspaceFolders [

	^ workspaceFolders
]

{ #category : 'accessing' }
PLPInitializeParams >> workspaceFolders: anObject [

	workspaceFolders := anObject
]
