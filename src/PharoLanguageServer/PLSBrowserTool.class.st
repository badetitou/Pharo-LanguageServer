"
I am a tool of the image shown by the client of the language server (see PLSClientTool): the inspector opens the Inspector view of the client, the browser the editor of the class or method.
"
Class {
	#name : 'PLSBrowserTool',
	#superclass : 'PLSClientTool',
	#category : 'PharoLanguageServer-UI',
	#package : 'PharoLanguageServer',
	#tag : 'UI'
}

{ #category : 'opening' }
PLSBrowserTool >> openOn: anObject [
	"Open a class or a method; anything else is opened by the original browser"

	anObject isCompiledMethod ifTrue: [ ^ self openOnMethod: anObject ].
	anObject isClass ifTrue: [ ^ self openOnClass: anObject ].
	(anObject isKindOf: Metaclass) ifTrue: [ ^ self openOnClass: anObject ].
	^ originalTool openOn: anObject
]

{ #category : 'opening' }
PLSBrowserTool >> openOnClass: aClass [

	^ self openOnClass: aClass selector: nil
]

{ #category : 'opening' }
PLSBrowserTool >> openOnClass: aClass selector: aSelectorOrNil [
	"Open the editor of aClass, or of its method aSelectorOrNil, in the client"

	plsServer uiBrowseClass: aClass selector: aSelectorOrNil
]

{ #category : 'opening' }
PLSBrowserTool >> openOnClass: aClass selector: aSelectorOrNil highlight: aString [

	^ self openOnClass: aClass selector: aSelectorOrNil
]

{ #category : 'opening' }
PLSBrowserTool >> openOnMethod: aMethod [

	^ self openOnClass: aMethod methodClass selector: aMethod selector
]
