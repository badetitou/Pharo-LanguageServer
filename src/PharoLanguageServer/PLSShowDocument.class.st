Class {
	#name : 'PLSShowDocument',
	#superclass : 'Object',
	#instVars : [
		'uri',
		'external',
		'takeFocus',
		'selection'
	],
	#category : 'PharoLanguageServer-Structure-ShowDocument',
	#package : 'PharoLanguageServer',
	#tag : 'Structure-ShowDocument'
}

{ #category : 'accessing' }
PLSShowDocument >> asJRPCJSON [

	| dic |
	dic := Dictionary new.
	dic at: #uri put: uri.
	external ifNotNil: [ dic at: #external put: external ].
	takeFocus ifNotNil: [ dic at: #takeFocus put: takeFocus ].
	selection ifNotNil: [ dic at: #selection put: selection ].
	^ dic
]

{ #category : 'accessing' }
PLSShowDocument >> external [

	^ external
]

{ #category : 'accessing' }
PLSShowDocument >> external: anObject [

	external := anObject
]

{ #category : 'accessing' }
PLSShowDocument >> selection [

	^ selection
]

{ #category : 'accessing' }
PLSShowDocument >> selection: anObject [

	selection := anObject
]

{ #category : 'accessing' }
PLSShowDocument >> takeFocus [

	^ takeFocus
]

{ #category : 'accessing' }
PLSShowDocument >> takeFocus: anObject [

	takeFocus := anObject
]

{ #category : 'accessing' }
PLSShowDocument >> uri [

	^ uri
]

{ #category : 'accessing' }
PLSShowDocument >> uri: anObject [

	uri := anObject
]
