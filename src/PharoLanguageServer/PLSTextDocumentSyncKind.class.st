"
Defines how the host (editor) should sync document changes to the language server.
"
Class {
	#name : #PLSTextDocumentSyncKind,
	#superclass : #Object,
	#category : 'PharoLanguageServer-Structure-Capabilities'
}

{ #category : #'as yet unclassified' }
PLSTextDocumentSyncKind class >> full [
	"Documents are synced by always sending the full content of the document."
	^ 1
]

{ #category : #'as yet unclassified' }
PLSTextDocumentSyncKind class >> incremental [
	"Documents are synced by sending the full content on open.
	
	After that only incremental updates to the document are send."
	^ 2
]

{ #category : #'as yet unclassified' }
PLSTextDocumentSyncKind class >> none [
	"Documents should not be synced at all."
	^ 0
]
