Class {
	#name : #PLSServerCapabilities,
	#superclass : #Object,
	#category : #'PharoLanguageServer-Structure-Capabilities'
}

{ #category : #converting }
PLSServerCapabilities >> asJRPCJSON [
	^ {(#completionProvider -> self completionProvider asJRPCJSON).
		(#textDocumentSync -> self textDocumentSync asJRPCJSON).
		(#hoverProvider -> self hoverProvider asJRPCJSON)}
		asDictionary
]

{ #category : #'as yet unclassified' }
PLSServerCapabilities >> completionProvider [
	^ PLSCompletionOptions new
]

{ #category : #converting }
PLSServerCapabilities >> hoverProvider [
	^ PLSHoverOptions new
]

{ #category : #converting }
PLSServerCapabilities >> textDocumentSync [
	^ PLSTextDocumentSyncOptions new
		openClose: true;
		change: PLSTextDocumentSyncKind full;
		yourself
]
