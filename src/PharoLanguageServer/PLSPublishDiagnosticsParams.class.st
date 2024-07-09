"
The structure used that embeded the diagnostics.
"
Class {
	#name : 'PLSPublishDiagnosticsParams',
	#superclass : 'Object',
	#instVars : [
		'uri',
		'version',
		'diagnostics'
	],
	#category : 'PharoLanguageServer-Structure-Diagnostic',
	#package : 'PharoLanguageServer',
	#tag : 'Structure-Diagnostic'
}

{ #category : 'accessing' }
PLSPublishDiagnosticsParams >> asJRPCJSON [
	^ {(#uri -> self uri asJRPCJSON).
	(#version -> self version asJRPCJSON).
	(#diagnostics -> self diagnostics asArray asJRPCJSON)} asDictionary
]

{ #category : 'accessing' }
PLSPublishDiagnosticsParams >> diagnostics [
	"An array of diagnostic information items."
	^ diagnostics
]

{ #category : 'accessing' }
PLSPublishDiagnosticsParams >> diagnostics: anObject [
	diagnostics := anObject
]

{ #category : 'accessing' }
PLSPublishDiagnosticsParams >> uri [
	"The URI for which diagnostic information is reported."
	^ uri
]

{ #category : 'accessing' }
PLSPublishDiagnosticsParams >> uri: anObject [
	uri := anObject
]

{ #category : 'accessing' }
PLSPublishDiagnosticsParams >> version [
	"Optional the version number of the document the diagnostics are published for."
	^ version
]

{ #category : 'accessing' }
PLSPublishDiagnosticsParams >> version: anObject [
	version := anObject
]
