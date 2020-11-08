"
Completion item tags are extra annotations that tweak the rendering of a completion item.
"
Class {
	#name : #PLSCompletionItemTag,
	#superclass : #Object,
	#category : #'PharoLanguageServer-Structure-Completion'
}

{ #category : #'as yet unclassified' }
PLSCompletionItemTag class >> deprecated [
	"Render a completion as obsolete, usually using a strike-out."
	^ 1
]
