Class {
	#name : #PLSUIManager,
	#superclass : #MorphicUIManager,
	#instVars : [
		'plsServer'
	],
	#category : #PharoLanguageServer
}

{ #category : #'instance creation' }
PLSUIManager class >> withPLSServer: aPLSServer [
	^ self new
		plsServer: aPLSServer;
		beDefault;
		yourself
]

{ #category : #'default actions' }
PLSUIManager >> inform: aStringOrText [
	plsServer
		ifNotNil: [ plsServer
				showMessage: aStringOrText printString
				ofType: PLSMessageType info ]
]

{ #category : #accessing }
PLSUIManager >> plsServer [
	^ plsServer
]

{ #category : #accessing }
PLSUIManager >> plsServer: anObject [
	plsServer := anObject
]

{ #category : #'default actions' }
PLSUIManager >> unhandledErrorDefaultAction: anException [

	anException debug
]
