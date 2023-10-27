"
Defines how the host (editor) should sync document changes to the language server.
"
Class {
	#name : 'PLSTextDocumentSyncOptions',
	#superclass : 'Object',
	#instVars : [
		'openClose',
		'change',
		'willSave',
		'willSaveWaitUntil',
		'save'
	],
	#category : 'PharoLanguageServer-Structure-Capabilities',
	#package : 'PharoLanguageServer',
	#tag : 'Structure-Capabilities'
}

{ #category : 'accessing' }
PLSTextDocumentSyncOptions >> asJRPCJSON [
	^ {(#change -> self change asJRPCJSON).
	(#openClose -> self openClose asJRPCJSON).
	(#willSave -> self willSave asJRPCJSON).
	(#willSaveWaitUntil -> self willSaveWaitUntil asJRPCJSON).
	(#save -> self save asJRPCJSON)} asDictionary
]

{ #category : 'accessing' }
PLSTextDocumentSyncOptions >> change [
	"Change notifications are sent to the server. 
	 See TextDocumentSyncKind.None, TextDocumentSyncKind.Full,  and TextDocumentSyncKind.Incremental.
	 If omitted, it defaults to TextDocumentSyncKind.None."
	^ change
]

{ #category : 'accessing' }
PLSTextDocumentSyncOptions >> change: anObject [
	change := anObject
]

{ #category : 'accessing' }
PLSTextDocumentSyncOptions >> openClose [
	"Open and close notifications are sent to the server. 
	If omitted open close notification should not be sent."

	^ openClose
]

{ #category : 'accessing' }
PLSTextDocumentSyncOptions >> openClose: anObject [
	openClose := anObject
]

{ #category : 'accessing' }
PLSTextDocumentSyncOptions >> save [
	^ save
]

{ #category : 'accessing' }
PLSTextDocumentSyncOptions >> save: anObject [
	save := anObject
]

{ #category : 'accessing' }
PLSTextDocumentSyncOptions >> willSave [
	^ willSave
]

{ #category : 'accessing' }
PLSTextDocumentSyncOptions >> willSave: anObject [
	willSave := anObject
]

{ #category : 'accessing' }
PLSTextDocumentSyncOptions >> willSaveWaitUntil [
	^ willSaveWaitUntil
]

{ #category : 'accessing' }
PLSTextDocumentSyncOptions >> willSaveWaitUntil: anObject [
	willSaveWaitUntil := anObject
]
