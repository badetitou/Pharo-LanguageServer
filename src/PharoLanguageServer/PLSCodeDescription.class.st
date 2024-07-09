Class {
	#name : 'PLSCodeDescription',
	#superclass : 'Object',
	#instVars : [
		'href'
	],
	#category : 'PharoLanguageServer-Structure-Diagnostic',
	#package : 'PharoLanguageServer',
	#tag : 'Structure-Diagnostic'
}

{ #category : 'accessing' }
PLSCodeDescription >> asJRPCJSON [

	^ { (#href -> self href asJRPCJSON) } asDictionary
]

{ #category : 'accessing' }
PLSCodeDescription >> href [

	^ href
]

{ #category : 'accessing' }
PLSCodeDescription >> href: anObject [

	href := anObject
]
