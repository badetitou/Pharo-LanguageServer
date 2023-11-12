Class {
	#name : #SpPLCCodePresenter,
	#superclass : #SpCodePresenter,
	#category : #'PharoLanguageClientLocal-GraphicalStack'
}

{ #category : #initialization }
SpPLCCodePresenter >> resetInlineCompletion [

	self withAdapterDo: [ :anAdapter | anAdapter resetInlineCompletion ]
]

{ #category : #initialization }
SpPLCCodePresenter >> setInlineCompletionWith: anInlineCompletionText [

	self withAdapterDo: [ :anAdapter |
		anAdapter resetInlineCompletion.
		anAdapter setInlineCompletionWith: anInlineCompletionText ]
]
