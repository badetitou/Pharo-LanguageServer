"
I stand for a tool of the image (Smalltalk tools) while a client of the language server shows it: what the code asks the tool, such as `anObject inspect` or `aClass browse`, opens the view of the client instead of a window nobody sees.

My subclasses answer the messages the client can show; any other message goes to the original tool.

	PLSServer>>uiInstallTools registers us; PLSServer>>uiRestoreTools puts the original tools back.
"
Class {
	#name : 'PLSClientTool',
	#superclass : 'Object',
	#instVars : [
		'plsServer',
		'originalTool'
	],
	#category : 'PharoLanguageServer-UI',
	#package : 'PharoLanguageServer',
	#tag : 'UI'
}

{ #category : 'instance creation' }
PLSClientTool class >> on: aPLSServer replacing: aTool [

	^ self new
		  plsServer: aPLSServer;
		  originalTool: aTool;
		  yourself
]

{ #category : 'reflective operations' }
PLSClientTool >> doesNotUnderstand: aMessage [
	"What the client does not show is done by the original tool"

	originalTool ifNil: [ ^ super doesNotUnderstand: aMessage ].
	^ aMessage sendTo: originalTool
]

{ #category : 'accessing' }
PLSClientTool >> originalTool [

	^ originalTool
]

{ #category : 'accessing' }
PLSClientTool >> originalTool: aTool [

	originalTool := aTool
]

{ #category : 'accessing' }
PLSClientTool >> plsServer: aPLSServer [

	plsServer := aPLSServer
]

{ #category : 'reflective operations' }
PLSClientTool >> respondsTo: aSymbol [

	^ (super respondsTo: aSymbol) or: [
		  originalTool notNil and: [ originalTool respondsTo: aSymbol ] ]
]
