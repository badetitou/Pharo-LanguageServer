Class {
	#name : 'PLSUIManager',
	#superclass : 'MorphicUIManager',
	#instVars : [
		'plsServer'
	],
	#category : 'PharoLanguageServer',
	#package : 'PharoLanguageServer'
}

{ #category : 'instance creation' }
PLSUIManager class >> withPLSServer: aPLSServer [
	^ self new
		plsServer: aPLSServer;
		beDefault;
		yourself
]

{ #category : 'accessing' }
PLSUIManager >> debugProcess: process context: context label: title fullView: bool notification: notificationString [

	(plsServer isNil or: [ plsServer debugMode ]) ifTrue: [
		super
			debugProcess: process
			context: context
			label: title
			fullView: bool
			notification: notificationString ].
	(OupsDebugRequest newForContext: context)
		process: process;
		label: title;
		submit
]

{ #category : 'accessing' }
PLSUIManager >> handleDebugRequest: aDebugRequest [
	| debuggerOpeningStrategy oupsSystem |
  
	oupsSystem := OupsDebuggerSystem new.
	aDebugRequest debugSession logStackToFileIfNeeded.
	oupsSystem performPreDebugActionsIn: aDebugRequest.
	oupsSystem ensureExceptionIn: aDebugRequest debugSession.
	debuggerOpeningStrategy := oupsSystem debuggerSelectionStrategy.
	debuggerOpeningStrategy openDebuggerForSession:aDebugRequest debugSession.
	oupsSystem suspendDebuggedProcess: aDebugRequest
]

{ #category : 'accessing' }
PLSUIManager >> handleError: anError log: shouldLog [

	(plsServer isNil or: [ plsServer debugMode ]) ifTrue: [
		^ super handleError: anError log: shouldLog ].
	self handleDebugRequest: (OupsDebugRequest newForException: anError)
]

{ #category : 'accessing' }
PLSUIManager >> handleWarningDebugRequest: aWarningDebugRequest [

	self handleDebugRequest:  aWarningDebugRequest	
]

{ #category : 'default actions' }
PLSUIManager >> inform: aStringOrText [

	(plsServer isNil or: [ plsServer debugMode ]) ifTrue: [
		^ super inform: aStringOrText ].
	plsServer
		showMessage: aStringOrText printString
		ofType: PLSMessageType info
]

{ #category : 'accessing' }
PLSUIManager >> plsServer [
	^ plsServer
]

{ #category : 'accessing' }
PLSUIManager >> plsServer: anObject [
	plsServer := anObject
]

{ #category : 'default actions' }
PLSUIManager >> unhandledErrorDefaultAction: anException [

	(plsServer isNil or: [ plsServer debugMode ]) ifTrue: [
		^ super unhandledErrorDefaultAction: anException ].
	anException debug
]
