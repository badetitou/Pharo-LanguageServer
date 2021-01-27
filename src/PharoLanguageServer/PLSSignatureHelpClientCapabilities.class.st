Class {
	#name : #PLSSignatureHelpClientCapabilities,
	#superclass : #Object,
	#instVars : [
		'triggerCharacters',
		'retriggerCharacters'
	],
	#category : #'PharoLanguageServer-Structure-Capabilities'
}

{ #category : #accessing }
PLSSignatureHelpClientCapabilities >> asJRPCJSON [
	^ {(#triggerCharacters -> self triggerCharacters asJRPCJSON).
	(#retriggerCharacters -> self retriggerCharacters asJRPCJSON).
	(#workDoneProgress -> false)} asDictionary
]

{ #category : #accessing }
PLSSignatureHelpClientCapabilities >> retriggerCharacters [
	^ retriggerCharacters
]

{ #category : #accessing }
PLSSignatureHelpClientCapabilities >> retriggerCharacters: anObject [
	retriggerCharacters := anObject
]

{ #category : #accessing }
PLSSignatureHelpClientCapabilities >> triggerCharacters [
	^ triggerCharacters
]

{ #category : #accessing }
PLSSignatureHelpClientCapabilities >> triggerCharacters: anObject [
	triggerCharacters := anObject
]
