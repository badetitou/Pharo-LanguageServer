"
Defines how the host (editor) should sync document changes to the language server.
"
Class {
	#name : #PLSTextDocumentSyncOptions,
	#superclass : #Object,
	#instVars : [
		'openClose',
		'change'
	],
	#category : #'PharoLanguageServer-Structure-Capabilities'
}

{ #category : #accessing }
PLSTextDocumentSyncOptions >> change [
	"Change notifications are sent to the server. 
	 See TextDocumentSyncKind.None, TextDocumentSyncKind.Full,  and TextDocumentSyncKind.Incremental.
	 If omitted, it defaults to TextDocumentSyncKind.None."
	^ change
]

{ #category : #accessing }
PLSTextDocumentSyncOptions >> change: anObject [
	change := anObject
]

{ #category : #accessing }
PLSTextDocumentSyncOptions >> openClose [
	"Open and close notifications are sent to the server. 
	If omitted open close notification should not be sent."

	^ openClose
]

{ #category : #accessing }
PLSTextDocumentSyncOptions >> openClose: anObject [
	openClose := anObject
]
