"
Represents a collection of {@link InlineCompletionItem inline completion items} to be presented in the editor.
"
Class {
	#name : #PLSInlineCompletionList,
	#superclass : #Object,
	#instVars : [
		'items'
	],
	#category : 'PharoLanguageServer-Structure-InlineCompletion'
}

{ #category : #accessing }
PLSInlineCompletionList >> asJRPCJSON [

	^ { (#items -> self items asJRPCJSON) } asDictionary
]

{ #category : #accessing }
PLSInlineCompletionList >> items [

	^ items
]

{ #category : #accessing }
PLSInlineCompletionList >> items: anObject [

	items := anObject
]
