Class {
	#name : #PLSClientContext,
	#superclass : #Object,
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
	#category : #'PharoLanguageServer-Context'
}

{ #category : #accessing }
PLSClientContext >> capabilities [

	^ capabilities
]

{ #category : #accessing }
PLSClientContext >> capabilities: anObject [

	capabilities := anObject
]

{ #category : #accessing }
PLSClientContext >> clientInfo [

	^ clientInfo
]

{ #category : #accessing }
PLSClientContext >> clientInfo: anObject [

	clientInfo := anObject
]

{ #category : #accessing }
PLSClientContext >> locale [

	^ locale
]

{ #category : #accessing }
PLSClientContext >> locale: anObject [

	locale := anObject
]

{ #category : #accessing }
PLSClientContext >> processId [

	^ processId
]

{ #category : #accessing }
PLSClientContext >> processId: anObject [

	processId := anObject
]

{ #category : #accessing }
PLSClientContext >> rootPath [

	^ rootPath
]

{ #category : #accessing }
PLSClientContext >> rootPath: anObject [

	rootPath := anObject
]

{ #category : #accessing }
PLSClientContext >> rootUri [

	^ rootUri
]

{ #category : #accessing }
PLSClientContext >> rootUri: anObject [

	rootUri := anObject
]

{ #category : #accessing }
PLSClientContext >> trace1 [

	^ trace
]

{ #category : #accessing }
PLSClientContext >> trace1: anObject [

	trace := anObject
]

{ #category : #accessing }
PLSClientContext >> workspaceFolders [

	^ workspaceFolders
]

{ #category : #accessing }
PLSClientContext >> workspaceFolders: anObject [

	workspaceFolders := anObject
]
