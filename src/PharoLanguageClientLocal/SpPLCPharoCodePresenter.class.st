Class {
	#name : 'SpPLCPharoCodePresenter',
	#superclass : 'SpCodePresenter',
	#category : 'PharoLanguageClientLocal-GraphicalStack',
	#package : 'PharoLanguageClientLocal',
	#tag : 'GraphicalStack'
}

{ #category : 'specs' }
SpPLCPharoCodePresenter class >> adapterName [

	^ #SpMorphicPLCCodeAdapter
]

{ #category : 'initialization' }
SpPLCPharoCodePresenter >> resetInlineCompletion [

	self withAdapterDo: [ :anAdapter | anAdapter resetInlineCompletion ]
]

{ #category : 'initialization' }
SpPLCPharoCodePresenter >> setInlineCompletionWith: anInlineCompletionText [

	self withAdapterDo: [ :anAdapter |
		anAdapter setInlineCompletionWith: anInlineCompletionText ]
]
