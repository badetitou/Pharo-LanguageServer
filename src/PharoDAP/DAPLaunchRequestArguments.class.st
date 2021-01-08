Class {
	#name : #DAPLaunchRequestArguments,
	#superclass : #DAPJsonableObject,
	#instVars : [
		'noDebug',
		'__restart'
	],
	#category : #'PharoDAP-Structure'
}

{ #category : #accessing }
DAPLaunchRequestArguments >> __restart [
	^ __restart
]

{ #category : #accessing }
DAPLaunchRequestArguments >> __restart: anObject [
	__restart := anObject
]

{ #category : #accessing }
DAPLaunchRequestArguments >> noDebug [
	^ noDebug
]

{ #category : #accessing }
DAPLaunchRequestArguments >> noDebug: anObject [
	noDebug := anObject
]
