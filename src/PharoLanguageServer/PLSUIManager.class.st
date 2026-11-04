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

{ #category : 'ui requests' }
PLSUIManager >> abort: aStringOrText title: aString [

	self forwardsToClient ifFalse: [
		^ super abort: aStringOrText title: aString ].
	self show: aStringOrText title: aString type: PLSMessageType error
]

{ #category : 'ui requests' }
PLSUIManager >> alert: aStringOrText title: aString configure: aBlock [

	self forwardsToClient ifFalse: [
		^ super alert: aStringOrText title: aString configure: aBlock ].
	self show: aStringOrText title: aString type: PLSMessageType warning
]

{ #category : 'pls - client' }
PLSUIManager >> ask: aMethodString params: anAssociationArray [
	"Ask the client, and answer its answer or nil when the user dismissed the question"

	^ plsServer
		  uiRequest: aMethodString
		  params:
		  (anAssociationArray reject: [ :each | each value isNil ])
			  asDictionary
]

{ #category : 'pls - client' }
PLSUIManager >> choose: aList values: aValueListOrNil message: aStringOrNil title: aTitleOrNil allowOther: aBoolean [
	"Ask the client to choose in aList. Answer the value of the chosen item, its index when aValueListOrNil is nil, the text typed when aBoolean allows it, or nil"

	| answer index |
	answer := self ask: 'pls-ui/choose' params: {
			          (#items
			           ->
			           (aList asArray collect: [ :each | self textOf: each ])).
			          (#message -> (self textOf: aStringOrNil)).
			          (#title -> (self textOf: aTitleOrNil)).
			          (#allowOther -> aBoolean) }.
	answer isDictionary ifFalse: [ ^ nil ].
	(answer at: 'text' ifAbsent: [ nil ]) ifNotNil: [ :text |
			^ aBoolean
				  ifTrue: [ text ]
				  ifFalse: [ nil ] ].
	index := (answer at: 'index' ifAbsent: [ nil ]) ifNil: [ ^ nil ].
	(index isInteger and: [ index between: 0 and: aList size - 1 ])
		ifFalse: [ ^ nil ].
	^ aValueListOrNil
		  ifNil: [ index + 1 ]
		  ifNotNil: [ aValueListOrNil at: index + 1 ]
]

{ #category : 'ui requests' }
PLSUIManager >> chooseDirectory: label from: dir [

	self forwardsToClient ifFalse: [
		^ super chooseDirectory: label from: dir ].
	^ self
		  chooseFile: (label ifNil: [ 'Choose Directory' ])
		  path: dir
		  directory: true
		  save: false
		  extensions: nil
]

{ #category : 'ui requests' }
PLSUIManager >> chooseDirectory: title path: path [

	self forwardsToClient ifFalse: [
		^ super chooseDirectory: title path: path ].
	^ self
		  chooseFile: title
		  path: path
		  directory: true
		  save: false
		  extensions: nil
]

{ #category : 'ui requests' }
PLSUIManager >> chooseDropList: aStringOrText title: aString list: aList [

	self forwardsToClient ifFalse: [
		^ super chooseDropList: aStringOrText title: aString list: aList ].
	^ self
		  choose: aList
		  values: aList
		  message: aStringOrText
		  title: aString
		  allowOther: false
]

{ #category : 'ui requests' }
PLSUIManager >> chooseExistingFileReference: title extensions: exts path: path preview: preview [

	self forwardsToClient ifFalse: [
			^ super
				  chooseExistingFileReference: title
				  extensions: exts
				  path: path
				  preview: preview ].
	^ self
		  chooseFile: title
		  path: path
		  directory: false
		  save: false
		  extensions: exts
]

{ #category : 'pls - client' }
PLSUIManager >> chooseFile: aTitle path: aPath directory: isDirectory save: isSave extensions: extensions [
	"Ask the client for a file or a directory, and answer its FileReference or nil"

	^ (self ask: 'pls-ui/chooseFile' params: {
			   (#title -> (self textOf: aTitle)).
			   (#path -> (self pathOf: aPath)).
			   (#directory -> isDirectory).
			   (#save -> isSave).
			   (#extensions -> (extensions ifNotNil: [ :exts |
				     exts asArray collect: [ :each | each asString ] ])) })
		  ifNotNil: [ :path |
				  path isString
					  ifTrue: [ path asFileReference ]
					  ifFalse: [ nil ] ]
]

{ #category : 'ui requests' }
PLSUIManager >> chooseForSaveFileReference: title extensions: exts path: path preview: preview [

	self forwardsToClient ifFalse: [
			^ super
				  chooseForSaveFileReference: title
				  extensions: exts
				  path: path
				  preview: preview ].
	^ self
		  chooseFile: title
		  path: path
		  directory: false
		  save: true
		  extensions: exts
]

{ #category : 'ui requests' }
PLSUIManager >> chooseFrom: labelList values: valueList lines: linesArray message: messageString title: aString [

	self forwardsToClient ifFalse: [
			^ super
				  chooseFrom: labelList
				  values: valueList
				  lines: linesArray
				  message: messageString
				  title: aString ].
	^ self
		  choose: labelList
		  values: valueList
		  message: messageString
		  title: aString
		  allowOther: false
]

{ #category : 'ui requests' }
PLSUIManager >> chooseFrom: labelList values: valueList lines: linesArray title: aString [

	(ProvideAnswerNotification signal: aString) ifNotNil: [ :answer |
		^ answer ].
	self forwardsToClient ifFalse: [
			^ super
				  chooseFrom: labelList
				  values: valueList
				  lines: linesArray
				  title: aString ].
	^ self
		  choose: labelList
		  values: valueList
		  message: nil
		  title: aString
		  allowOther: false
]

{ #category : 'ui requests' }
PLSUIManager >> chooseFullFileNameMatching: patterns label: label [

	self forwardsToClient ifFalse: [
		^ super chooseFullFileNameMatching: patterns label: label ].
	^ (self
		   chooseFile: (label ifNil: [ 'Choose File' ])
		   path: nil
		   directory: false
		   save: false
		   extensions: (patterns ifNotNil: [ :each |
				    each collect: [ :pattern | pattern copyAfterLast: $. ] ]))
		  ifNotNil: [ :file | file fullName ]
]

{ #category : 'ui requests' }
PLSUIManager >> chooseOrRequestFrom: labelList values: valueList lines: linesArray title: aString [

	self forwardsToClient ifFalse: [
			^ super
				  chooseOrRequestFrom: labelList
				  values: valueList
				  lines: linesArray
				  title: aString ].
	^ self
		  choose: labelList
		  values: valueList
		  message: nil
		  title: aString
		  allowOther: true
]

{ #category : 'ui requests' }
PLSUIManager >> confirm: queryString label: aTitle [

	(ProvideAnswerNotification signal: queryString) ifNotNil: [ :answer |
		^ answer ].
	self forwardsToClient ifFalse: [
		^ super confirm: queryString label: aTitle ].
	^ (self ask: 'pls-ui/confirm' params: {
			   (#message -> (self textOf: queryString)).
			   (#title -> (self textOf: aTitle)) }) == true
]

{ #category : 'ui requests' }
PLSUIManager >> confirm: queryString label: aTitle trueChoice: trueChoice falseChoice: falseChoice cancelChoice: cancelChoice default: defaultOption [

	| answer |
	(ProvideAnswerNotification signal: queryString) ifNotNil: [ :provided |
		^ provided ].
	self forwardsToClient ifFalse: [
			^ super
				  confirm: queryString
				  label: aTitle
				  trueChoice: trueChoice
				  falseChoice: falseChoice
				  cancelChoice: cancelChoice
				  default: defaultOption ].
	answer := self ask: 'pls-ui/confirm' params: {
			          (#message -> (self textOf: queryString)).
			          (#title -> (self textOf: aTitle)).
			          (#trueChoice -> (self textOf: trueChoice)).
			          (#falseChoice -> (self textOf: falseChoice)).
			          (#cancelChoice -> (self textOf: cancelChoice)) }.
	(answer isKindOf: Boolean) ifTrue: [ ^ answer ].
	"Dismissed: cancel when there is a cancel choice, else no"
	^ cancelChoice ifNil: [ false ]
]

{ #category : 'ui requests' }
PLSUIManager >> confirm: aStringOrText orCancel: cancelBlock [

	| answer |
	(ProvideAnswerNotification signal: aStringOrText) ifNotNil: [
			:provided |
			^ provided == #cancel
				  ifTrue: [ cancelBlock value ]
				  ifFalse: [ provided ] ].
	self forwardsToClient ifFalse: [
		^ super confirm: aStringOrText orCancel: cancelBlock ].
	answer := self ask: 'pls-ui/confirm' params: {
			          (#message -> (self textOf: aStringOrText)).
			          (#cancelChoice -> 'Cancel') }.
	^ (answer isKindOf: Boolean)
		  ifTrue: [ answer ]
		  ifFalse: [ cancelBlock value ]
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

{ #category : 'ui requests' }
PLSUIManager >> deny: aStringOrText title: aString [

	self forwardsToClient ifFalse: [
		^ super deny: aStringOrText title: aString ].
	self show: aStringOrText title: aString type: PLSMessageType error
]

{ #category : 'pls - client' }
PLSUIManager >> forwardsToClient [
	"Whether the questions go to the client of the language server, which announced it shows them"

	^ plsServer isNotNil and: [ plsServer uiForwards ]
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

{ #category : 'ui requests' }
PLSUIManager >> inform: aStringOrText [

	(plsServer isNil or: [ plsServer debugMode ]) ifTrue: [
		^ super inform: aStringOrText ].
	plsServer
		showMessage: (self textOf: aStringOrText)
		ofType: PLSMessageType info
]

{ #category : 'ui requests' }
PLSUIManager >> message: aStringOrText title: aString [

	self forwardsToClient ifFalse: [
		^ super message: aStringOrText title: aString ].
	self show: aStringOrText title: aString type: PLSMessageType info
]

{ #category : 'ui requests' }
PLSUIManager >> multiLineRequest: queryString initialAnswer: defaultAnswer answerHeight: answerHeight [

	(ProvideAnswerNotification signal: queryString) ifNotNil: [ :answer |
			^ answer == #default
				  ifTrue: [ defaultAnswer ]
				  ifFalse: [ answer ] ].
	self forwardsToClient ifFalse: [
			^ super
				  multiLineRequest: queryString
				  initialAnswer: defaultAnswer
				  answerHeight: answerHeight ].
	^ self
		  requestText: queryString
		  initialAnswer: defaultAnswer
		  title: nil
		  password: false
		  multiline: true
]

{ #category : 'pls - client' }
PLSUIManager >> pathOf: aFileReferenceOrStringOrNil [

	^ aFileReferenceOrStringOrNil ifNotNil: [ :path |
		  path asFileReference fullName ]
]

{ #category : 'accessing' }
PLSUIManager >> plsServer [
	^ plsServer
]

{ #category : 'accessing' }
PLSUIManager >> plsServer: anObject [
	plsServer := anObject
]

{ #category : 'ui requests' }
PLSUIManager >> request: queryString initialAnswer: defaultAnswer title: aTitle [

	(ProvideAnswerNotification signal: queryString) ifNotNil: [ :answer |
			^ answer == #default
				  ifTrue: [ defaultAnswer ]
				  ifFalse: [ answer ] ].
	self forwardsToClient ifFalse: [
			^ super
				  request: queryString
				  initialAnswer: defaultAnswer
				  title: aTitle ].
	^ self
		  requestText: queryString
		  initialAnswer: defaultAnswer
		  title: aTitle
		  password: false
		  multiline: false
]

{ #category : 'ui requests' }
PLSUIManager >> request: queryString initialAnswer: defaultAnswer title: aTitle entryCompletion: anEntryCompletion [

	self forwardsToClient ifFalse: [
			^ super
				  request: queryString
				  initialAnswer: defaultAnswer
				  title: aTitle
				  entryCompletion: anEntryCompletion ].
	^ self
		  request: queryString
		  initialAnswer: defaultAnswer
		  title: aTitle
]

{ #category : 'ui requests' }
PLSUIManager >> requestPassword: aStringOrText [

	(ProvideAnswerNotification signal: aStringOrText) ifNotNil: [ :answer |
			^ answer == #default
				  ifTrue: [ '' ]
				  ifFalse: [ answer ] ].
	self forwardsToClient ifFalse: [
		^ super requestPassword: aStringOrText ].
	^ self
		  requestText: aStringOrText
		  initialAnswer: nil
		  title: 'Password Required'
		  password: true
		  multiline: false
]

{ #category : 'pls - client' }
PLSUIManager >> requestText: queryString initialAnswer: defaultAnswer title: aTitle password: isPassword multiline: isMultiline [
	"Ask the client for a text. Answer it, or nil when the user cancelled"

	| answer |
	answer := self ask: 'pls-ui/request' params: {
			          (#message -> (self textOf: queryString)).
			          (#title -> (self textOf: aTitle)).
			          (#initialAnswer -> (self textOf: defaultAnswer)).
			          (#password -> isPassword).
			          (#multiline -> isMultiline) }.
	^ answer isString
		  ifTrue: [ answer ]
		  ifFalse: [ nil ]
]

{ #category : 'pls - client' }
PLSUIManager >> show: aStringOrText title: aTitleOrNil type: aMessageType [

	plsServer
		showMessage: (aTitleOrNil
				 ifNil: [ self textOf: aStringOrText ]
				 ifNotNil: [
				 (self textOf: aTitleOrNil) , ': ' , (self textOf: aStringOrText) ])
		ofType: aMessageType
]

{ #category : 'pls - client' }
PLSUIManager >> textOf: aStringOrText [

	^ aStringOrText ifNotNil: [ :text | text asString ]
]

{ #category : 'ui requests' }
PLSUIManager >> unhandledErrorDefaultAction: anException [
	"Stop the process for a debugger of the client, as the debugger of Pharo would, when the exception filters of the client say so"

	(plsServer isNil or: [ plsServer debugMode ]) ifTrue: [
		^ super unhandledErrorDefaultAction: anException ].
	plsServer debugHasClient ifFalse: [ ^ anException debug ].
	(plsServer debugShouldStopOn: anException) ifFalse: [
		^ plsServer debugSkip: anException ].
	^ plsServer debugSuspend: anException
]
