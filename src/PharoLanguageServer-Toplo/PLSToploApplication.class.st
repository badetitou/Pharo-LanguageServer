Class {
	#name : 'PLSToploApplication',
	#superclass : 'SpApplication',
	#classVars : [
		'Current'
	],
	#category : 'PharoLanguageServer-Toplo',
	#package : 'PharoLanguageServer-Toplo'
}

{ #category : 'accessing' }
PLSToploApplication class >> current [

	^ Current ifNil: [
		  Current := self new.
		  Current run.
		  Current ]
]

{ #category : 'accessing' }
PLSToploApplication class >> defaultBackendName [

	^ #Toplo
]
