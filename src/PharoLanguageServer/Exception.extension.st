Extension { #name : #Exception }

{ #category : #'*PharoLanguageServer' }
Exception >> plsMimeType [
	^ 'error'
]

{ #category : #'*PharoLanguageServer' }
Exception >> plsPrintString [
	^ self messageText
]
