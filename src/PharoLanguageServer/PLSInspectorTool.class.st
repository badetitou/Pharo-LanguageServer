"
I am a tool of the image shown by the client of the language server (see PLSClientTool): the inspector opens the Inspector view of the client, the browser the editor of the class or method.
"
Class {
	#name : 'PLSInspectorTool',
	#superclass : 'PLSClientTool',
	#category : 'PharoLanguageServer-UI',
	#package : 'PharoLanguageServer',
	#tag : 'UI'
}

{ #category : 'opening' }
PLSInspectorTool >> inspect: anObject [

	^ self inspect: anObject label: nil
]

{ #category : 'opening' }
PLSInspectorTool >> inspect: anObject label: aStringOrNil [
	"Open the Inspector view of the client on anObject"

	plsServer uiInspect: anObject label: aStringOrNil.
	^ anObject
]

{ #category : 'opening' }
PLSInspectorTool >> openOn: anObject [

	^ self inspect: anObject
]
