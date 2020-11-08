Class {
	#name : #PLSCompletionItem,
	#superclass : #Object,
	#instVars : [
		'label',
		'kind',
		'tags',
		'detail',
		'documentation',
		'deprecated',
		'preselect',
		'sortText',
		'filterText',
		'insertText',
		'insertTextFormat',
		'textEdit',
		'additionalTextEdits',
		'commitCharacters',
		'command',
		'data'
	],
	#category : #'PharoLanguageServer-Structure-Completion'
}

{ #category : #accessing }
PLSCompletionItem >> additionalTextEdits [
	^ additionalTextEdits
]

{ #category : #accessing }
PLSCompletionItem >> additionalTextEdits: anObject [
	additionalTextEdits := anObject
]

{ #category : #accessing }
PLSCompletionItem >> command [
	^ command
]

{ #category : #accessing }
PLSCompletionItem >> command: anObject [
	command := anObject
]

{ #category : #accessing }
PLSCompletionItem >> commitCharacters [
	^ commitCharacters
]

{ #category : #accessing }
PLSCompletionItem >> commitCharacters: anObject [
	commitCharacters := anObject
]

{ #category : #accessing }
PLSCompletionItem >> data [
	^ data
]

{ #category : #accessing }
PLSCompletionItem >> data: anObject [
	data := anObject
]

{ #category : #accessing }
PLSCompletionItem >> deprecated [
	^ deprecated
]

{ #category : #accessing }
PLSCompletionItem >> deprecated1: anObject [
	deprecated := anObject
]

{ #category : #accessing }
PLSCompletionItem >> detail [
	^ detail
]

{ #category : #accessing }
PLSCompletionItem >> detail: anObject [
	detail := anObject
]

{ #category : #accessing }
PLSCompletionItem >> documentation [
	^ documentation
]

{ #category : #accessing }
PLSCompletionItem >> documentation: anObject [
	documentation := anObject
]

{ #category : #accessing }
PLSCompletionItem >> filterText [
	^ filterText
]

{ #category : #accessing }
PLSCompletionItem >> filterText: anObject [
	filterText := anObject
]

{ #category : #accessing }
PLSCompletionItem >> insertText [
	^ insertText
]

{ #category : #accessing }
PLSCompletionItem >> insertText: anObject [
	insertText := anObject
]

{ #category : #accessing }
PLSCompletionItem >> insertTextFormat [
	^ insertTextFormat
]

{ #category : #accessing }
PLSCompletionItem >> insertTextFormat: anObject [
	insertTextFormat := anObject
]

{ #category : #accessing }
PLSCompletionItem >> kind [
	^ kind
]

{ #category : #accessing }
PLSCompletionItem >> kind: anObject [
	kind := anObject
]

{ #category : #accessing }
PLSCompletionItem >> label [
	^ label
]

{ #category : #accessing }
PLSCompletionItem >> label: anObject [
	label := anObject
]

{ #category : #accessing }
PLSCompletionItem >> preselect [
	^ preselect
]

{ #category : #accessing }
PLSCompletionItem >> preselect: anObject [
	preselect := anObject
]

{ #category : #accessing }
PLSCompletionItem >> sortText [
	^ sortText
]

{ #category : #accessing }
PLSCompletionItem >> sortText: anObject [
	sortText := anObject
]

{ #category : #accessing }
PLSCompletionItem >> tags [
	^ tags
]

{ #category : #accessing }
PLSCompletionItem >> tags: anObject [
	tags := anObject
]

{ #category : #accessing }
PLSCompletionItem >> textEdit [
	^ textEdit
]

{ #category : #accessing }
PLSCompletionItem >> textEdit: anObject [
	textEdit := anObject
]
