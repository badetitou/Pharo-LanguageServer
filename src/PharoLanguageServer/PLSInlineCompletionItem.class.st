"
An inline completion item represents a text snippet that is proposed inline to complete text that is being typed.
"
Class {
	#name : #PLSInlineCompletionItem,
	#superclass : #Object,
	#instVars : [
		'insertText',
		'filterText',
		'range',
		'command'
	],
	#category : 'PharoLanguageServer-Structure-InlineCompletion'
}

{ #category : #accessing }
PLSInlineCompletionItem >> asJRPCJSON [

	| dic |
	dic := { (#insertText -> self insertText asJRPCJSON) } asDictionary.
	self filterText ifNotNil: [
		dic at: #filterText put: self filterText asJRPCJSON ].
	self range ifNotNil: [ dic at: #range put: self range asJRPCJSON ].
	self command ifNotNil: [
		dic at: #command put: self command asJRPCJSON ].

	^ dic
]

{ #category : #accessing }
PLSInlineCompletionItem >> command [

	^ command
]

{ #category : #accessing }
PLSInlineCompletionItem >> command: anObject [

	command := anObject
]

{ #category : #accessing }
PLSInlineCompletionItem >> filterText [
	" A text that is used to decide if this inline completion should be shown. When `falsy` the {@link InlineCompletionItem.insertText} is used.

An inline completion is shown if the text to replace is a prefix of the filter text."

	^ filterText
]

{ #category : #accessing }
PLSInlineCompletionItem >> filterText: anObject [

	filterText := anObject
]

{ #category : #accessing }
PLSInlineCompletionItem >> insertText [
	"The text to replace the range with. Must be set.
	 Is used both for the preview and the accept operation."

	^ insertText
]

{ #category : #accessing }
PLSInlineCompletionItem >> insertText: anObject [

	insertText := anObject
]

{ #category : #accessing }
PLSInlineCompletionItem >> range [

	^ range
]

{ #category : #accessing }
PLSInlineCompletionItem >> range: anObject [

	range := anObject
]
