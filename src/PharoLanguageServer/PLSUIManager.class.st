Class {
	#name : #PLSUIManager,
	#superclass : #MorphicUIManager,
	#instVars : [
		'plsServer'
	],
	#category : 'PharoLanguageServer'
}

{ #category : #'instance creation' }
PLSUIManager class >> withPLSServer: aPLSServer [
	^ self new
		plsServer: aPLSServer;
		beDefault;
		yourself
]

{ #category : #accessing }
PLSUIManager >> debugProcess: process context: context label: title fullView: bool notification: notificationString [
	
	(OupsDebugRequest newForContext: context)
		process: process;
		label: title;
		submit
]

{ #category : #accessing }
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

{ #category : #accessing }
PLSUIManager >> handleError: anError log: shouldLog [

	self handleDebugRequest: (OupsDebugRequest newForException: anError)

]

{ #category : #accessing }
PLSUIManager >> handleWarningDebugRequest: aWarningDebugRequest [

	self handleDebugRequest:  aWarningDebugRequest	
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
