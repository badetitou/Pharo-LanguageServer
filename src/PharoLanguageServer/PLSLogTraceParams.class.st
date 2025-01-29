Class {
	#name : 'PLSLogTraceParams',
	#superclass : 'Object',
	#instVars : [
		'message',
		'verbose'
	],
	#category : 'PharoLanguageServer-Structure-Trace',
	#package : 'PharoLanguageServer',
	#tag : 'Structure-Trace'
}

{ #category : 'as yet unclassified' }
PLSLogTraceParams class >> message: aString verbose: anExtendedString [

	^ self new
		  message: aString;
		  verbose: anExtendedString;
		  yourself
]

{ #category : 'accessing' }
PLSLogTraceParams >> asJRPCJSON [

	| dic |
	dic := Dictionary new.
	dic at: #message put: self message.
	self verbose ifNotNil: [ dic at: #verbose put: self verbose ].
	^ dic
]

{ #category : 'accessing' }
PLSLogTraceParams >> message [

	^ message
]

{ #category : 'accessing' }
PLSLogTraceParams >> message: anObject [

	message := anObject
]

{ #category : 'accessing' }
PLSLogTraceParams >> verbose [

	^ verbose
]

{ #category : 'accessing' }
PLSLogTraceParams >> verbose: anObject [

	verbose := anObject
]
