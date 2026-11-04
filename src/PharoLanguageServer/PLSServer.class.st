"
I am the server. 
I also include all the pharo language features.

Methods in `lsp` protocol are standard language server protocol feature.

Methods in `pls` protocol are pharo language server feature.
"
Class {
	#name : 'PLSServer',
	#superclass : 'PLSAbstractServer',
	#instVars : [
		'envProjectPackages',
		'envChanges',
		'envChangesMutex',
		'envChangesReady',
		'envFlushProcess',
		'envFirstChangeTime',
		'envLastChangeTime',
		'envOverflow',
		'mcpEndpoint',
		'transcriptSubscription',
		'inspectorObjects',
		'inspectorNextId',
		'inspectorMutex',
		'critiquesEnabled',
		'debugSessions',
		'debugNextId',
		'debugMutex',
		'debugPoints',
		'debugExceptionFilters',
		'uiEnabled',
		'uiPreviousTools',
		'uiProgressTokens',
		'uiProgressMutex'
	],
	#classInstVars : [
		'version'
	],
	#category : 'PharoLanguageServer',
	#package : 'PharoLanguageServer'
}

{ #category : 'accessing' }
PLSServer class >> critiquesBanCommand [
	"The command banning a rule, which the client runs from a code action"

	^ 'pharo.critiques.ban'
]

{ #category : 'accessing' }
PLSServer class >> releaseVersion [
	"The release this source belongs to. The Release workflow writes the tag of the release here before building its images; between releases it stays 'development'"

	^ 'development'
]

{ #category : 'accessing' }
PLSServer class >> version [
	"The version of the language server: the one given by #version:, the release loaded by the start script of the client, else the release of this source"

	^ version ifNil: [ self releaseVersion ]
]

{ #category : 'accessing' }
PLSServer class >> version: aString [
	"Remember the release loaded in the image, for an image that loads it with Metacello rather than a release image"

	version := aString
]

{ #category : 'lsp - navigation' }
PLSServer >> callHierarchyIncomingCalls: item [
	"Answer the senders of the selector of the method of item, with the ranges of the sends"

	<jrpc: #'callHierarchy/incomingCalls'>
	| method matcher |
	method := self navMethodOfItem: item.
	method ifNil: [ ^ #(  ) ].
	matcher := self navMatcherOf:
		           (self navSelectorTarget: method selector).
	^ ((self navSorted:
		    (SystemNavigation default allSendersOf: method selector))
		   collect: [ :sender |
				   {
					   (#from -> (self navCallItemOf: sender)).
					   (#fromRanges
					    -> (self navRangesIn: sender where: matcher) asArray) }
					   asDictionary ]) asArray
]

{ #category : 'lsp - navigation' }
PLSServer >> callHierarchyOutgoingCalls: item [
	"Answer one call for each selector the method of item sends, to its most likely implementor, with the ranges of its sends"

	<jrpc: #'callHierarchy/outgoingCalls'>
	| method source sends |
	method := self navMethodOfItem: item.
	method ifNil: [ ^ #(  ) ].
	source := method sourceCode.
	sends := OrderedDictionary new.
	((RBParser parseFaultyMethod: source) allChildren select: [ :node |
		 node isMessage ]) do: [ :node |
			(sends at: node selector ifAbsentPut: [ OrderedCollection new ])
				add: node ].
	^ (sends associations
		   collect: [ :each |
				   (self
					    navImplementorOf: each key
					    sentTo: each value first receiver
					    from: method methodClass) ifNotNil: [ :implementor |
						   {
							   (#to -> (self navCallItemOf: implementor)).
							   (#fromRanges
							    ->
								    (each value collect: [ :node |
									     self navRangeOf: node in: source ]) asArray) }
							   asDictionary ] ]
		   thenSelect: [ :call | call notNil ]) asArray
]

{ #category : 'lsp - navigation' }
PLSServer >> callHierarchyPrepareWithPosition: position textDocument: textDocument [
	"Answer the item of the method at position: the implementor of a selector sent there, or the method whose selector or body holds position"

	<jrpc: #'textDocument/prepareCallHierarchy'>
	| document target context method |
	document := self context textItem: (textDocument at: #uri).
	target := self navTargetIn: document at: position.
	context := self navContextOf: document at: position.
	(target notNil and: [
		 (target at: #kind) = #selector and: [ target includesKey: #node ] ])
		ifTrue: [
				| node |
				node := target at: #node.
				method := node isMethod
					          ifTrue: [
							          ((target at: #context) at: #behavior) ifNotNil: [
								          :behavior |
								          behavior
									          compiledMethodAt: node selector
									          ifAbsent: [ nil ] ] ]
					          ifFalse: [
							          self
								          navImplementorOf: node selector
								          sentTo: node receiver
								          from: ((target at: #context) at: #behavior) ] ]
		ifFalse: [
				(context notNil and: [
					 (context at: #isMethod) and: [ (context at: #behavior) notNil ] ])
					ifTrue: [
							method := (context at: #behavior)
								          compiledMethodAt:
								          (RBParser parseFaultyMethod: (context at: #source))
									          selector
								          ifAbsent: [ nil ] ] ].
	^ method
		  ifNil: [ #(  ) ]
		  ifNotNil: [ { (self navCallItemOf: method) } ]
]

{ #category : 'pls - chest' }
PLSServer >> chestClass [
	"Answer the class Chest, or nil when Chest (github://pharo-spec/Chest) is not loaded"

	^ Smalltalk globals at: #Chest ifAbsent: [ nil ]
]

{ #category : 'pls - chest' }
PLSServer >> chestCodeOf: aKey in: aChest [
	"Answer the code that answers the object of aChest named aKey, as Paste object from chest writes it"

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: '(Chest named: ';
				  print: aChest name asString;
				  nextPutAll: ') at: ';
				  print: aKey asString ]
]

{ #category : 'pls - chest' }
PLSServer >> chestInspect: chest key: key [
	"Answer the description of the object of the chest named chest (the default chest when nil) named key, under a new reference of the inspector"

	<jrpc: #'pls-chest:inspect'>
	| object |
	object := [ (self chestNamed: chest) at: key ]
		          on: KeyNotFound
		          do: [ :error |
				          PLSUnknownEntity signal:
					          'Nothing named ' , key printString , ' in the chest' ].
	^ self
		  inspectorDescriptionOf: object
		  ref: (self inspectorRegister: object)
]

{ #category : 'pls - chest' }
PLSServer >> chestList [
	"Answer whether Chest is loaded, and its chests, the default one first, with the objects each holds by name and the code that answers them"

	<jrpc: #'pls-chest:list'>
	| chestClass chests |
	chestClass := self chestClass ifNil: [
			              ^ {
				                (#available -> false).
				                (#chests -> #(  )) } asDictionary ].
	chestClass defaultInstance.
	chests := chestClass allChests asArray sort: [ :a :b |
			          a == chestClass defaultInstance or: [
				          b ~~ chestClass defaultInstance and: [ a name <= b name ] ] ].
	^ {
		  (#available -> true).
		  (#chests -> (chests collect: [ :chest |
				    {
					    (#name -> chest name asString).
					    (#items -> (chest contents associations asArray
						      sort: [ :a :b | a key <= b key ];
						      collect: [ :association |
								      {
									      (#key -> association key asString).
									      (#className
									       ->
										       (thisContext objectClass: association value) name
											       asString).
									      (#printString
									       -> (self inspectorStringOf: association value)).
									      (#code -> (self chestCodeOf: association key in: chest)) }
									      asDictionary ])) } asDictionary ])) } asDictionary
]

{ #category : 'pls - chest' }
PLSServer >> chestNamed: aString [
	"Answer the chest named aString, the default chest when aString is nil"

	| chestClass |
	chestClass := self chestClass ifNil: [
		              ^ PLSUnknownEntity signal:
			                'Chest is not loaded in the image' ].
	aString ifNil: [ ^ chestClass defaultInstance ].
	^ [ chestClass named: aString ]
		  on: KeyNotFound
		  do: [ :error |
		  PLSUnknownEntity signal: 'Unknown chest: ' , aString ]
]

{ #category : 'pls - chest' }
PLSServer >> chestRemove: chest key: key [
	"Remove the object named key from the chest named chest (the default chest when nil)"

	<jrpc: #'pls-chest:remove'>
	(self chestNamed: chest) removeObjectNamed: key.
	^ nil
]

{ #category : 'pls - chest' }
PLSServer >> chestStore: ref chest: chest key: key [
	"Store the object of the reference ref of the inspector in the chest named chest (the default chest when nil) under key, or under a new name when key is nil. Answer the name"

	<jrpc: #'pls-chest:store'>
	| target object |
	target := self chestNamed: chest.
	object := self inspectorObjectOf: ref.
	^ { (#key -> ([
		    (key isNil or: [ key isEmpty ])
			    ifTrue: [ target add: object ]
			    ifFalse: [ target at: key put: object ] ]
		    on: Error
		    do: [ :error |
		    JRPCInvalidParameters signal: error messageText asString ])
		   asString) } asDictionary
]

{ #category : 'pls - variables' }
PLSServer >> childrenVariables: variableReference in: textDocument [

	<jrpc: #'pls:childrenVariables'>
	| document references currentVariable |
	document := self context textItem: (textDocument at: #uri at: #path).
	references := Stack newFrom: (variableReference substrings: '/').
	currentVariable := document binder bindings at: references pop.
	[ references isEmpty ] whileFalse: [
		| goTo |
		goTo := references pop.
		currentVariable := currentVariable instVarNamed: goTo asSymbol ].
	^ (currentVariable class allInstVarNames collectWithIndex: [ :name :idx |
		   PLSVariable new
			   name: name;
			   value: (currentVariable instVarAt: idx) printString;
			   variableReference: variableReference , '/' , name;
			   isDirectory:
				   (currentVariable instVarAt: idx) class allInstVarNames
					   isNotEmpty;
			   yourself ]) asArray
]

{ #category : 'lsp - diagnostics' }
PLSServer >> clientPullsDiagnostics [

	^ self context clientContext capabilities textDocument
		  ifNil: [ false ]
		  ifNotNil: [ :textDocument | textDocument diagnostic notNil ]
]

{ #category : 'lsp - diagnostics' }
PLSServer >> clientRefreshesDiagnostics [

	^ [
		  ((self context clientContext capabilities workspace at:
			    #diagnostics) at: #refreshSupport) == true ]
		  on: Error
		  do: [ false ]
]

{ #category : 'lsp - code action' }
PLSServer >> codeActionForDocument: textDocument atRange: range withContext: context [
	"Answer the code actions of the critiques among the diagnostics of context: the transformation of the rule, while the critique still matches the text, and the bans of the rule"

	<jrpc: #'textDocument/codeAction'>
	| uri document actions |
	self critiquesEnabled ifFalse: [ ^ #(  ) ].
	uri := textDocument at: #uri.
	document := self context textItem: uri ifAbsent: [ ^ #(  ) ].
	actions := OrderedCollection new.
	(context at: #diagnostics ifAbsent: [ #(  ) ]) do: [ :diagnostic |
			(self critiqueOf: diagnostic in: document) ifNotNil: [ :critique |
					document critiquesAreCurrent ifTrue: [
							(critique fixActionFor: uri) ifNotNil: [ :action |
								actions add: action ] ].
					actions addAll: (critique banActionsFor: uri) ] ].
	^ (actions collect: [ :each | each asJRPCJSON ]) asArray
]

{ #category : 'lsp - code lens' }
PLSServer >> codeLenResolves: range command: command data: aData [
	<jrpc: #'codeLens/resolve'>
	self flag: 'Not use in this version. All is done by codeLensTextDocument:'
]

{ #category : 'commands' }
PLSServer >> commandNotebookPrintIt: line textDocument: textDocumentURI [

	<jrpc: #'command:notebookPrintIt'>
	| compiler answer2 |
	"Use path because #external also uses the fragment number of the cell"
	compiler := self compilerFor: (textDocumentURI at: #path).
	answer2 := [ compiler evaluate: line ]
		           on: Error
		           do: [ :error | 
			           'error' record.
			           error ].
	^ answer2 asPLSCellOutput asJRPCJSON
]

{ #category : 'commands' }
PLSServer >> commandPharoLanguageServerVersion [

	<jrpc: #'command:version'>
	^ self class version
]

{ #category : 'commands' }
PLSServer >> commandPharoPrintIt: line textDocument: textDocumentURI [
	"This textDocumentURI from VSCode is strange.
	 An exception the evaluation leaves unhandled opens the debugger of the client"

	<jrpc: #'command:printIt'>
	| compiler answer2 |
	compiler := self compilerFor: (textDocumentURI at: #path).
	answer2 := self
		           debugEvaluate: [ compiler evaluate: line ]
		           ifStopped: [ :exception |
			           ^ Error signal:
				             exception description , ' (opened in the debugger)' ].
	^ answer2 plsPrintString
]

{ #category : 'commands' }
PLSServer >> commandPharoSave [
	<jrpc: #'command:save'>
	SmalltalkImage current snapshot: true andQuit: false.
	^ 'Image saved'
]

{ #category : 'accessing' }
PLSServer >> compilerFor: fileURI [

	| compiler |
	compiler := SmalltalkImage current compiler
		            failBlock: [ nil ];
		            yourself.
	fileURI ifNotNil: [
		compiler requestor: (self context textItem: fileURI) binder ].
	^ compiler
]

{ #category : 'lsp - code action' }
PLSServer >> critiqueOf: aDiagnostic in: aDocument [
	"Answer the PLSCritique that aDiagnostic, as the client sends it back, shows, or nil if it shows no critique"

	| data |
	(aDiagnostic at: #source ifAbsent: [ nil ]) = 'Renraku' ifFalse: [
		^ nil ].
	data := aDiagnostic at: #data ifAbsent: [ ^ nil ].
	data isDictionary ifFalse: [ ^ nil ].
	^ aDocument
		  critiqueAt: (data at: #critique ifAbsent: [ ^ nil ])
		  stamp: (data at: #stamp ifAbsent: [ ^ nil ])
]

{ #category : 'lsp - workspace' }
PLSServer >> critiquesBan: arguments [
	"arguments are the uri of a document, the stamp and index of one of its critiques, and the level of the ban among the entities that can ban it"

	| critique |
	critique := (self context textItem: arguments first)
		            critiqueAt: arguments third
		            stamp: arguments second.
	critique ifNil: [
			PLSUnknownEntity signal:
				'The critique is no longer the one of the document. Save it, then try again' ].
	critique banAt: arguments fourth.
	self critiquesRefresh.
	^ nil
]

{ #category : 'lsp - diagnostics' }
PLSServer >> critiquesEnabled [
	"Answer whether the Renraku critiques of the documents are shown, as the setting pharo.critiques.enabled of the client says"

	^ critiquesEnabled ifNil: [ true ]
]

{ #category : 'lsp - diagnostics' }
PLSServer >> critiquesRefresh [
	"Compute again the critiques of the open documents, and have the client show them"

	self context textItems valuesDo: [ :document |
		document resetCritiques ].
	self clientPullsDiagnostics
		ifTrue: [
				self clientRefreshesDiagnostics ifTrue: [
					self sendRequest: 'workspace/diagnostic/refresh' params: nil ] ]
		ifFalse: [
				self context textItems valuesDo: [ :document |
					self sendDiagnosticsforDocument: document ] ]
]

{ #category : 'debug' }
PLSServer >> debugClassesIn: aString [
	"The classes named in aString, separated by commas or spaces"

	^ ((aString substrings: ', ') collect: [ :each |
		   self class environment at: each asSymbol ifAbsent: [ nil ] ])
		  reject: [ :each | each isNil ]
]

{ #category : 'debug' }
PLSServer >> debugDescriptionOf: aDebugPoint [
	"The breakpoint of the client that stands for aDebugPoint: the entity and editor of its method, the line where it stops, and its condition, hit condition and log message. Nil when it is not on a method of the image"

	^ [
		  | node method description |
		  node := aDebugPoint nodes anyOne.
		  method := node methodNode compiledMethod.
		  description := Dictionary new.
		  description
			  at: #entity put: (self envMethodIdOf: method);
			  at: #uri put: (self navUriOfMethod: method);
			  at: #line
			  put: (self debugLineOf: node start in: method sourceCode).
		  (aDebugPoint getBehavior: ConditionBehavior) ifNotNil: [ :behavior |
			  description at: #condition put: behavior condition ].
		  (aDebugPoint getBehavior: PLSHitConditionBehavior) ifNotNil: [
			  :behavior |
			  description at: #hitCondition put: behavior condition ].
		  (aDebugPoint getBehavior: PLSLogPointBehavior) ifNotNil: [
			  :behavior | description at: #logMessage put: behavior message ].
		  description ]
		  on: Error
		  do: [ :error | nil ]
]

{ #category : 'pls - debug' }
PLSServer >> debugEvaluate: aBlock ifStopped: stoppedBlock [
	"Evaluate aBlock in a process of its own, outside of the execution environment of the caller, and answer its value.
	 An exception it leaves unhandled, or a halt, suspends that process for a debugger of the client (see #debugSuspend:):
	 answer then the value of stoppedBlock with the exception, once the client knows the debug session, without waiting for the debugger"

	| done release value stopped |
	done := Semaphore new.
	release := [
		           release := [ ].
		           done signal ].
	[
		[
			DefaultExecutionEnvironment beActiveDuring: [
					value := [ aBlock value ]
						         on: UnhandledException
						         do: [ :exception |
								         self debugHasClient ifFalse: [ exception pass ].
								         stopped := exception.
								         exception resumeUnchecked:
									         (self
										          debugSuspend: exception
										          registered: [ release value ]) ] ] ] ensure: [
			release value ] ]
		forkAt: Processor activeProcess priority
		named: 'PLS evaluation'.
	done wait.
	stopped ifNotNil: [
			^ stoppedBlock cull: ((stopped isKindOf: UnhandledError)
					   ifTrue: [ stopped exception ]
					   ifFalse: [ stopped ]) ].
	^ value
]

{ #category : 'debug' }
PLSServer >> debugExceptionFilters [
	"The exception filters of the client, by id, each with its condition ('' for none): the unhandled exceptions of the image that stop for its debugger. Until the client sets them, unhandled errors and halts stop, as in Pharo"

	^ debugExceptionFilters ifNil: [
			  Dictionary new
				  at: 'error' put: '';
				  at: 'halt' put: '';
				  yourself ]
]

{ #category : 'debug' }
PLSServer >> debugExceptionFilters: someFilterIds options: someFilterOptions [
	"Keep the exception filters the client enabled, the filters of a DAP setExceptionBreakpoints request: someFilterIds without condition, and someFilterOptions with one ({filterId, condition}). The deprecation filter makes deprecations signal a warning"

	| filters |
	filters := Dictionary new.
	someFilterIds do: [ :each | filters at: each put: '' ].
	someFilterOptions do: [ :each |
			filters
				at: (each at: #filterId)
				put:
				((each at: #condition ifAbsent: [ '' ]) ifNil: [ '' ]) trimBoth ].
	debugExceptionFilters := filters.
	Deprecation raiseWarning: (filters includesKey: 'deprecation')
]

{ #category : 'pls - debug' }
PLSServer >> debugHasClient [
	"Answer whether a client can take the processes stopped on an exception"

	^ clientOutStream notNil
]

{ #category : 'debug' }
PLSServer >> debugInstall: someBreakpointsAndNodes at: aKey [
	"Install a debug point for each association of a breakpoint of the client with the node where it stops (a String saying why there is none) and keep them at aKey, instead of the ones there. Answer what the client shows of each"

	| installed answers |
	self debugPointsAt: aKey put: #(  ).
	installed := OrderedCollection new.
	answers := someBreakpointsAndNodes collect: [ :each |
			           each value isString
				           ifTrue: [ self debugUnverified: each value ]
				           ifFalse: [
						           [
							           | point |
							           point := self debugPointFor: each key on: each value.
							           installed add: point.
							           self debugVerified: point ]
							           on: Error
							           do: [ :error |
							           self debugUnverified: error messageText ] ] ].
	self debugPointsAt: aKey put: installed.
	^ answers asArray
]

{ #category : 'debug' }
PLSServer >> debugLineOf: anIndex in: aString [
	"The line of aString, from 1, that holds the character at anIndex"

	^ (aString first: (anIndex max: 1)) lines size max: 1
]

{ #category : 'pls - debug' }
PLSServer >> debugMutex [

	^ debugMutex ifNil: [ debugMutex := Mutex new ]
]

{ #category : 'debug' }
PLSServer >> debugNodeIn: aMethod atLine: aLine [
	"The first statement of aMethod, or of a block in it, that starts on aLine of its source, or after it. Answer a String saying why when there is none"

	| source statements |
	source := aMethod sourceCode.
	statements := ((aMethod ast allChildren select: [ :each |
		                each isSequence ]) flatCollect: [ :each |
		               each statements ]) asSortedCollection: [ :a :b |
		              a start <= b start ].
	^ statements
		  detect: [ :each |
		  (self debugLineOf: each start in: source) >= aLine ]
		  ifNone: [ 'No statement on this line or after it' ]
]

{ #category : 'debug' }
PLSServer >> debugPointFor: aBreakpoint on: aNode [
	"A debug point of Pharo stopping before aNode, with the condition, the hit condition and the log message of aBreakpoint of the client"

	| point |
	point := DebugPointManager
		         installNew: BreakDebugPoint
		         on: aNode
		         withBehaviors: #(  ).
	aBreakpoint at: #condition ifPresent: [ :condition |
			(condition isString and: [ condition trimBoth isNotEmpty ])
				ifTrue: [
						point addBehavior: (ConditionBehavior new
								 condition: condition;
								 priority: 30;
								 yourself) ] ].
	aBreakpoint at: #hitCondition ifPresent: [ :condition |
			(condition isString and: [ condition trimBoth isNotEmpty ])
				ifTrue: [
						point addBehavior: (PLSHitConditionBehavior new
								 condition: condition;
								 yourself) ] ].
	aBreakpoint at: #logMessage ifPresent: [ :message |
			(message isString and: [ message isNotEmpty ]) ifTrue: [
					point addBehavior: (PLSLogPointBehavior new
							 message: message;
							 yourself) ] ].
	^ point
]

{ #category : 'debug' }
PLSServer >> debugPoints [
	"The debug points the client installed, by pls-env id of their method, or #function for the function breakpoints"

	^ self debugMutex critical: [
		  debugPoints ifNil: [ debugPoints := Dictionary new ] ]
]

{ #category : 'debug' }
PLSServer >> debugPointsAt: aKey put: someDebugPoints [
	"Remove the debug points installed at aKey, and keep someDebugPoints instead"

	| previous |
	previous := self debugMutex critical: [
			            | points old |
			            points := debugPoints ifNil: [
				                      debugPoints := Dictionary new ].
			            old := points at: aKey ifAbsent: [ #(  ) ].
			            someDebugPoints
				            ifEmpty: [ points removeKey: aKey ifAbsent: [ ] ]
				            ifNotEmpty: [
				            points at: aKey put: someDebugPoints asArray ].
			            old ].
	previous do: [ :each |
			[ each remove ]
				on: Error
				do: [ :error |  ] ]
]

{ #category : 'debug' }
PLSServer >> debugRegister: aDebugSession [
	"Keep aDebugSession until a debugger of the client takes it or dismisses it, and tell the client in a pls-debug/stopped notification (see #debugRegister:atOnce:). Answer its id"

	^ self debugRegister: aDebugSession atOnce: false
]

{ #category : 'debug' }
PLSServer >> debugRegister: aDebugSession atOnce: atOnce [
	"Keep aDebugSession until a debugger of the client takes it or dismisses it, and tell the client in a pls-debug/stopped notification, with the exception, the class of its receiver and the top frames of the stack. The client opens its debugger at once on a breakpoint, or when atOnce, and offers it otherwise. Answer its id"

	| id exception frames |
	id := self debugMutex critical: [
			      debugSessions ifNil: [ debugSessions := Dictionary new ].
			      debugNextId := (debugNextId ifNil: [ 0 ]) + 1.
			      debugSessions at: debugNextId put: aDebugSession.
			      debugNextId ].
	exception := aDebugSession exception.
	frames := [
		          (aDebugSession interruptedContext stackOfSize: 5)
			          collect: [ :each | each printString ] ]
		          on: Error
		          do: [ :error | #(  ) ].
	self sendNotification: 'pls-debug/stopped' params: {
			(#id -> id).
			(#name -> aDebugSession name asString).
			(#exception
			 -> (exception ifNotNil: [ exception class name asString ])).
			(#description
			 -> (exception ifNotNil: [ exception description asString ])).
			(#receiverClass -> ([
				  (thisContext objectClass:
					   aDebugSession interruptedContext receiver) name asString ]
				  on: Error
				  do: [ :error | nil ])).
			(#doesNotUnderstand -> (exception isKindOf: MessageNotUnderstood)).
			(#subclassResponsibility
			 -> (exception isKindOf: SubclassResponsibility)).
			(#breakpoint -> (atOnce or: [ exception isKindOf: Break ])).
			(#frames -> frames asArray) } asDictionary.
	^ id
]

{ #category : 'pls - debug' }
PLSServer >> debugSessionAt: id [
	"Answer the debug session of the id, waiting for a debugger of the client, and forget it: a single debugger takes it.
	 Its process tells the client before it suspends itself: wait a little for it to be suspended"

	| session |
	session := self debugMutex critical: [
			           (debugSessions ifNil: [ Dictionary new ])
				           removeKey: id
				           ifAbsent: [
				           PLSUnknownEntity signal:
					           'Unknown debug session: ' , id printString ] ].
	100 timesRepeat: [
			session interruptedProcess isSuspended ifTrue: [ ^ session ].
			10 milliSeconds wait ].
	^ session
]

{ #category : 'debug' }
PLSServer >> debugShouldStopOn: anException [
	"Answer whether anException, that nobody handled, stops for the debugger of the client, as its exception filters say. A breakpoint always stops"

	| exception filters |
	exception := (anException isKindOf: UnhandledError)
		             ifTrue: [ anException exception ]
		             ifFalse: [ anException ].
	(exception isKindOf: Break) ifTrue: [ ^ true ].
	filters := self debugExceptionFilters.
	(exception isKindOf: Halt) ifTrue: [ ^ filters includesKey: 'halt' ].
	(exception isKindOf: Deprecation) ifTrue: [
		^ filters includesKey: 'deprecation' ].
	((exception isKindOf: MessageNotUnderstood) and: [
		 filters includesKey: 'messageNotUnderstood' ]) ifTrue: [ ^ true ].
	^ filters
		  at: 'error'
		  ifPresent: [ :condition |
				  condition isEmpty or: [
						  (self debugClassesIn: condition) anySatisfy: [ :each |
							  exception isKindOf: each ] ] ]
		  ifAbsent: [ false ]
]

{ #category : 'debug' }
PLSServer >> debugSkip: anException [
	"anException, that nobody handled, does not stop for the debugger of the client. A resumable one resumes; another one ends its active, as dismissing its debugger would, and is written on the Transcript. Answer the value to resume anException with"

	| exception active |
	exception := (anException isKindOf: UnhandledError)
		             ifTrue: [ anException exception ]
		             ifFalse: [ anException ].
	exception isResumable ifTrue: [ ^ nil ].
	Transcript
		show: exception description , ' (not debugged: exception filters)';
		cr.
	active := Processor activeProcess.
	UIManager default uiProcess == active ifTrue: [
		UIManager default spawnNewProcess ].
	active terminate.
	^ nil
]

{ #category : 'pls - debug' }
PLSServer >> debugSuspend: anException [
	"Suspend the active process on anException, that nobody handled, until a debugger of the client resumes it, as the debugger of Pharo does. Answer the value to resume anException with.
	 The exception of an UnhandledError is the one the debugger shows"

	^ self debugSuspend: anException registered: [ ]
]

{ #category : 'pls - debug' }
PLSServer >> debugSuspend: anException registered: aBlock [
	"As #debugSuspend:, and evaluate aBlock once the client knows the debug session, just before the process suspends. A halt or a breakpoint stops in the method that halts, not in the methods of the halt"

	| exception session |
	exception := (anException isKindOf: UnhandledError)
		             ifTrue: [ anException exception ]
		             ifFalse: [ anException ].
	session := Processor activeProcess
		           newDebugSessionNamed: exception description
		           startedAt: ((exception isKindOf: Halt)
				            ifTrue: [
				            exception signalerContext filterDebuggerStack ]
				            ifFalse: [ exception signalerContext ]).
	session exception: exception.
	self debugRegister: session.
	aBlock value.
	Processor activeProcess suspend.
	^ nil
]

{ #category : 'debug' }
PLSServer >> debugUnverified: aString [

	^ {
		  (#verified -> false).
		  (#message -> aString) } asDictionary
]

{ #category : 'debug' }
PLSServer >> debugVerificationsAt: aUri of: someBreakpoints [
	"What the client shows of someBreakpoints of the editor aUri, the breakpoints of a DAP setBreakpoints request: the debug points the client installed with pls-debug:setBreakpoints, on the statements of their lines"

	| uri entry |
	uri := aUri urlDecoded.
	entry := (self debugMutex critical: [
		          (debugPoints ifNil: [ Dictionary new ]) associations ])
		         detect: [ :each |
				         each key ~= #function and: [
						         ([
							          (self navUriOfMethod:
								           (self envMethodNamed: (self envPathOf: each key)))
								          urlDecoded ]
							          on: PLSUnknownEntity
							          do: [ :error | nil ]) = uri ] ]
		         ifNone: [ nil ].
	^ someBreakpoints collect: [ :each |
			  | node point |
			  point := entry ifNotNil: [
					           node := self
						                   debugNodeIn:
						                   (self envMethodNamed:
							                    (self envPathOf: entry key))
						                   atLine: (each at: #line).
					           node isString ifFalse: [
							           entry value
								           detect: [ :candidate |
								           candidate nodes anyOne start = node start ]
								           ifNone: [ nil ] ] ].
			  point
				  ifNil: [ self debugUnverified: 'Not installed in the image' ]
				  ifNotNil: [ self debugVerified: point ] ]
]

{ #category : 'debug' }
PLSServer >> debugVerified: aDebugPoint [
	"What the client shows of a breakpoint installed as aDebugPoint: the line of its method where it stops"

	| node |
	node := aDebugPoint nodes anyOne.
	^ {
		  (#verified -> true).
		  (#line
		   -> (self debugLineOf: node start in: node methodNode sourceCode)) }
		  asDictionary
]

{ #category : 'lsp - diagnostics' }
PLSServer >> diagnosticsOf: aDocument [
	"Answer the diagnostics of aDocument: the errors of compilation, then its critiques"

	| diagnostics |
	diagnostics := aDocument diagnostics asArray collect: [ :each |
		               each asJRPCJSON ].
	self critiquesEnabled ifFalse: [ ^ diagnostics ].
	^ diagnostics , ([
	   aDocument critiques collect: [ :each | each diagnostic asJRPCJSON ] ]
		   on: Error
		   do: [ #(  ) ])
]

{ #category : 'lsp - text synchronisation' }
PLSServer >> didChange: textDocument contentChanges: contentChanges [

	<jrpc: #'textDocument/didChange'>
	| document |
	document := self context
		            textItem: (textDocument at: #uri)
		            ifAbsent: [ self openDocument: textDocument ].
	document version: (textDocument at: #version).
	document text: (contentChanges anyOne at: #text).
	"If diagnostic is not nil, we are in a pull diagnostic context. Else, we are in a push diagnostic context"
	self publishDiagnosticsFor: document
]

{ #category : 'lsp - workspace' }
PLSServer >> didChangeConfiguration: settings [
	"Follow the settings of the client: pharo.critiques.enabled shows or hides the critiques"

	<jrpc: #'workspace/didChangeConfiguration'>
	| enabled |
	enabled := [ ((settings at: #pharo) at: #critiques) at: #enabled ]
		           on: Error
		           do: [ true ].
	enabled = self critiquesEnabled ifTrue: [ ^ nil ].
	critiquesEnabled := enabled.
	self critiquesRefresh.
	^ nil
]

{ #category : 'lsp - text synchronisation' }
PLSServer >> didClose: textDocument [

	<jrpc: #'textDocument/didClose'>
	| document |
	document := self context removeItem: (textDocument at: #uri).
	(PLSDocument isTonelDocument: textDocument) ifFalse: [
		self
			sendNotification: 'textDocument/publishDiagnostics'
			params: (PLSPublishDiagnosticsParams new
					 diagnostics: {  };
					 uri: document uri;
					 version: document version;
					 yourself) ]
]

{ #category : 'lsp - text synchronisation' }
PLSServer >> didOpen: textDocument [

	<jrpc: #'textDocument/didOpen'>
	| document |
	document := self openDocument: textDocument.
	"If diagnostic is not nil, we are in a pull diagnostic context. Else, we are in a push diagnostic context"
	self publishDiagnosticsFor: document
]

{ #category : 'lsp - text synchronisation' }
PLSServer >> didSave: textDocument text: text [
	"Install the code in the image if the code is part of a tonel file"

	<jrpc: #'textDocument/didSave'>
	(self context textItem: (textDocument at: #uri) ifAbsent: [ nil ])
		ifNotNil: [ :document | document savedText: text ].
	(PLSDocument isTonelDocument: textDocument) ifTrue: [
		(PLSTonelParser parseString: text asByteArray utf8Decoded) do: #load ]
]

{ #category : 'lsp - diagnostics' }
PLSServer >> documentDiagnosticFor: textDocument withIdentifier: identifier andPreviousResult: previousResultId [

	<jrpc: #'textDocument/diagnostic'>
	^ (PLSFullDocumentDiagnosticsReport new
		   items:
			   (self diagnosticsOf:
					    (self context textItem: (textDocument at: #uri)));
		   yourself) asJRPCJSON
]

{ #category : 'lsp - document symbol' }
PLSServer >> documentSymbol: textDocument [

	<jrpc: #'textDocument/documentSymbol'>
	| document |
	document := self context textItem: (textDocument at: #uri).
	^ document symbols
]

{ #category : 'pls - variables' }
PLSServer >> documentVariables: textDocument [
	<jrpc: #'pls:documentVariables'>
	| document |
	document := self context
		textItem: (textDocument at: #uri at: #path).
	^ (document binder bindings associations
		collect: [ :assoc |
			  PLSVariable new
				name: assoc key printString;
				value: assoc value printString;
				variableReference: assoc key;
				isDirectory: assoc value class allInstVarNames isNotEmpty;
				yourself ]
		as: Array) asJRPCJSON
]

{ #category : 'pls - env' }
PLSServer >> envAddRepositoryOf: id to: entity [
	"Complete the entity id with the name of its Iceberg repository, and, for a project or a package, whether that repository holds changes of it not committed yet.
	 The repository of a project is the one of its baseline"

	| kind path repositories packageName |
	kind := self envKindOf: id.
	path := self envPathOf: id.
	repositories := self envRepositoriesByPackageName.
	packageName := kind = 'project'
		               ifTrue: [
		               path = '*' ifFalse: [
			               (self envBaselineNamed: path) package name ] ]
		               ifFalse: [ self envPackageNameOf: id ].
	entity at: #repository put: (packageName ifNotNil: [
				 (repositories at: packageName ifAbsent: [ nil ]) ifNotNil: [
					 :repository | repository name ] ]).
	kind = 'package' ifTrue: [
			entity
				at: #modified
				put:
				(self envIsPackageNamed: packageName modifiedIn: repositories) ].
	kind = 'project' ifTrue: [
			entity
				at: #modified
				put: ((self envProjectChildren: path) anySatisfy: [ :packageId |
							 self
								 envIsPackageNamed: (self envPathOf: packageId)
								 modifiedIn: repositories ]) ]
]

{ #category : 'pls - env changes' }
PLSServer >> envAnnouncementSelectors [
	"Answer the system announcements that change the environment model, with the method that records each of them"

	^ {
		  (PackageAdded -> #envPackageAdded:).
		  (PackageRemoved -> #envPackageRemoved:).
		  (PackageRenamed -> #envPackageRenamed:).
		  (PackageTagAdded -> #envTagAdded:).
		  (PackageTagRemoved -> #envTagRemoved:).
		  (PackageTagRenamed -> #envTagRenamed:).
		  (ClassAdded -> #envClassAdded:).
		  (ClassModifiedClassDefinition -> #envClassChanged:).
		  (ClassCommented -> #envClassChanged:).
		  (ClassParentRenamed -> #envClassChanged:).
		  (ClassRenamed -> #envClassRenamed:).
		  (ClassRepackaged -> #envClassRepackaged:).
		  (ClassRemoved -> #envClassRemoved:).
		  (ProtocolAdded -> #envProtocolAdded:).
		  (ProtocolRemoved -> #envProtocolRemoved:).
		  (ProtocolRenamed -> #envProtocolRenamed:).
		  (MethodAdded -> #envMethodAdded:).
		  (MethodModified -> #envMethodChanged:).
		  (MethodRepackaged -> #envMethodChanged:).
		  (MethodRecategorized -> #envMethodRecategorized:).
		  (MethodRemoved -> #envMethodRemoved:) } asOrderedDictionary
]

{ #category : 'pls - env' }
PLSServer >> envBaselineNamed: aString [

	| baseline |
	baseline := self class environment classNamed: 'BaselineOf' , aString.
	(baseline notNil and: [
			 (baseline inheritsFrom: BaselineOf) and: [
				 baseline includesSelector: #baseline: ] ]) ifFalse: [
		PLSUnknownEntity signal: 'Unknown project: ' , aString printString ].
	^ baseline
]

{ #category : 'pls - env' }
PLSServer >> envBaselines [
	"Answer the Metacello baselines of the image, sorted by name"

	^ (BaselineOf allSubclasses select: [ :baseline |
		   baseline includesSelector: #baseline: ]) sorted: [ :a :b |
		  a name <= b name ]
]

{ #category : 'pls - env' }
PLSServer >> envBehaviorNamed: aString [
	"aString is a class or trait name, followed by ' class' for its class side"

	| class |
	class := self class environment classOrTraitNamed:
		         (aString withoutSuffix: ' class').
	(class isNil or: [ class isClassSide ]) ifTrue: [
		PLSUnknownEntity signal: 'Unknown class: ' , aString printString ].
	^ (aString endsWith: ' class')
		  ifTrue: [ class classSide ]
		  ifFalse: [ class ]
]

{ #category : 'pls - env' }
PLSServer >> envBehaviorPathOf: aBehavior [

	^ aBehavior isClassSide
		  ifTrue: [ aBehavior instanceSide name , ' class' ]
		  ifFalse: [ aBehavior name ]
]

{ #category : 'pls - env changes' }
PLSServer >> envChange: kind id: id [
	"kind is added, changed, removed, renamed or moved"

	^ Dictionary new
		  at: #kind put: kind;
		  at: #id put: id;
		  yourself
]

{ #category : 'pls - env changes' }
PLSServer >> envChangesAreSettled [
	"Pending changes are sent once the system stays quiet for envQuietDelay, or envMaxDelay after the first of them.
	 A flood of changes that overflowed waits for the quiet, so that the client reloads everything once"

	^ envChangesMutex critical: [
			  | now |
			  now := Time millisecondClockValue.
			  now - envLastChangeTime >= self envQuietDelay or: [
				  envOverflow not and: [
					  now - envFirstChangeTime >= self envMaxDelay ] ] ]
]

{ #category : 'pls - env edition' }
PLSServer >> envCheckVersionOf: id is: expectedVersion [
	"Signal a conflict if expectedVersion is given and the entity id is no longer at that version, or no longer exists"

	| currentVersion |
	expectedVersion ifNil: [ ^ self ].
	currentVersion := [ self envVersionOf: id ]
		                  on: PLSUnknownEntity
		                  do: [ nil ].
	currentVersion = expectedVersion ifFalse: [
			PLSEntityConflict new
				id: id;
				currentVersion: currentVersion;
				signal ]
]

{ #category : 'pls - env' }
PLSServer >> envChildren: id offset: offset limit: limit [
	"Answer one page of the children of the entity id, as nodes, with the total number of children.
	 offset is zero-based and defaults to 0; limit defaults to all the remaining children"

	<jrpc: #'pls-env:children'>
	| ids start stop |
	ids := self envChildrenIds: id.
	start := (offset ifNil: [ 0 ]) max: 0.
	stop := limit
		        ifNil: [ ids size ]
		        ifNotNil: [ start + limit min: ids size ].
	^ {
		  (#items -> ((start + 1 to: stop)
			    collect: [ :index | self envNode: (ids at: index) ]
			    as: Array)).
		  (#total -> ids size) } asDictionary
]

{ #category : 'pls - env' }
PLSServer >> envChildrenIds: id [
	"Answer the ids of the children of the entity id, in display order"

	^ self
		  perform:
		  ('env' , (self envKindOf: id) capitalized , 'Children:') asSymbol
		  with: (self envPathOf: id)
]

{ #category : 'pls - env changes' }
PLSServer >> envClassAdded: anAnnouncement [

	| class |
	class := anAnnouncement classAffected instanceSide.
	(self envIgnoresBehavior: class) ifTrue: [ ^ self ].
	self envRecord: [
			(self envChange: 'added' id: (self envClassIdOf: class))
				at: #parent
				put:
					(self envClassParentIdIn: class package tag: class packageTag);
				at: #version put: (self envVersionOfClass: class);
				yourself ]
]

{ #category : 'pls - env changes' }
PLSServer >> envClassChanged: anAnnouncement [

	| class |
	class := anAnnouncement classAffected instanceSide.
	(self envIgnoresBehavior: class) ifTrue: [ ^ self ].
	self envRecord: [
			(self envChange: 'changed' id: (self envClassIdOf: class))
				at: #version put: (self envVersionOfClass: class);
				yourself ]
]

{ #category : 'pls - env' }
PLSServer >> envClassChildren: aString [
	"A class has two sides, the instance side and the class side"

	self envClassNamed: aString.
	^ {
		  ('side:' , aString).
		  ('side:' , aString , ' class') }
]

{ #category : 'pls - env changes' }
PLSServer >> envClassIdOf: aClass [

	^ 'class:' , aClass instanceSide name
]

{ #category : 'pls - env' }
PLSServer >> envClassNamed: aString [
	"Answer the class or trait named aString. Its class side is not a class entity but a side"

	(aString endsWith: ' class') ifTrue: [
		PLSUnknownEntity signal: 'Unknown class: ' , aString printString ].
	^ self envBehaviorNamed: aString
]

{ #category : 'pls - env' }
PLSServer >> envClassNode: aString [

	| class |
	class := self envClassNamed: aString.
	^ Dictionary new
		  at: #name put: class name;
		  at: #parent put: (class packageTag isRoot
				   ifTrue: [ 'package:' , class package name ]
				   ifFalse: [
					   'tag:' , class package name , '/' , class packageTag name ]);
		  at: #hasChildren put: true;
		  at: #flags put: {
				  (#abstract -> class isAbstract).
				  (#test -> (class includesBehavior: TestCase)).
				  (#deprecated -> class isDeprecated).
				  (#trait -> class isTrait) } asDictionary;
		  yourself
]

{ #category : 'pls - env changes' }
PLSServer >> envClassParentIdIn: aPackage tag: aTag [

	^ (aTag isNil or: [ aTag isRoot ])
		  ifTrue: [ 'package:' , aPackage name ]
		  ifFalse: [ 'tag:' , aPackage name , '/' , aTag name ]
]

{ #category : 'pls - env changes' }
PLSServer >> envClassRemoved: anAnnouncement [
	"A removed class is already renamed AnObsolete..."

	| class |
	class := anAnnouncement classRemoved instanceSide.
	(self envIgnoresBehavior: class) ifTrue: [ ^ self ].
	self envRecord: [
			(self
				 envChange: 'removed'
				 id: 'class:' , (class name withoutPrefix: 'AnObsolete'))
				at: #parent put: (class package ifNotNil: [ :package |
							 self envClassParentIdIn: package tag: class packageTag ]);
				yourself ]
]

{ #category : 'pls - env changes' }
PLSServer >> envClassRenamed: anAnnouncement [
	"The ids of the sides, protocols and methods of the class change with it"

	(self envIgnoresBehavior: anAnnouncement classRenamed) ifTrue: [
		^ self ].
	self envRecord: [
			(self envChange: 'renamed' id: 'class:' , anAnnouncement newName)
				at: #oldId put: 'class:' , anAnnouncement oldName;
				yourself ]
]

{ #category : 'pls - env changes' }
PLSServer >> envClassRepackaged: anAnnouncement [

	| class |
	class := anAnnouncement classRepackaged instanceSide.
	(self envIgnoresBehavior: class) ifTrue: [ ^ self ].
	self envRecord: [
			(self envChange: 'moved' id: (self envClassIdOf: class))
				at: #parent put: (self
						 envClassParentIdIn: anAnnouncement newPackage
						 tag: anAnnouncement newTag);
				at: #oldParent put: (self
						 envClassParentIdIn: anAnnouncement oldPackage
						 tag: anAnnouncement oldTag);
				yourself ]
]

{ #category : 'pls - env edition' }
PLSServer >> envClassify: id protocol: protocol [
	"Move the method id to protocol without compiling it again, and answer its id and its new protocol"

	<jrpc: #'pls-env:classify'>
	| method |
	(self envKindOf: id) = 'method' ifFalse: [
			PLSUnknownEntity signal:
				'Only methods can be classified: ' , id printString ].
	(protocol isNil or: [ protocol isEmpty ]) ifTrue: [
		PLSUnknownEntity signal: 'A protocol is needed to classify ' , id ].
	method := self envMethodNamed: (self envPathOf: id).
	method methodClass classify: method selector under: protocol.
	^ {
		  (#id -> id).
		  (#protocol -> (method methodClass >> method selector) protocolName) }
		  asDictionary
]

{ #category : 'pls - env edition' }
PLSServer >> envCodeErrorClass [
	"Answer the error the compiler signals for code that does not compile: OCCodeError since Pharo 13, CodeError before"

	^ self class environment
		  at: #OCCodeError
		  ifAbsent: [ self class environment at: #CodeError ]
]

{ #category : 'pls - env edition' }
PLSServer >> envCompilationFailure: diagnostics [

	^ {
		  (#compiled -> false).
		  (#id -> nil).
		  (#version -> nil).
		  (#diagnostics -> diagnostics asArray) } asDictionary
]

{ #category : 'pls - env edition' }
PLSServer >> envCompile: id source: source protocol: protocol expectedVersion: expectedVersion [
	"Compile source into the image and answer whether it compiled, the id of the result, its version and the diagnostics.
	 id is the method or class to replace, or the side of a class to add a method to. A source that declares another selector
	 or class name creates that entity and leaves the one named by id unchanged.
	 The protocol of a method defaults to the one of the method it replaces.
	 With expectedVersion, the compilation is refused with a conflict if the entity id is no longer at that version.
	 The editors of the client are not saved through the server: their critiques are computed again now"

	<jrpc: #'pls-env:compile'>
	^ [
	  self
		  envCompileEntity: id
		  source: source
		  protocol: protocol
		  expectedVersion: expectedVersion ] ensure: [ self critiquesRefresh ]
]

{ #category : 'pls - env edition' }
PLSServer >> envCompileClassFrom: source [

	| definitions classDefinition diagnostics |
	definitions := [ PLSTonelParser parseString: source ]
		               on: Error
		               do: [ :error |
				               ^ self envCompilationFailure: { (self
						                  envDiagnostic: error messageText
						                  in: source
						                  from: 1
						                  to: source size
						                  severity: 1) } ].
	classDefinition := definitions
		                   detect: [ :definition |
		                   definition isClassDefinition ]
		                   ifNone: [
				                   ^ self envCompilationFailure: { (self
						                      envDiagnostic: 'No class definition'
						                      in: source
						                      from: 1
						                      to: source size
						                      severity: 1) } ].
	diagnostics := (definitions anySatisfy: [ :definition |
		                definition isMethodDefinition ])
		               ifTrue: [
				               { (self
					                envDiagnostic:
					                'Methods are not compiled with a class definition'
					                in: source
					                from: 1
					                to: source size
					                severity: 2) } ]
		               ifFalse: [ #(  ) ].
	[ classDefinition load ]
		on: Error
		do: [ :error |
				^ self envCompilationFailure: { (self
						   envDiagnostic: error messageText
						   in: source
						   from: 1
						   to: source size
						   severity: 1) } ].
	^ {
		  (#compiled -> true).
		  (#id -> ('class:' , classDefinition className)).
		  (#version -> (self envVersionOfClass:
			    (self class environment classNamed: classDefinition className))).
		  (#diagnostics -> diagnostics) } asDictionary
]

{ #category : 'pls - env edition' }
PLSServer >> envCompileEntity: id source: source protocol: protocol expectedVersion: expectedVersion [
	"Compile source into the image, as envCompile:source:protocol:expectedVersion: answers"

	| kind path |
	kind := self envKindOf: id.
	path := self envPathOf: id.
	self envCheckVersionOf: id is: expectedVersion.
	kind = 'class' ifTrue: [ ^ self envCompileClassFrom: source ].
	kind = 'side' ifTrue: [
			^ self
				  envCompileMethodIn: (self envBehaviorNamed: path)
				  from: source
				  protocol: protocol
				  replacing: nil ].
	kind = 'method' ifTrue: [
			| behavior |
			behavior := self envBehaviorNamed:
				            (path
					             copyFrom: 1
					             to: (path indexOfSubCollection: '>>') - 1).
			^ self
				  envCompileMethodIn: behavior
				  from: source
				  protocol: protocol
				  replacing: ([ self envMethodNamed: path ]
						   on: PLSUnknownEntity
						   do: [ nil ]) ].
	PLSUnknownEntity signal:
		'Only classes and methods can be compiled: ' , id printString
]

{ #category : 'pls - env edition' }
PLSServer >> envCompileMethodIn: aBehavior from: source protocol: protocol replacing: aMethodOrNil [
	"Compile source in aBehavior. Syntax and semantic errors are answered as diagnostics; an undeclared variable is only a warning, as when Pharo loads code"

	| ast diagnostics selector |
	ast := RBParser parseFaultyMethod: source.
	diagnostics := OrderedCollection new.
	ast acceptVisitor:
		(RBParseErrorNodeVisitor new visitBlock: [ :errorNode |
				 diagnostics add: (self
						  envDiagnostic: errorNode errorMessage
						  in: source
						  from: errorNode start
						  to: errorNode stop
						  severity: 1) ]).
	diagnostics ifNotEmpty: [ ^ self envCompilationFailure: diagnostics ].
	selector := [
		            [
			            aBehavior
				            compile: source
				            classified: (protocol ifNil: [
							             ((aBehavior
								               compiledMethodAt: ast selector
								               ifAbsent: [ aMethodOrNil ]) ifNotNil: [ :method |
								              method protocolName ]) ifNil: [
								             Protocol unclassified ] ]) ]
			            on: OCUndeclaredVariableWarning
			            do: [ :warning |
					            diagnostics add: (self
							             envDiagnostic:
							             'Undeclared variable: ' , warning node name
							             in: source
							             from: warning node start
							             to: warning node stop
							             severity: 2).
					            warning resume: warning defaultAction ] ]
		            on: self envCodeErrorClass
		            do: [ :error |
				            diagnostics add: (self
						             envDiagnostic: error messageText
						             in: source
						             from:
						             (error node
							              ifNil: [ error position ]
							              ifNotNil: [ :node | node start ])
						             to:
						             (error node
							              ifNil: [ error position ]
							              ifNotNil: [ :node | node stop ])
						             severity: 1).
				            ^ self envCompilationFailure: diagnostics ].
	^ {
		  (#compiled -> true).
		  (#id
		   ->
		   ('method:' , (self envBehaviorPathOf: aBehavior) , '>>'
		    , selector)).
		  (#version -> (self envVersionOfMethod: aBehavior >> selector)).
		  (#diagnostics -> diagnostics asArray) } asDictionary
]

{ #category : 'pls - env edition' }
PLSServer >> envDiagnostic: message in: source from: start to: stop severity: severity [
	"start and stop are the one-based indexes of the first and last characters of the error in source.
	 severity is 1 for an error, 2 for a warning"

	^ {
		  (#message -> message).
		  (#severity -> severity).
		  (#range -> (PLSRange
			    start: (source toLineCharacter: (start - 1 max: 0))
			    end: (source toLineCharacter: (stop max: start))) asJRPCJSON) }
		  asDictionary
]

{ #category : 'pls - env history' }
PLSServer >> envDismissLostChanges: refs [
	"Forget the lost changes refs without applying them"

	<jrpc: #'pls-env:dismissLostChanges'>
	refs do: [ :ref | PLSLostChanges current handle: ref ].
	^ { (#dismissed -> refs asArray) } asDictionary
]

{ #category : 'pls - env' }
PLSServer >> envEntity: id [
	"Answer the node of the entity id, completed with its package and Iceberg repository, whether that repository holds
	 uncommitted changes of a project or package, its superclass for a class, the version of a class or method, which
	 changes with its source, and the slots, traits and redefined selectors of a side"

	<jrpc: #'pls-env:entity'>
	| entity packageName |
	entity := self envNode: id.
	packageName := self envPackageNameOf: id.
	entity
		at: #package
		put: (packageName ifNotNil: [ 'package:' , packageName ]).
	self envAddRepositoryOf: id to: entity.
	(entity at: #kind) = 'class' ifTrue: [
			| class |
			class := self envClassNamed: (self envPathOf: id).
			entity
				at: #superclass
				put: (class superclass ifNotNil: [ :superclass |
						 'class:' , superclass name ]).
			entity at: #version put: (self envVersionOfClass: class) ].
	(entity at: #kind) = 'side' ifTrue: [
			self
				envSideDetailsOf: (self envBehaviorNamed: (self envPathOf: id))
				in: entity ].
	(entity at: #kind) = 'method' ifTrue: [
			entity
				at: #version
				put:
				(self envVersionOfMethod:
					 (self envMethodNamed: (self envPathOf: id))) ].
	^ entity
]

{ #category : 'pls - env' }
PLSServer >> envExtensionsChildren: aString [

	^ ((self envPackageNamed: aString) extensionMethods collect: [
			   :method |
			   'method:' , (self envBehaviorPathOf: method methodClass) , '>>'
			   , method selector ]) asArray sort
]

{ #category : 'pls - env' }
PLSServer >> envExtensionsNode: aString [
	"The extensions of a package gather the methods it adds to classes of other packages"

	| package |
	package := self envPackageNamed: aString.
	^ Dictionary new
		  at: #name put: 'Extensions';
		  at: #parent put: 'package:' , package name;
		  at: #hasChildren put: package extensionMethods notEmpty;
		  at: #flags put: Dictionary new;
		  yourself
]

{ #category : 'pls - env changes' }
PLSServer >> envFlushChanges [
	"Send the pending changes to the client in one pls-env/didChange notification"

	| mutex changes reset |
	mutex := envChangesMutex ifNil: [ ^ self ].
	mutex critical: [
			changes := envChanges values asArray.
			reset := envOverflow.
			envChanges := OrderedDictionary new.
			envOverflow := false.
			envFirstChangeTime := nil ].
	(changes isEmpty and: [ reset not ]) ifTrue: [ ^ self ].
	clientOutStream ifNil: [ ^ self ].
	self sendNotification: 'pls-env/didChange' params: {
			(#changes -> changes).
			(#reset -> reset) } asDictionary
]

{ #category : 'pls - env changes' }
PLSServer >> envFlushLoop [

	[
		envChangesReady wait.
		[
			(Delay forMilliseconds: 20) wait.
			self envChangesAreSettled ] whileFalse.
		self envFlushChanges ] repeat
]

{ #category : 'pls - env history' }
PLSServer >> envHistory: id [
	"Answer the versions of the method id that the changes file holds, newest first. The first is its current source"

	<jrpc: #'pls-env:history'>
	| method records items |
	(self envKindOf: id) = 'method' ifFalse: [
			PLSUnknownEntity signal:
				'Only methods have a history: ' , id printString ].
	method := self envMethodNamed: (self envPathOf: id).
	records := method sourcePointer
		           ifNil: [ #(  ) ]
		           ifNotNil: [
		           SourceFiles changeRecordsFor:
			           method asRingDefinition asHistorical ].
	items := records collect: [ :record |
			         self
				         envVersionWithSource: record sourceCode
				         protocol: record protocol
				         stamp: record stamp ].
	(items isEmpty or: [ (items first at: #source) ~= method sourceCode ])
		ifTrue: [
				items := (OrderedCollection withAll: items)
					         addFirst: (self
							          envVersionWithSource: method sourceCode
							          protocol: method protocolName
							          stamp: nil);
					         yourself ].
	^ { (#items -> items asArray) } asDictionary
]

{ #category : 'pls - env history' }
PLSServer >> envIdOfLostChange: anEvent [
	"Answer the pls-env id of the entity anEvent changes, nil for an entity without one"

	anEvent isEpMethodChange ifTrue: [
			^ 'method:' , anEvent behaviorAffectedName , '>>'
			  , anEvent methodAffectedSelector ].
	anEvent isEpProtocolChange ifTrue: [
			^ 'protocol:' , anEvent behaviorAffectedName , '>>'
			  , (anEvent protocol isString
					   ifTrue: [ anEvent protocol ]
					   ifFalse: [ anEvent protocol name ]) ].
	anEvent isEpBehaviorChange ifTrue: [
		^ 'class:' , (anEvent behaviorAffectedName withoutSuffix: ' class') ].
	anEvent isEpPackageTagChange ifTrue: [
		^ 'tag:' , anEvent packageName , '/' , anEvent tagName ].
	anEvent isEpPackageChange ifTrue: [
		^ 'package:' , anEvent packageName ].
	^ nil
]

{ #category : 'pls - env changes' }
PLSServer >> envIgnoresBehavior: aBehavior [
	"Anonymous classes, such as those of tests and tools, are not part of the environment"

	^ aBehavior instanceSide isAnonymous
]

{ #category : 'pls - env' }
PLSServer >> envIsPackageNamed: aString modifiedIn: repositories [
	"Answer whether the Iceberg repository of the package holds changes of it not committed yet"

	^ (repositories at: aString ifAbsent: [ nil ])
		  ifNil: [ false ]
		  ifNotNil: [ :repository |
			  (repository workingCopy packageNamed: aString) isDirty ]
]

{ #category : 'pls - env' }
PLSServer >> envKindOf: id [
	"Answer the kind of the entity id, the part before its first colon"

	| kind |
	kind := id copyUpTo: $:.
	(#( 'project' 'package' 'tag' 'extensions' 'class' 'side' 'protocol'
	    'method' ) includes: kind) ifFalse: [
		PLSUnknownEntity signal: 'Unknown entity: ' , id printString ].
	^ kind
]

{ #category : 'pls - env' }
PLSServer >> envLoadProject: path baseline: baseline groups: groups [
	"Load the baseline from the git working copy at path, with Metacello and a gitlocal:// repository so that Iceberg works in that working copy, and answer the node of its project.
	 baseline is named with or without its BaselineOf prefix; groups, when given, are loaded instead of the default group.
	 A project already loaded from another repository is replaced by this working copy"

	<jrpc: #'pls-env:loadProject'>
	| name sources |
	name := baseline withoutPrefix: 'BaselineOf'.
	sources := self envSourceDirectoryOf: path asFileReference.
	(sources / ('BaselineOf' , name)) isDirectory ifFalse: [
			PLSProjectLoadFailed signal:
				'No BaselineOf' , name , ' in ' , sources fullName ].
	[
		| metacello |
		metacello := Metacello new
			             baseline: name;
			             repository: 'gitlocal://' , sources fullName;
			             onConflictUseIncoming;
			             onWarningLog;
			             yourself.
		groups isEmptyOrNil
			ifTrue: [ metacello load ]
			ifFalse: [ metacello load: groups asArray ] ]
		on: Error
		do: [ :error |
				PLSProjectLoadFailed signal:
					'Loading BaselineOf' , name , ' failed: '
					, error messageText asString ].
	^ self envNode: 'project:' , name
]

{ #category : 'pls - env history' }
PLSServer >> envLostChange: anEvent ref: ref time: aDateAndTime [
	"The sources are the ones of the entity before and after anEvent, nil when there is none, as for an addition or a removal.
	 Epicea gives class definitions with CR line endings: answer LF ones, as the other sources"

	| id sources |
	id := [ self envIdOfLostChange: anEvent ]
		      on: Error
		      do: [ nil ].
	sources := [ self envSourcesOfLostChange: anEvent ]
		           on: Error
		           do: [ #( nil nil ) ].
	sources := sources collect: [ :source |
		           source ifNotNil: [ source asString withUnixLineEndings ] ].
	^ {
		  (#ref -> ref).
		  (#kind -> (anEvent class name allButFirst: 2) uncapitalized).
		  (#label
		   ->
		   (id
			    ifNil: [ anEvent printString ]
			    ifNotNil: [ self envPathOf: id ])).
		  (#id -> id).
		  (#time -> (aDateAndTime ifNotNil: [ aDateAndTime asString ])).
		  (#oldSource -> sources first).
		  (#source -> sources second) } asDictionary
]

{ #category : 'pls - env history' }
PLSServer >> envLostChanges [
	"Answer the code changes of the last session of the image that it did not save, oldest first, but the ones replayed or dismissed since"

	<jrpc: #'pls-env:lostChanges'>
	^ { (#items -> (PLSLostChanges current pending collect: [ :each |
			    self
				    envLostChange: each value content
				    ref: each key
				    time: (each value tags at: EpLog timeKey ifAbsent: [ nil ]) ])
		   asArray) } asDictionary
]

{ #category : 'pls - env changes' }
PLSServer >> envMaxChanges [

	^ 1000
]

{ #category : 'pls - env changes' }
PLSServer >> envMaxDelay [
	"Milliseconds"

	^ 500
]

{ #category : 'pls - env changes' }
PLSServer >> envMethodAdded: anAnnouncement [

	| method |
	method := anAnnouncement method.
	(self envIgnoresBehavior: method methodClass) ifTrue: [ ^ self ].
	self envRecord: [
			(self envChange: 'added' id: (self envMethodIdOf: method))
				at: #parent
				put:
					(self
						 envProtocolIdIn: method methodClass
						 named: method protocolName);
				at: #version put: (self envVersionOfMethod: method);
				yourself ]
]

{ #category : 'pls - env changes' }
PLSServer >> envMethodChanged: anAnnouncement [

	| method |
	method := anAnnouncement method.
	(self envIgnoresBehavior: method methodClass) ifTrue: [ ^ self ].
	self envRecord: [
			(self envChange: 'changed' id: (self envMethodIdOf: method))
				at: #version put: (self envVersionOfMethod: method);
				yourself ]
]

{ #category : 'pls - env' }
PLSServer >> envMethodChildren: aString [

	self envMethodNamed: aString.
	^ #(  )
]

{ #category : 'pls - env changes' }
PLSServer >> envMethodIdOf: aMethod [

	^ 'method:' , (self envBehaviorPathOf: aMethod methodClass) , '>>'
	  , aMethod selector
]

{ #category : 'pls - env' }
PLSServer >> envMethodNamed: aString [
	"aString is 'Behavior>>selector'. Class names hold no '>', so the first '>>' ends the behavior even for a selector such as >>"

	| index |
	index := aString indexOfSubCollection: '>>'.
	index = 0 ifTrue: [
		PLSUnknownEntity signal: 'Unknown method: ' , aString printString ].
	^ (self envBehaviorNamed: (aString first: index - 1))
		  compiledMethodAt: (aString allButFirst: index + 1) asSymbol
		  ifAbsent: [
		  PLSUnknownEntity signal: 'Unknown method: ' , aString printString ]
]

{ #category : 'pls - env' }
PLSServer >> envMethodNode: aString [

	| method node |
	method := self envMethodNamed: aString.
	node := Dictionary new
		        at: #name put: method selector;
		        at: #parent
		        put:
			        'protocol:' , (self envBehaviorPathOf: method methodClass)
			        , '>>' , method protocolName;
		        at: #hasChildren put: false;
		        at: #flags put: {
				        (#abstract -> method isAbstract).
				        (#extension -> method isExtension).
				        (#override -> method isOverriding).
				        (#test -> method isTestMethod).
				        (#deprecated -> method isDeprecated).
				        (#fromTrait -> method isFromTrait) } asDictionary;
		        yourself.
	method isFromTrait ifTrue: [
		node at: #trait put: 'class:' , method origin instanceSide name ].
	^ node
]

{ #category : 'pls - env changes' }
PLSServer >> envMethodRecategorized: anAnnouncement [

	| method |
	method := anAnnouncement method.
	(self envIgnoresBehavior: method methodClass) ifTrue: [ ^ self ].
	self envRecord: [
			(self envChange: 'moved' id: (self envMethodIdOf: method))
				at: #parent
				put:
					(self
						 envProtocolIdIn: method methodClass
						 named: method protocolName);
				at: #oldParent put: (self
						 envProtocolIdIn: method methodClass
						 named: anAnnouncement oldProtocol name);
				yourself ]
]

{ #category : 'pls - env changes' }
PLSServer >> envMethodRemoved: anAnnouncement [

	| behavior |
	behavior := anAnnouncement methodClass.
	(self envIgnoresBehavior: behavior) ifTrue: [ ^ self ].
	self envRecord: [
			(self
				 envChange: 'removed'
				 id: 'method:' , (self envBehaviorPathOf: behavior) , '>>'
					 , anAnnouncement selector)
				at: #parent
				put: (anAnnouncement protocol ifNotNil: [ :protocol |
							 self envProtocolIdIn: behavior named: protocol name ]);
				yourself ]
]

{ #category : 'pls - env' }
PLSServer >> envNode: id [
	"Answer the node of the entity id: its id, kind, name, parent, flags and whether it has children"

	| kind |
	kind := self envKindOf: id.
	^ (self
		   perform: ('env' , kind capitalized , 'Node:') asSymbol
		   with: (self envPathOf: id))
		  at: #id put: id;
		  at: #kind put: kind;
		  yourself
]

{ #category : 'pls - env changes' }
PLSServer >> envPackageAdded: anAnnouncement [

	self envRecord: [
			(self
				 envChange: 'added'
				 id: 'package:' , anAnnouncement package name)
				at: #parent
				put:
					(self envProjectIdOfPackageNamed: anAnnouncement package name);
				yourself ]
]

{ #category : 'pls - env' }
PLSServer >> envPackageChildren: aString [
	"Answer the tags of the package, then the classes outside any tag, then its extensions if any"

	| package |
	package := self envPackageNamed: aString.
	^ ((package tags reject: [ :tag | tag isRoot ]) collect: [ :tag |
		   'tag:' , aString , '/' , tag name ]) asArray sort
	  , ((package tags detect: [ :tag | tag isRoot ] ifNone: [ nil ])
			   ifNil: [ #(  ) ]
			   ifNotNil: [ :root |
					   (root classes collect: [ :class | 'class:' , class name ])
						   asArray sort ]) , (package extensionMethods
		   ifEmpty: [ #(  ) ]
		   ifNotEmpty: [ { ('extensions:' , aString) } ])
]

{ #category : 'pls - env' }
PLSServer >> envPackageNameOf: id [
	"Answer the name of the package that holds the entity id, or nil for a project.
	 An extension protocol belongs to the package of its methods"

	| kind path |
	kind := self envKindOf: id.
	path := self envPathOf: id.
	kind = 'project' ifTrue: [ ^ nil ].
	kind = 'package' | (kind = 'extensions') ifTrue: [
		^ (self envPackageNamed: path) name ].
	kind = 'tag' ifTrue: [ ^ (self envTagNamed: path) package name ].
	kind = 'method' ifTrue: [ ^ (self envMethodNamed: path) package name ].
	kind = 'protocol' ifTrue: [
			| behaviorAndProtocol |
			behaviorAndProtocol := self envProtocolNamed: path.
			^ behaviorAndProtocol value methodSelectors
				  ifEmpty: [ behaviorAndProtocol key package name ]
				  ifNotEmpty: [ :selectors |
					  (behaviorAndProtocol key >> selectors anyOne) package name ] ].
	^ (self envBehaviorNamed: path) package name
]

{ #category : 'pls - env' }
PLSServer >> envPackageNamed: aString [

	^ self packageOrganizer
		  packageNamed: aString
		  ifAbsent: [
		  PLSUnknownEntity signal: 'Unknown package: ' , aString printString ]
]

{ #category : 'pls - env' }
PLSServer >> envPackageNamesOfBaseline: aBaseline [
	"Answer the names of the packages declared by aBaseline, its own package included, loaded or not.
	 Reading a spec is slow, so the answer is cached until #baseline: is recompiled"

	| specMethod entry |
	envProjectPackages ifNil: [ envProjectPackages := Dictionary new ].
	specMethod := aBaseline >> #baseline:.
	entry := envProjectPackages at: aBaseline name ifAbsent: [ nil ].
	(entry isNil or: [ entry key ~~ specMethod ]) ifTrue: [
			entry := specMethod
			         ->
				         (([ aBaseline project version packages collect: #name ]
					           on: Error
					           do: [ #(  ) ]) asSet
					          add: aBaseline package name;
					          yourself).
			envProjectPackages at: aBaseline name put: entry ].
	^ entry value
]

{ #category : 'pls - env' }
PLSServer >> envPackageNode: aString [

	| package |
	package := self envPackageNamed: aString.
	^ Dictionary new
		  at: #name put: package name;
		  at: #parent put: (self envProjectIdOfPackageNamed: package name);
		  at: #hasChildren put: (package definedClasses notEmpty or: [
					   package extensionMethods notEmpty ]);
		  at: #flags put: { (#test -> package isTestPackage) } asDictionary;
		  yourself
]

{ #category : 'pls - env changes' }
PLSServer >> envPackageRemoved: anAnnouncement [

	self envRecord: [
		self
			envChange: 'removed'
			id: 'package:' , anAnnouncement package name ]
]

{ #category : 'pls - env changes' }
PLSServer >> envPackageRenamed: anAnnouncement [

	self envRecord: [
			(self envChange: 'renamed' id: 'package:' , anAnnouncement newName)
				at: #oldId put: 'package:' , anAnnouncement oldName;
				yourself ]
]

{ #category : 'pls - env' }
PLSServer >> envPathOf: id [
	"Answer the path of the entity id, the part after its first colon"

	^ id allButFirst: (id indexOf: $:)
]

{ #category : 'pls - env' }
PLSServer >> envProjectChildren: aString [
	"Answer the loaded packages of the project. The volatile project holds those of no baseline"

	| names |
	names := aString = '*'
		         ifTrue: [
				         | declared |
				         declared := Set new.
				         self envBaselines do: [ :baseline |
					         declared addAll:
						         (self envPackageNamesOfBaseline: baseline) ].
				         (self packageOrganizer packages collect: #name) reject: [
					         :name | declared includes: name ] ]
		         ifFalse: [
				         (self envPackageNamesOfBaseline:
					          (self envBaselineNamed: aString)) select: [ :name |
					         self packageOrganizer hasPackage: name ] ].
	^ names asArray sort collect: [ :name | 'package:' , name ]
]

{ #category : 'pls - env' }
PLSServer >> envProjectIdOfPackageNamed: aString [
	"Answer the project of the package: the first baseline by name that declares it, or else the volatile project"

	^ 'project:' , ((self envBaselines
		    detect: [ :baseline |
			    (self envPackageNamesOfBaseline: baseline) includes: aString ]
		    ifNone: [ ^ 'project:*' ]) name withoutPrefix: 'BaselineOf')
]

{ #category : 'pls - env' }
PLSServer >> envProjectNode: aString [
	"aString is the name of a baseline without its BaselineOf prefix, or * for the volatile project"

	aString = '*' ifFalse: [ self envBaselineNamed: aString ].
	^ Dictionary new
		  at: #name put: (aString = '*'
				   ifTrue: [ 'Volatile' ]
				   ifFalse: [ aString ]);
		  at: #parent put: nil;
		  at: #hasChildren put: true;
		  at: #flags put: { (#volatile -> (aString = '*')) } asDictionary;
		  yourself
]

{ #category : 'pls - env' }
PLSServer >> envProjects [
	"Answer the nodes of the projects of the image: one per Metacello baseline, then the volatile project that gathers the packages of no baseline"

	<jrpc: #'pls-env:projects'>
	^ (self envBaselines collect: [ :baseline |
		   'project:' , (baseline name withoutPrefix: 'BaselineOf') ])
		  asArray , { 'project:*' } collect: [ :id | self envNode: id ]
]

{ #category : 'pls - env changes' }
PLSServer >> envProtocolAdded: anAnnouncement [

	| behavior |
	behavior := anAnnouncement classReorganized.
	(self envIgnoresBehavior: behavior) ifTrue: [ ^ self ].
	self envRecord: [
			(self
				 envChange: 'added'
				 id:
					 (self
						  envProtocolIdIn: behavior
						  named: anAnnouncement protocol name))
				at: #parent put: 'side:' , (self envBehaviorPathOf: behavior);
				yourself ]
]

{ #category : 'pls - env' }
PLSServer >> envProtocolChildren: aString [

	| behaviorAndProtocol path |
	behaviorAndProtocol := self envProtocolNamed: aString.
	path := self envBehaviorPathOf: behaviorAndProtocol key.
	^ (behaviorAndProtocol value methodSelectors collect: [ :selector |
		   'method:' , path , '>>' , selector ]) asArray sort
]

{ #category : 'pls - env changes' }
PLSServer >> envProtocolIdIn: aBehavior named: aString [

	^ 'protocol:' , (self envBehaviorPathOf: aBehavior) , '>>' , aString
]

{ #category : 'pls - env' }
PLSServer >> envProtocolNamed: aString [
	"aString is 'Behavior>>protocol'. Answer the behavior -> the protocol"

	| index behavior |
	index := aString indexOfSubCollection: '>>'.
	index = 0 ifTrue: [
		PLSUnknownEntity signal: 'Unknown protocol: ' , aString printString ].
	behavior := self envBehaviorNamed: (aString first: index - 1).
	^ behavior -> (behavior
		   protocolNamed: (aString allButFirst: index + 1)
		   ifAbsent: [
		   PLSUnknownEntity signal: 'Unknown protocol: ' , aString printString ])
]

{ #category : 'pls - env' }
PLSServer >> envProtocolNode: aString [

	| behaviorAndProtocol |
	behaviorAndProtocol := self envProtocolNamed: aString.
	^ Dictionary new
		  at: #name put: behaviorAndProtocol value name;
		  at: #parent
		  put: 'side:' , (self envBehaviorPathOf: behaviorAndProtocol key);
		  at: #hasChildren
		  put: behaviorAndProtocol value methodSelectors notEmpty;
		  at: #flags
		  put:
			  { (#extension -> behaviorAndProtocol value isExtensionProtocol) }
				  asDictionary;
		  yourself
]

{ #category : 'pls - env changes' }
PLSServer >> envProtocolRemoved: anAnnouncement [

	| behavior |
	behavior := anAnnouncement classReorganized.
	(self envIgnoresBehavior: behavior) ifTrue: [ ^ self ].
	self envRecord: [
			self
				envChange: 'removed'
				id:
				(self
					 envProtocolIdIn: behavior
					 named: anAnnouncement protocol name) ]
]

{ #category : 'pls - env changes' }
PLSServer >> envProtocolRenamed: anAnnouncement [

	| behavior |
	behavior := anAnnouncement classReorganized.
	(self envIgnoresBehavior: behavior) ifTrue: [ ^ self ].
	self envRecord: [
			(self
				 envChange: 'renamed'
				 id:
					 (self
						  envProtocolIdIn: behavior
						  named: anAnnouncement newProtocol name))
				at: #oldId
				put:
					(self
						 envProtocolIdIn: behavior
						 named: anAnnouncement oldProtocol name);
				yourself ]
]

{ #category : 'pls - env changes' }
PLSServer >> envQuietDelay [
	"Milliseconds"

	^ 100
]

{ #category : 'pls - env edition' }
PLSServer >> envRead: id [
	"Answer the source of the class or method id, with its version. The source of a class is its Tonel definition, comment included"

	<jrpc: #'pls-env:read'>
	| kind |
	kind := self envKindOf: id.
	kind = 'method' ifTrue: [
			| method |
			method := self envMethodNamed: (self envPathOf: id).
			^ {
				  (#id -> id).
				  (#source -> method sourceCode).
				  (#protocol -> method protocolName).
				  (#side
				   -> ('side:' , (self envBehaviorPathOf: method methodClass))).
				  (#version -> (self envVersionOfMethod: method)) } asDictionary ].
	kind = 'class' ifTrue: [
			| class |
			class := self envClassNamed: (self envPathOf: id).
			^ {
				  (#id -> id).
				  (#source -> (self envTonelDefinitionOf: class)).
				  (#version -> (self envVersionOfClass: class)) } asDictionary ].
	PLSUnknownEntity signal:
		'Only classes and methods can be read: ' , id printString
]

{ #category : 'pls - env changes' }
PLSServer >> envRecord: aBlock [
	"Add the change built by aBlock to the pending ones. A change replaces a pending change of the same kind on the same entity.
	 Past envMaxChanges pending changes, they are dropped and the client is told to reload everything.
	 aBlock runs in the process that changed the system, so its errors are ignored rather than break that change"

	| mutex change |
	mutex := envChangesMutex ifNil: [ ^ self ].
	envOverflow ifFalse: [
			change := [ aBlock value ]
				          on: Error
				          do: [ ^ self ] ].
	mutex critical: [
			| now |
			now := Time millisecondClockValue.
			envLastChangeTime := now.
			envFirstChangeTime ifNil: [
					envFirstChangeTime := now.
					envChangesReady signal ].
			(envOverflow or: [ change isNil ]) ifFalse: [
					| key |
					key := (change at: #kind) , ' ' , (change at: #id).
					envChanges removeKey: key ifAbsent: [ ].
					envChanges at: key put: change.
					envChanges size > self envMaxChanges ifTrue: [
							envOverflow := true.
							envChanges := OrderedDictionary new ] ] ]
]

{ #category : 'pls - env edition' }
PLSServer >> envRemove: id expectedVersion: expectedVersion [
	"Remove the class or method id from the image.
	 With expectedVersion, the removal is refused with a conflict if the entity is no longer at that version"

	<jrpc: #'pls-env:remove'>
	| kind |
	kind := self envKindOf: id.
	self envCheckVersionOf: id is: expectedVersion.
	kind = 'method' ifTrue: [
			| method |
			method := self envMethodNamed: (self envPathOf: id).
			method isFromTrait ifTrue: [
					PLSUnknownEntity signal:
						id printString , ' comes from the trait ' , method origin name
						, ', remove it there' ].
			method methodClass removeSelector: method selector.
			^ { (#removed -> id) } asDictionary ].
	kind = 'class' ifTrue: [
			(self envClassNamed: (self envPathOf: id)) removeFromSystem.
			^ { (#removed -> id) } asDictionary ].
	PLSUnknownEntity signal:
		'Only classes and methods can be removed: ' , id printString
]

{ #category : 'pls - env history' }
PLSServer >> envReplayLostChange: anEvent [
	"Epicea silently skips a change of a method or a protocol of a class the image no longer holds: signal it instead"

	(anEvent isEpMethodChange or: [ anEvent isEpProtocolChange ])
		ifTrue: [ self envBehaviorNamed: anEvent behaviorAffectedName ].
	anEvent applyCodeChange
]

{ #category : 'pls - env history' }
PLSServer >> envReplayLostChanges: refs [
	"Apply the lost changes refs to the image, in the order of the log. A change that fails stays pending"

	<jrpc: #'pls-env:replayLostChanges'>
	| lostChanges replayed failures |
	lostChanges := PLSLostChanges current.
	replayed := OrderedCollection new.
	failures := OrderedCollection new.
	(lostChanges pendingAmong: refs) do: [ :each |
			[
				self envReplayLostChange: each value content.
				lostChanges handle: each key.
				replayed add: each key ]
				on: Error
				do: [ :error |
						failures add: {
								(#ref -> each key).
								(#message -> error messageText asString) } asDictionary ] ].
	^ {
		  (#replayed -> replayed asArray).
		  (#failures -> failures asArray) } asDictionary
]

{ #category : 'pls - env' }
PLSServer >> envRepositoriesByPackageName [
	"Answer the Iceberg repository of each package that one holds, by package name"

	| repositories |
	repositories := Dictionary new.
	IceRepository registry do: [ :repository |
			repository workingCopy packages do: [ :package |
				repositories at: package name ifAbsentPut: [ repository ] ] ].
	^ repositories
]

{ #category : 'pls - env search' }
PLSServer >> envSearch: query kinds: kinds limit: limit [
	"Answer the projects, packages, classes and methods that match query, best matches first, at most limit of each kind (default 50).
	 kinds defaults to all four. query is a term, or a class and a term: `Array col`, `Array class new`, `Array>>col`.
	 A term matches a name that holds it, ignoring case; an exact name comes first, then a name that begins with it.
	 A class whose name is exactly the class of the query also offers the methods it inherits"

	<jrpc: #'pls-env:search'>
	| wanted max matches items complete |
	wanted := kinds ifNil: [ #( 'class' 'method' 'package' 'project' ) ].
	max := limit ifNil: [ 50 ].
	matches := self
		           envSearchMatchesOf: (query ifNil: [ '' ]) trimBoth
		           kinds: wanted.
	items := OrderedCollection new.
	complete := true.
	#( 'class' 'method' 'package' 'project' ) do: [ :kind |
			| found |
			found := (matches at: kind ifAbsent: [ #(  ) ]) sorted: [ :a :b |
				         self envSearchMatch: a precedes: b ].
			found size > max ifTrue: [ complete := false ].
			(found first: (found size min: max)) do: [ :match |
				items add: (self envSearchItemOf: match) ] ].
	^ {
		  (#items -> items asArray).
		  (#complete -> complete) } asDictionary
]

{ #category : 'pls - env search' }
PLSServer >> envSearchItemOf: aMatch [
	"Answer the node of the subject of aMatch, with its label and package. The label of a method names the side it was found on:
	 `Array>>collect:` for SequenceableCollection>>collect: found from Array"

	| subject id label |
	subject := aMatch third.
	subject isCompiledMethod
		ifTrue: [
				id := self envMethodIdOf: subject.
				label := (self envBehaviorPathOf: aMatch fourth) , '>>'
				         , subject selector ]
		ifFalse: [
				id := (subject isKindOf: Package)
					      ifTrue: [ 'package:' , subject name ]
					      ifFalse: [
							      (subject inheritsFrom: BaselineOf)
								      ifTrue: [ 'project:' , aMatch second ]
								      ifFalse: [ self envClassIdOf: subject ] ].
				label := aMatch second ].
	^ (self envNode: id)
		  at: #label put: label;
		  at: #package
		  put:
			  ((self envPackageNameOf: id) ifNotNil: [ :name |
					   'package:' , name ]);
		  yourself
]

{ #category : 'pls - env search' }
PLSServer >> envSearchMatch: a precedes: b [
	"Best score first, then shortest name, then by name"

	a first = b first ifFalse: [ ^ a first < b first ].
	a second size = b second size ifFalse: [
		^ a second size < b second size ].
	^ a second <= b second
]

{ #category : 'pls - env search' }
PLSServer >> envSearchMatchesOf: query kinds: kinds [
	"Answer the matches of query by kind. A match is {score. name to sort by. subject. receiver}:
	 a baseline, a package, a class, or a method and the side it is looked up from"

	| matches terms |
	matches := Dictionary new.
	kinds do: [ :kind | matches at: kind put: OrderedCollection new ].
	terms := self envSearchTermsOf: query.
	terms first ifNotNil: [ :classTerm |
			(kinds includes: 'method') ifTrue: [
					self
						envSearchMethodsOfClassesMatching: classTerm
						classSide: terms second
						selector: terms third
						into: (matches at: 'method') ].
			^ matches ].
	terms third ifEmpty: [ ^ matches ].
	matches at: 'project' ifPresent: [ :found |
			self envBaselines do: [ :baseline |
					| name |
					name := baseline name withoutPrefix: 'BaselineOf'.
					(self envSearchScoreOf: name for: terms third) ifNotNil: [ :score |
							found add: {
									score.
									name.
									baseline.
									nil } ] ] ].
	matches at: 'package' ifPresent: [ :found |
			self packageOrganizer packages do: [ :package |
					(self envSearchScoreOf: package name for: terms third) ifNotNil: [
							:score |
							found add: {
									score.
									package name.
									package.
									nil } ] ] ].
	matches at: 'class' ifPresent: [ :found |
			Smalltalk allClassesAndTraits do: [ :class |
					(self envSearchScoreOf: class name for: terms third) ifNotNil: [
							:score |
							found add: {
									score.
									class name.
									class.
									nil } ] ] ].
	matches at: 'method' ifPresent: [ :found |
			Smalltalk allClassesAndTraits do: [ :class |
					{
						class instanceSide.
						class classSide } do: [ :behavior |
							behavior selectorsAndMethodsDo: [ :selector :method |
									(self envSearchScoreOf: selector for: terms third) ifNotNil: [
											:score |
											found add: {
													score.
													selector.
													method.
													behavior } ] ] ] ] ].
	^ matches
]

{ #category : 'pls - env search' }
PLSServer >> envSearchMethodsOfClassesMatching: classTerm classSide: aBoolean selector: selectorTerm into: found [
	"Add the methods of the classes that match classTerm. A class named exactly classTerm also offers its inherited methods,
	 each after its own methods that match as well"

	Smalltalk allClassesAndTraits do: [ :class |
			(self envSearchScoreOf: class name for: classTerm) ifNotNil: [
					:classScore |
					| behavior |
					behavior := aBoolean
						            ifTrue: [ class classSide ]
						            ifFalse: [ class instanceSide ].
					classScore = 0
						ifTrue: [
								behavior allSelectors do: [ :selector |
										(self envSearchScoreOf: selector for: selectorTerm)
											ifNotNil: [ :score |
													| method |
													method := behavior lookupSelector: selector.
													found add: {
															(method methodClass == behavior
																 ifTrue: [ score * 2 ]
																 ifFalse: [ score * 2 + 1 ]).
															selector.
															method.
															behavior } ] ] ]
						ifFalse: [
								behavior selectorsAndMethodsDo: [ :selector :method |
										(self envSearchScoreOf: selector for: selectorTerm)
											ifNotNil: [ :score |
													found add: {
															(classScore * 6 + (score * 2)).
															selector.
															method.
															behavior } ] ] ] ] ]
]

{ #category : 'pls - env search' }
PLSServer >> envSearchScoreOf: aString for: aTerm [
	"Answer 0 when aString is aTerm, 1 when it begins with aTerm, 2 when it holds aTerm, ignoring case, or else nil"

	aTerm ifEmpty: [ ^ 1 ].
	(aString includesSubstring: aTerm caseSensitive: false) ifFalse: [
		^ nil ].
	(aString beginsWith: aTerm caseSensitive: false) ifFalse: [ ^ 2 ].
	^ aString size = aTerm size
		  ifTrue: [ 0 ]
		  ifFalse: [ 1 ]
]

{ #category : 'pls - env search' }
PLSServer >> envSearchTermsOf: query [
	"Answer {class term or nil. class side. selector term} of query: `col`, `Array col`, `Array class new`, `Array>>col` or `Array class>>#new`"

	| classPart selectorPart tokens |
	(query includesSubstring: '>>')
		ifTrue: [
				| index |
				index := query indexOfSubCollection: '>>'.
				classPart := (query first: index - 1) substrings.
				selectorPart := (query allButFirst: index + 1) trimBoth ]
		ifFalse: [
				tokens := query substrings.
				tokens size <= 1 ifTrue: [
						^ {
							  nil.
							  false.
							  ((tokens ifEmpty: [ '' ] ifNotEmpty: [ tokens first ])
								   withoutPrefix: '#') } ].
				classPart := (tokens size > 2 or: [ tokens second ~= 'class' ])
					             ifTrue: [
							             tokens first: (tokens second = 'class'
									              ifTrue: [ 2 ]
									              ifFalse: [ 1 ]) ]
					             ifFalse: [ tokens ].
				selectorPart := ''.
				(tokens allButFirst: classPart size) do: [ :token |
					selectorPart := selectorPart , token ] ].
	classPart ifEmpty: [
			^ {
				  nil.
				  false.
				  (selectorPart withoutPrefix: '#') } ].
	^ {
		  classPart first.
		  (classPart size > 1 and: [ classPart second = 'class' ]).
		  (selectorPart withoutPrefix: '#') }
]

{ #category : 'pls - env' }
PLSServer >> envSideChildren: aString [

	^ ((self envBehaviorNamed: aString) protocols collect: [ :protocol |
		   'protocol:' , aString , '>>' , protocol name ]) asArray sort
]

{ #category : 'pls - env' }
PLSServer >> envSideDetailsOf: aBehavior in: entity [
	"Complete the entity of a side with its own slots, the class variables of its class (instance side only),
	 the ids of the traits its class uses, and its selectors that a subclass redefines"

	| subclassSelectors |
	entity at: #slots put: (aBehavior localSlots
			 collect: [ :slot | slot name asString ]
			 as: Array).
	entity at: #classVariables put: (aBehavior isClassSide
			 ifTrue: [ #(  ) ]
			 ifFalse: [
					 (aBehavior classVariables
						  collect: [ :variable | variable name asString ]
						  as: Array) sort ]).
	entity
		at: #traits
		put: (aBehavior instanceSide traitComposition allTraits
				 collect: [ :trait | 'class:' , trait name ]
				 as: Array).
	subclassSelectors := Set new.
	aBehavior allSubclassesDo: [ :subclass |
		subclassSelectors addAll: subclass localSelectors ].
	entity at: #overridden put: (aBehavior selectors
			 select: [ :selector | subclassSelectors includes: selector ]
			 thenCollect: [ :selector | selector asString ]) asArray sort.
	^ entity
]

{ #category : 'pls - env' }
PLSServer >> envSideNode: aString [

	| behavior |
	behavior := self envBehaviorNamed: aString.
	^ Dictionary new
		  at: #name put: (behavior isClassSide
				   ifTrue: [ 'class side' ]
				   ifFalse: [ 'instance side' ]);
		  at: #parent put: 'class:' , behavior instanceSide name;
		  at: #hasChildren put: behavior protocols notEmpty;
		  at: #flags put: Dictionary new;
		  yourself
]

{ #category : 'pls - env' }
PLSServer >> envSourceDirectoryOf: aDirectory [
	"Answer the directory of the sources of the working copy aDirectory: the srcDirectory of its .project file, as Iceberg reads it, else the working copy itself"

	| project sources |
	aDirectory isDirectory ifFalse: [
		PLSProjectLoadFailed signal: 'Not a folder: ' , aDirectory fullName ].
	project := aDirectory / '.project'.
	project exists ifFalse: [ ^ aDirectory ].
	sources := [
		           (STON fromString: project contents)
			           at: 'srcDirectory'
			           ifAbsent: [ '' ] ]
		           on: Error
		           do: [ '' ].
	^ sources isEmptyOrNil
		  ifTrue: [ aDirectory ]
		  ifFalse: [ aDirectory / sources ]
]

{ #category : 'pls - env history' }
PLSServer >> envSourcesOfLostChange: anEvent [
	"Answer the source of the entity anEvent changes, before and after it"

	| name |
	name := anEvent class name.
	name = #EpMethodAddition ifTrue: [
			^ {
				  nil.
				  anEvent sourceCode } ].
	name = #EpMethodModification ifTrue: [
			^ {
				  anEvent oldSourceCode.
				  anEvent newSourceCode } ].
	name = #EpMethodRemoval ifTrue: [
			^ {
				  anEvent sourceCode.
				  nil } ].
	name = #EpClassAddition ifTrue: [
			^ {
				  nil.
				  anEvent classAdded definitionSource } ].
	name = #EpClassModification ifTrue: [
			^ {
				  anEvent oldClass definitionSource.
				  anEvent newClass definitionSource } ].
	name = #EpClassRemoval ifTrue: [
			^ {
				  anEvent classRemoved definitionSource.
				  nil } ].
	name = #EpTraitAddition ifTrue: [
			^ {
				  nil.
				  anEvent traitAdded definitionSource } ].
	name = #EpTraitModification ifTrue: [
			^ {
				  anEvent oldTrait definitionSource.
				  anEvent newTrait definitionSource } ].
	name = #EpTraitRemoval ifTrue: [
			^ {
				  anEvent traitRemoved definitionSource.
				  nil } ].
	name = #EpBehaviorCommentChange ifTrue: [
			^ {
				  anEvent oldComment.
				  anEvent newComment } ].
	^ { nil. nil }
]

{ #category : 'pls - env changes' }
PLSServer >> envSubscribe [
	"Listen to the changes of the system, and send them to the client in pls-env/didChange notifications.
	 The changes are recorded in the process that made them, so recording one never signals an error into it"

	self envUnsubscribe.
	envChanges := OrderedDictionary new.
	envChangesMutex := Mutex new.
	envChangesReady := Semaphore new.
	envOverflow := false.
	envFirstChangeTime := nil.
	self envAnnouncementSelectors keysAndValuesDo: [
			:announcement
			:selector |
			SystemAnnouncer uniqueInstance
				when: announcement
				do: [ :each |
						[ self perform: selector with: each ]
							on: Error
							do: [ :error | error return: nil ] ]
				for: self ].
	envFlushProcess := [ self envFlushLoop ]
		                   forkAt: Processor userBackgroundPriority
		                   named: 'PLS environment changes'
]

{ #category : 'pls - env search' }
PLSServer >> envSymbolOf: anItem [
	"Answer the LSP SymbolInformation of an item of pls-env:search. It names a method as its label, `Array>>collect:`,
	 and in its container the class that defines it when the method is inherited"

	| packageName path container |
	packageName := (anItem at: #package) withoutPrefix: 'package:'.
	path := self envPathOf: (anItem at: #id).
	container := packageName.
	(anItem at: #kind) = 'method' ifTrue: [
			| definer |
			definer := path first: (path indexOfSubCollection: '>>') - 1.
			((anItem at: #label) beginsWith: definer , '>>') ifFalse: [
				container := definer , ' (' , packageName , ')' ] ].
	^ {
		  (#name -> (anItem at: #label)).
		  (#kind -> ((anItem at: #kind) = 'method'
			    ifTrue: [ 6 ]
			    ifFalse: [ 5 ])).
		  (#containerName -> container).
		  (#location -> {
			   (#uri
			    -> (self envUriOf: (anItem at: #id) inPackage: packageName)).
			   (#range -> {
				    (#start -> {
					     (#line -> 0).
					     (#character -> 0) } asDictionary).
				    (#end -> {
					     (#line -> 0).
					     (#character -> 0) } asDictionary) } asDictionary) }
			   asDictionary) } asDictionary
]

{ #category : 'pls - env changes' }
PLSServer >> envTagAdded: anAnnouncement [

	anAnnouncement tag isRoot ifTrue: [ ^ self ].
	self envRecord: [
			(self
				 envChange: 'added'
				 id:
					 'tag:' , anAnnouncement package name , '/'
					 , anAnnouncement tag name)
				at: #parent put: 'package:' , anAnnouncement package name;
				yourself ]
]

{ #category : 'pls - env' }
PLSServer >> envTagChildren: aString [

	^ ((self envTagNamed: aString) classes collect: [ :class |
		   'class:' , class name ]) asArray sort
]

{ #category : 'pls - env' }
PLSServer >> envTagNamed: aString [
	"aString is 'Package/Tag'"

	| package |
	package := self envPackageNamed: (aString copyUpTo: $/).
	^ package tags
		  detect: [ :tag |
		  tag isRoot not and: [ tag name = (aString copyAfter: $/) ] ]
		  ifNone: [ PLSUnknownEntity signal: 'Unknown tag: ' , aString printString ]
]

{ #category : 'pls - env' }
PLSServer >> envTagNode: aString [

	| tag |
	tag := self envTagNamed: aString.
	^ Dictionary new
		  at: #name put: tag name;
		  at: #parent put: 'package:' , tag package name;
		  at: #hasChildren put: tag classes notEmpty;
		  at: #flags put: Dictionary new;
		  yourself
]

{ #category : 'pls - env changes' }
PLSServer >> envTagRemoved: anAnnouncement [

	anAnnouncement tag isRoot ifTrue: [ ^ self ].
	self envRecord: [
			self
				envChange: 'removed'
				id:
				'tag:' , anAnnouncement package name , '/'
				, anAnnouncement tag name ]
]

{ #category : 'pls - env changes' }
PLSServer >> envTagRenamed: anAnnouncement [

	self envRecord: [
			(self
				 envChange: 'renamed'
				 id:
					 'tag:' , anAnnouncement package name , '/'
					 , anAnnouncement newName)
				at: #oldId
				put:
					'tag:' , anAnnouncement package name , '/'
					, anAnnouncement oldName;
				yourself ]
]

{ #category : 'pls - env edition' }
PLSServer >> envTonelDefinitionOf: aClass [

	^ String streamContents: [ :stream |
			  TonelWriter new
				  writeClassDefinition: aClass asClassDefinition
				  on: stream ]
]

{ #category : 'pls - env changes' }
PLSServer >> envUnsubscribe [

	SystemAnnouncer uniqueInstance unsubscribe: self.
	envFlushProcess ifNotNil: [ :flushProcess | flushProcess terminate ].
	envFlushProcess := nil.
	envChangesMutex := nil
]

{ #category : 'pls - env search' }
PLSServer >> envUriOf: id inPackage: packageName [
	"Answer the URI of the editor of a class or method of the extension:
	 pharo:/<image>/<package>/<class>.class.st or pharo:/<image>/<package>/<class>/<instance|class>/<selector>.st.
	 A selector escapes % and / first, since they cannot stay in a path segment; see docs/environment-model.md"

	| path segments encoder |
	path := self envPathOf: id.
	segments := OrderedCollection
		            with: Smalltalk imageFile basenameWithoutExtension
		            with: packageName.
	(self envKindOf: id) = 'class'
		ifTrue: [ segments add: path , '.class.st' ]
		ifFalse: [
				| side selector |
				side := path first: (path indexOfSubCollection: '>>') - 1.
				selector := path allButFirst: side size + 2.
				segments
					add: (side withoutSuffix: ' class');
					add: ((side endsWith: ' class')
							 ifTrue: [ 'class' ]
							 ifFalse: [ 'instance' ]);
					add: ((selector copyReplaceAll: '%' with: '%25')
							 copyReplaceAll: '/'
							 with: '%2F') , '.st' ].
	encoder := ZnPercentEncoder new.
	^ String streamContents: [ :stream |
			  stream nextPutAll: 'pharo:'.
			  segments do: [ :segment |
					  stream
						  nextPut: $/;
						  nextPutAll: (encoder encode: segment) ] ]
]

{ #category : 'pls - env edition' }
PLSServer >> envVersionOf: id [
	"Answer the version of the class or method id, or nil for another kind of entity"

	| kind |
	kind := self envKindOf: id.
	kind = 'method' ifTrue: [
		^ self envVersionOfMethod:
			  (self envMethodNamed: (self envPathOf: id)) ].
	kind = 'class' ifTrue: [
		^ self envVersionOfClass: (self envClassNamed: (self envPathOf: id)) ].
	^ nil
]

{ #category : 'pls - env changes' }
PLSServer >> envVersionOfClass: aClass [
	"Answer a hash of the definition and comment of the class, which changes whenever they do"

	| class |
	class := aClass instanceSide.
	^ (SHA1 hashMessage:
		   class definitionString , class classSide definitionString
		   , class comment asString) hex
]

{ #category : 'pls - env changes' }
PLSServer >> envVersionOfMethod: aMethod [
	"Answer a hash of the source of the method, which changes whenever it does"

	^ (SHA1 hashMessage: aMethod sourceCode) hex
]

{ #category : 'pls - env history' }
PLSServer >> envVersionWithSource: source protocol: protocol stamp: stamp [
	"stamp is when the version was compiled, nil when unknown"

	^ {
		  (#source -> source asString).
		  (#protocol -> protocol asString).
		  (#stamp -> (stamp isEmptyOrNil
			    ifTrue: [ nil ]
			    ifFalse: [ stamp asString ])) } asDictionary
]

{ #category : 'lsp - workspace' }
PLSServer >> executeCommand: command arguments: arguments workDoneToken: workDoneToken [
	"Execute a command that the server declares in its capabilities"

	<jrpc: #'workspace/executeCommand'>
	command = self class critiquesBanCommand ifTrue: [
		^ self critiquesBan: arguments ].
	^ nil
]

{ #category : 'lsp - formatting' }
PLSServer >> formatTextDocument: textDocument withOptions: options [

	<jrpc: #'textDocument/formatting'>
	| document codeSource lines endPosition |
	document := self context textItem: (textDocument at: #uri).
	codeSource := document text.
	lines := codeSource lines.
	endPosition := PLSPosition new
		               line: lines size;
		               character: lines last size;
		               yourself.
	^ { (PLSTextEdit new
		   newText: document formattedText;
		   range: (PLSRange new
				    start: (PLSPosition new
						     line: 0;
						     character: 0;
						     yourself);
				    end: endPosition;
				    yourself)) }
]

{ #category : 'pls - ice' }
PLSServer >> iceAddPackageToRepository: aRepositoryName packageName: packageName [

	<jrpc: #'pls-ice:addPackage'>
	| normalizedPackage repository workingCopy |
	normalizedPackage := packageName ifNil: [ '' ].
	normalizedPackage := normalizedPackage trimBoth.
	normalizedPackage ifEmpty: [ self error: 'Package name cannot be empty.' ].

	repository := self iceRepositoryNamed: aRepositoryName.
	self plsCreatePackage: normalizedPackage.
	workingCopy := repository workingCopy.
	(workingCopy includesPackageNamed: normalizedPackage) ifTrue: [
		^ 'Package ' , normalizedPackage , ' is already managed by ' , repository name ].

	workingCopy addPackageNamed: normalizedPackage.
	^ 'Package ' , normalizedPackage , ' added to ' , repository name
]

{ #category : 'pls - ice' }
PLSServer >> iceClassDefinitionNamed: className inPackageVersion: packageVersion [

	| definitions |
	packageVersion ifNil: [ ^ nil ].
	definitions := self iceDefinitionsInPackageVersion: packageVersion.
	^ definitions
		  detect: [ :definition | 
			  self
				  iceDefinition: definition
				  matchesClassName: className ]
		  ifNone: [ nil ]
]

{ #category : 'pls - ice' }
PLSServer >> iceDefinition: definition matchesClassName: className [

	| definitionName |
	definition ifNil: [ ^ false ].
	(definition respondsTo: #isClassDefinition) ifTrue: [ 
		(definition isClassDefinition not) ifTrue: [ ^ false ] ].
	(definition respondsTo: #name) ifFalse: [ ^ false ].
	definitionName := [ definition name asString ] on: Error do: [ nil ].
	^ definitionName = className
]

{ #category : 'pls - ice' }
PLSServer >> iceDefinitionsInPackageVersion: packageVersion [

	| snapshot |
	(packageVersion respondsTo: #definitions) ifTrue: [ 
		^ [ packageVersion definitions ] on: Error do: [ #() ] ].
	(packageVersion respondsTo: #snapshot) ifTrue: [ 
		snapshot := [ packageVersion snapshot ] on: Error do: [ nil ].
		snapshot ifNotNil: [ 
			(snapshot respondsTo: #definitions) ifTrue: [ 
				^ [ snapshot definitions ] on: Error do: [ #() ] ] ] ].
	^ #()
]

{ #category : 'pls - ice' }
PLSServer >> iceDiffLeavesOf: aDiff [

	| tree |
	tree := (aDiff respondsTo: #tree)
		        ifTrue: [ aDiff tree ]
		        ifFalse: [ ^ #() ].
	^ tree allChildren select: [ :node | node children isEmpty ]
]

{ #category : 'pls - ice' }
PLSServer >> iceOriginalContent: uri [

	"Return the original (reference commit) content for a pharoImage URI."
	<jrpc: #'pls-ice:originalContent'>
	| baseUri uriSegments packageName classFileName className repository source |
	baseUri := uri copyUpTo: $?.
	uriSegments := baseUri substrings: '/'.
	uriSegments size < 3 ifTrue: [ ^ '' ].
	packageName := uriSegments at: uriSegments size - 1.
	classFileName := uriSegments last.
	className := classFileName withoutSuffix: '.class.st'.
	repository := self iceRepositoryContainingClassUri: baseUri.
	source := repository
		          ifNil: [ nil ]
		          ifNotNil: [ 
			          self
				          iceOriginalContentFromRepository: repository
				          packageName: packageName
				          className: className ].
	^ source
]

{ #category : 'pls - ice' }
PLSServer >> iceOriginalContentFromRepository: repository packageName: packageName className: className [

	| workingCopy packageVersion source snapshot writer referenceCommit |
	workingCopy := repository workingCopy.
	referenceCommit := [ workingCopy referenceCommit ]
		                   on: Error
		                   do: [ nil ].
	referenceCommit ifNil: [ ^ '' ].
	packageVersion := self
		                  icePackageVersionIn: referenceCommit
		                  forPackageNamed: packageName
		                  className: className.
	snapshot := packageVersion mcSnapshot.
	writer := TonelWriter new snapshot: snapshot.
	source := String streamContents: [ :aStream |
		          writer
			          writeClass:
			          (snapshot
				           classDefinitionNamed: className
				           ifAbsent: [ '' ])
			          on: aStream ].
	^ source
]

{ #category : 'pls - ice' }
PLSServer >> iceOriginalResource: uri [
	"Return a virtual pharoImage URI for the reference version; never use the local filesystem."

	<jrpc: #'pls-ice:originalResource'>
	^ (uri copyUpTo: $?) , '?iceOriginal=1'
]

{ #category : 'pls - ice' }
PLSServer >> icePackageVersionIn: workingCopy forPackageNamed: packageName className: className [

	^ workingCopy versionFor: packageName asPackage
]

{ #category : 'pls - ice' }
PLSServer >> iceRepositories [

	<jrpc: #'pls-ice:repositories'>
	^ (IceRepository registry collect: [ :repository | 
		   { 
			   (#name -> repository name).
			   (#valid -> repository isValid) } asDictionary ]) asArray
]

{ #category : 'pls - ice' }
PLSServer >> iceRepository: aRepositoryName [

	<jrpc: #'pls-ice:repository'>
	| repoOfInterest set |
	repoOfInterest := IceRepository registry detect: [ :repository | 
		                  repository name = aRepositoryName ].
	set := (repoOfInterest workingCopy diffToReferenceCommit tree
		        allChildren
		        select: [ :a | a children isEmpty ]
		        thenCollect: [ :a | a definition actualClass ]) asSet.
	^ (set collect: #plsURIString) asArray
]

{ #category : 'pls - ice' }
PLSServer >> iceRepositoryChangesFor: aRepositoryName [

	| repository diff leaves changes seenUris |
	repository := self iceRepositoryNamed: aRepositoryName.
	diff := repository workingCopy diffToReferenceCommit.
	leaves := self iceDiffLeavesOf: diff.
	changes := OrderedCollection new.
	seenUris := Set new.
	leaves do: [ :leaf | 
		| definition targetClass status uri |
		definition := leaf definition.
		(definition respondsTo: #actualClass) ifTrue: [ 
			targetClass := definition actualClass.
			targetClass ifNotNil: [ 
				uri := targetClass plsURIString.
				(seenUris includes: uri) ifFalse: [ 
					seenUris add: uri.
					status := self iceStatusForDiffLeaf: leaf.
					changes add: { 
							#uri -> uri.
							#status -> status } asDictionary ] ] ] ].
	^ changes asArray
]

{ #category : 'pls - ice' }
PLSServer >> iceRepositoryCommit: aRepositoryName message: message [

	<jrpc: #'pls-ice:commit'>
	| repository workingCopy diff |
	repository := self iceRepositoryNamed: aRepositoryName.
	workingCopy := repository workingCopy.
	diff := workingCopy diffToReferenceCommit.
	(self iceDiffLeavesOf: diff) ifEmpty: [
		^ 'Nothing to commit in ' , repository name ].

	workingCopy commitChanges: diff withMessage: message force: false.
	^ 'Committed ' , repository name
]

{ #category : 'pls - ice' }
PLSServer >> iceRepositoryContainingClassUri: classUri [

	^ IceRepository registry
		  detect: [ :repository |
				  [
					  repository isValid and: [
							  (self iceRepositoryChangesFor: repository name) anySatisfy: [
								  :change | (change at: #uri) = classUri ] ] ]
					  on: Error
					  do: [ false ] ]
		  ifNone: [ nil ]
]

{ #category : 'pls - ice' }
PLSServer >> iceRepositoryNamed: aRepositoryName [

	^ IceRepository registry
		  detect: [ :repository | repository name = aRepositoryName ]
		  ifNone: [
		  self error: 'Iceberg repository not found: ' , aRepositoryName ]
]

{ #category : 'pls - ice' }
PLSServer >> iceRepositoryPackages: aRepositoryName [

	<jrpc: #'pls-ice:repositoryPackages'>
	| repository workingCopy |
	repository := self iceRepositoryNamed: aRepositoryName.
	workingCopy := repository workingCopy.
	^ (workingCopy packages collect: [:iceP | iceP package ]) asArray
]

{ #category : 'pls - ice' }
PLSServer >> iceRepositoryPush: aRepositoryName [

	<jrpc: #'pls-ice:push'>
	| repository |
	repository := self iceRepositoryNamed: aRepositoryName.
	(repository respondsTo: #push) ifTrue: [
		repository push.
		^ 'Pushed ' , repository name ].

	^ self error: 'Iceberg push API not available in this image.'
]

{ #category : 'pls - ice' }
PLSServer >> iceRepositoryStatus: aRepositoryName [

	<jrpc: #'pls-ice:repositoryStatus'>
	^ {
		  (#stagedChanges -> #(  ) asArray).
		  (#changes -> (self iceRepositoryChangesFor: aRepositoryName)) }
		  asDictionary
]

{ #category : 'pls - ice' }
PLSServer >> iceSourceFromDefinition: definition [

	| source |
	definition ifNil: [ ^ nil ].
	#(contents sourceString sourceCode source tonelString)
		do: [ :selector | 
			(definition respondsTo: selector) ifTrue: [ 
				source := [ definition perform: selector ]
					          on: Error
					          do: [ nil ].
				source ifNotNil: [ 
					source isString ifTrue: [ ^ source ].
					(source respondsTo: #utf8Decoded) ifTrue: [ ^ source utf8Decoded ].
					(source respondsTo: #asString) ifTrue: [ ^ source asString ] ] ] ].
	(definition respondsTo: #actualClass) ifTrue: [ 
		| currentClass |
		currentClass := definition actualClass.
		currentClass ifNotNil: [ ^ self iceSourceFromImageClassNamed: currentClass name ] ].
	^ nil
]

{ #category : 'pls - ice' }
PLSServer >> iceSourceFromImageClassNamed: className [

	| targetClass |
	targetClass := self class environment
		               at: className asSymbol
		               ifAbsent: [ ^ '' ].
	^ String streamContents: [ :stream |
		  TonelWriter exportClass: targetClass on: stream ]
]

{ #category : 'pls - ice' }
PLSServer >> iceStatusForDiffLeaf: aDiffLeaf [

	| className |
	(aDiffLeaf respondsTo: #isAddition) ifTrue: [
		aDiffLeaf isAddition ifTrue: [ ^ 'added' ] ].
	(aDiffLeaf respondsTo: #isRemoval) ifTrue: [
		aDiffLeaf isRemoval ifTrue: [ ^ 'deleted' ] ].
	(aDiffLeaf respondsTo: #isConflict) ifTrue: [
		aDiffLeaf isConflict ifTrue: [ ^ 'conflicted' ] ].
	className := aDiffLeaf class name asString asLowercase.
	(className includesSubstring: 'add') ifTrue: [ ^ 'added' ].
	((className includesSubstring: 'remove') or: [
		 className includesSubstring: 'delete' ]) ifTrue: [ ^ 'deleted' ].
	(className includesSubstring: 'conflict') ifTrue: [ ^ 'conflicted' ].
	^ 'modified'
]

{ #category : 'pls - playground' }
PLSServer >> inspectIt: line textDocument: textDocumentURI [
	"Evaluate line in a playground page and bind its result to the variable it of the page, so that the client shows it in the variables of the page"

	<jrpc: #'pls:inspectIt'>
	| document result |
	document := self context textItem: (textDocumentURI at: #path).
	result := (self compilerFor: (textDocumentURI at: #path)) evaluate:
		          line.
	(document binder bindingOf: #it) value: result.
	^ result plsPrintString
]

{ #category : 'pls - inspector' }
PLSServer >> inspectorCellOf: column for: row at: index [
	"Answer the text of the cell of row, the index-th row of its table, in column"

	^ [
		  (column isKindOf: SpIndexTableColumn)
			  ifTrue: [ index printString ]
			  ifFalse: [
					  (column isKindOf: SpCompositeTableColumn)
						  ifTrue: [
								  ' ' join:
									  ((column columns reject: [ :each |
										    each isKindOf: SpImageTableColumn ]) collect: [ :each |
										   self inspectorCellOf: each for: row at: index ]) ]
						  ifFalse: [ self inspectorStringOf: (column readObject: row) ] ] ]
		  on: Error
		  do: [ :error | error messageText asString ]
]

{ #category : 'pls - inspector' }
PLSServer >> inspectorChildren: ref offset: offset limit: limit [
	"Answer one page of the slots and indexed items of the object of the reference ref, with the total number of them"

	<jrpc: #'pls-inspector:children'>
	^ (self
		   inspectorTreeOf:
			   (self inspectorRawChildrenOf: (self inspectorObjectOf: ref))
		   offset: offset
		   limit: limit)
		  removeKey: #kind;
		  yourself
]

{ #category : 'pls - inspector' }
PLSServer >> inspectorContextsOf: anObject [
	"Answer the inspection contexts of anObject, one per inspection method of its class, in the order of the inspector"

	^ [ (StInspectionCollector on: anObject) collectInspectionContexts ]
		  on: Error
		  do: [ #(  ) ]
]

{ #category : 'pls - inspector' }
PLSServer >> inspectorDescriptionOf: anObject ref: ref [
	"Answer the description of anObject, known by the reference ref: its class, its print string and the views the client can show of it"

	^ {
		  (#ref -> ref).
		  (#className -> anObject class name asString).
		  (#printString -> (self inspectorPrintStringOf: anObject)).
		  (#hasChildren -> (self inspectorHasChildren: anObject)).
		  (#views -> (self inspectorViewsOf: anObject)) } asDictionary
]

{ #category : 'pls - inspector' }
PLSServer >> inspectorEvaluate: expression textDocumentURI: textDocumentURI receiver: receiver [
	"Evaluate expression with self bound to the object of the reference receiver when given, else with the bindings of the document, and answer the description of its result.
	 An error the evaluation signals is its result, and the description carries its message"

	<jrpc: #'pls-inspector:evaluate'>
	| compiler error result |
	(self inspectorSyntaxErrorOf: expression) ifNotNil: [ :message |
		^ JRPCInvalidParameters signal: message ].
	compiler := receiver
		            ifNil: [
			            self compilerFor:
				            (textDocumentURI ifNotNil: [ :uri | uri at: #path ]) ]
		            ifNotNil: [
				            SmalltalkImage current compiler
					            receiver: (self inspectorObjectOf: receiver);
					            yourself ].
	result := [ compiler evaluate: expression ]
		          on: Error
		          do: [ :exception |
				          error := exception.
				          exception return: exception ].
	^ (self
		   inspectorDescriptionOf: result
		   ref: (self inspectorRegister: result))
		  at: #error put: (error ifNotNil: [ error description asString ]);
		  yourself
]

{ #category : 'pls - inspector' }
PLSServer >> inspectorExtensionView: viewId of: anObject offset: offset limit: limit [
	"Answer the view viewId that an inspection method of the class of anObject builds"

	| context presenter |
	context := (self inspectorContextsOf: anObject)
		           detect: [ :each | each methodSelector asString = viewId ]
		           ifNone: [
				           PLSUnknownEntity signal:
					           'Unknown inspector view: ' , viewId printString ].
	presenter := [
		             context basicNewInspectionPresenter:
			             (context newPresenterBuilderOnApplication:
				              SpApplication new) ]
		             on: Error , Warning
		             do: [ :error |
				             ^ self inspectorUnsupported:
					               'This view failed: ' , error messageText asString ].
	^ [
	  self
		  inspectorViewOfPresenter: presenter
		  offset: offset
		  limit: limit ]
		  on: Error
		  do: [ :error |
				  self inspectorUnsupported:
					  'This view failed: ' , error messageText asString ]
]

{ #category : 'pls - inspector' }
PLSServer >> inspectorHasChildren: anObject [
	"Answer whether anObject has slots or indexed items to show in its Raw view"

	^ [
		  anObject class instSize > 0 or: [
			  anObject class isVariable and: [ anObject basicSize > 0 ] ] ]
		  on: Error
		  do: [ false ]
]

{ #category : 'pls - inspector' }
PLSServer >> inspectorInspect: ref [
	"Answer the description of the object of the reference ref"

	<jrpc: #'pls-inspector:inspect'>
	^ self inspectorDescriptionOf: (self inspectorObjectOf: ref) ref: ref
]

{ #category : 'pls - inspector' }
PLSServer >> inspectorItemNamed: name of: anObject [
	"Answer the item that shows anObject under name, with a new reference to it"

	^ {
		  (#name -> name).
		  (#ref -> (self inspectorRegister: anObject)).
		  (#className -> anObject class name asString).
		  (#printString -> (self inspectorPrintStringOf: anObject)).
		  (#hasChildren -> (self inspectorHasChildren: anObject)) }
		  asDictionary
]

{ #category : 'pls - inspector' }
PLSServer >> inspectorMetaOf: anObject offset: offset limit: limit [
	"Answer the class of anObject and its superclasses up to the root of the hierarchy, as a table view"

	^ self
		  inspectorTableOf: anObject class withAllSuperclasses asArray
		  columns: #( 'Class' 'Package' )
		  cells: [ :class :index |
				  {
					  class name asString.
					  (class package
						   ifNil: [ '' ]
						   ifNotNil: [ :package | package name asString ]) } ]
		  objects: [ :class | class ]
		  offset: offset
		  limit: limit
]

{ #category : 'pls - inspector' }
PLSServer >> inspectorMutex [

	^ inspectorMutex ifNil: [ inspectorMutex := Mutex new ]
]

{ #category : 'pls - inspector' }
PLSServer >> inspectorObjectOf: ref [
	"Answer the object of the reference ref"

	^ self inspectorMutex critical: [
			  (inspectorObjects ifNil: [ Dictionary new ]) at: ref ifAbsent: [
					  PLSUnknownEntity signal:
						  'Unknown inspector reference: ' , ref printString ] ]
]

{ #category : 'pls - inspector' }
PLSServer >> inspectorObjectOfRow: row [
	"Answer the object a row of an inspection list shows: the value of an inspector node, else the row itself"

	^ (row isKindOf: StInspectorNode)
		  ifTrue: [ row rawValue ]
		  ifFalse: [ row ]
]

{ #category : 'pls - inspector' }
PLSServer >> inspectorPrintStringOf: anObject [

	^ [ anObject printStringLimitedTo: 1000 ]
		  on: Error
		  do: [ :error |
				  'Error printing a ' , anObject class name , ': '
				  , error messageText asString ]
]

{ #category : 'pls - inspector' }
PLSServer >> inspectorRawChildrenOf: anObject [
	"Answer the slots and indexed items of anObject, as name -> value"

	^ [
		  (anObject allInspectorNodes reject: [ :node |
			   node isKindOf: StInspectorSelfNode ]) collect: [ :node |
			  node label asString -> node rawValue ] ]
		  on: Error
		  do: [ #(  ) ]
]

{ #category : 'pls - inspector' }
PLSServer >> inspectorRegister: anObject [
	"Answer a new reference to anObject, which keeps anObject alive until the client releases it"

	^ self inspectorMutex critical: [
			  inspectorObjects ifNil: [ inspectorObjects := Dictionary new ].
			  inspectorNextId := (inspectorNextId ifNil: [ 0 ]) + 1.
			  inspectorObjects at: inspectorNextId printString put: anObject.
			  inspectorNextId printString ]
]

{ #category : 'pls - inspector' }
PLSServer >> inspectorRelease: refs all: all [
	"Forget the objects of the references refs, or of every reference when all is true, so that the image can collect them"

	<jrpc: #'pls-inspector:release'>
	self inspectorMutex critical: [
			all = true
				ifTrue: [ inspectorObjects := nil ]
				ifFalse: [
						inspectorObjects ifNotNil: [ :objects |
								(refs ifNil: [ #(  ) ]) do: [ :ref |
									objects removeKey: ref ifAbsent: [ ] ] ] ] ].
	^ nil
]

{ #category : 'pls - inspector' }
PLSServer >> inspectorStart: offset stop: limit size: size [
	"Answer the interval of the indexes of a page of size elements that starts at the zero-based offset, which defaults to 0, and holds at most limit elements, all the remaining ones by default"

	| start |
	start := (offset ifNil: [ 0 ]) max: 0.
	^ start + 1 to:
	  (limit ifNil: [ size ] ifNotNil: [ start + limit min: size ])
]

{ #category : 'pls - inspector' }
PLSServer >> inspectorStringOf: aValue [
	"Answer the text a table cell shows for aValue"

	aValue ifNil: [ ^ '' ].
	(aValue isString or: [ aValue isText ]) ifTrue: [ ^ aValue asString ].
	^ self inspectorPrintStringOf: aValue
]

{ #category : 'pls - inspector' }
PLSServer >> inspectorSyntaxErrorOf: expression [
	"Answer the message of the first syntax error of expression, or nil when it parses"

	| ast |
	ast := RBParser parseFaultyExpression: expression.
	ast isFaulty ifFalse: [ ^ nil ].
	^ (ast allChildren
		   detect: [ :node | node isParseError ]
		   ifNone: [ ^ 'Syntax error' ]) errorMessage
]

{ #category : 'pls - inspector' }
PLSServer >> inspectorTableOf: rows columns: titles cells: cellsBlock objects: objectBlock offset: offset limit: limit [
	"Answer one page of rows as a table view with the column titles, with the total number of rows.
	 cellsBlock answers the texts of the cells of a row and its index, objectBlock the object a row shows"

	^ {
		  (#kind -> 'table').
		  (#columns -> titles asArray).
		  (#items
		   -> ((self inspectorStart: offset stop: limit size: rows size)
				    collect: [ :index |
						    | row cells |
						    row := rows at: index.
						    cells := (cellsBlock value: row value: index) asArray.
						    (self
							     inspectorItemNamed:
								     (cells ifEmpty: [ '' ] ifNotEmpty: [ cells first ])
							     of: (objectBlock value: row))
							    at: #cells put: cells;
							    yourself ]
				    as: Array)).
		  (#total -> rows size) } asDictionary
]

{ #category : 'pls - inspector' }
PLSServer >> inspectorTextOf: aString [

	^ {
		  (#kind -> 'text').
		  (#text -> aString asString) } asDictionary
]

{ #category : 'pls - inspector' }
PLSServer >> inspectorTreeOf: associations offset: offset limit: limit [
	"Answer one page of the associations name -> value as a tree view, with the total number of them"

	^ {
		  (#kind -> 'tree').
		  (#items
		   ->
			   ((self
				     inspectorStart: offset
				     stop: limit
				     size: associations size)
				    collect: [ :index |
						    | association |
						    association := associations at: index.
						    self
							    inspectorItemNamed: association key
							    of: association value ]
				    as: Array)).
		  (#total -> associations size) } asDictionary
]

{ #category : 'pls - inspector' }
PLSServer >> inspectorUnsupported: aString [

	^ {
		  (#kind -> 'unsupported').
		  (#text -> aString) } asDictionary
]

{ #category : 'pls - inspector' }
PLSServer >> inspectorView: ref view: view offset: offset limit: limit [
	"Answer one page of the view view of the object of the reference ref: a tree of its slots for raw, a table of its class hierarchy for meta, else the view of an inspection method of its class, a text or a table"

	<jrpc: #'pls-inspector:view'>
	| object |
	object := self inspectorObjectOf: ref.
	view = 'raw' ifTrue: [
			^ self
				  inspectorTreeOf: (self inspectorRawChildrenOf: object)
				  offset: offset
				  limit: limit ].
	view = 'meta' ifTrue: [
		^ self inspectorMetaOf: object offset: offset limit: limit ].
	^ self
		  inspectorExtensionView: view
		  of: object
		  offset: offset
		  limit: limit
]

{ #category : 'pls - inspector' }
PLSServer >> inspectorViewIdOf: selector [
	"Answer the id of the view of the inspection method selector, or nil for an inspection the client cannot show"

	selector = #inspectionRaw: ifTrue: [ ^ 'raw' ].
	selector = #inspectionMeta: ifTrue: [ ^ 'meta' ].
	selector = #inspectionBreakpoints: ifTrue: [ ^ nil ].
	^ selector asString
]

{ #category : 'pls - inspector' }
PLSServer >> inspectorViewOfPresenter: presenter offset: offset limit: limit [
	"Answer the view of the inspection presenter: its text when it shows a text, its rows when it shows a list, a table or a tree, of which the roots only"

	| rows columns |
	(presenter isKindOf: SpAbstractTextPresenter) ifTrue: [
		^ self inspectorTextOf: presenter text ].
	(presenter isKindOf: SpAbstractListPresenter) ifTrue: [
		rows := presenter items asArray ].
	(presenter isKindOf: SpAbstractTreePresenter) ifTrue: [
		rows := presenter roots asArray ].
	rows ifNil: [
			^ self inspectorUnsupported:
				  'This view is not available outside of Pharo.' ].
	((presenter respondsTo: #columns) and: [
		 presenter columns isNotEmpty ]) ifFalse: [
			^ self
				  inspectorTableOf: rows
				  columns: #( 'Value' )
				  cells: [ :row :index |
						  { (self inspectorStringOf: ([ presenter display value: row ]
								    on: Error
								    do: [ row ])) } ]
				  objects: [ :row | self inspectorObjectOfRow: row ]
				  offset: offset
				  limit: limit ].
	columns := presenter columns reject: [ :column |
		           column isKindOf: SpImageTableColumn ].
	^ self
		  inspectorTableOf: rows
		  columns: (columns collect: [ :column |
				   column title
					   ifNil: [ '' ]
					   ifNotNil: [ :title | title asString ] ])
		  cells: [ :row :index |
				  columns collect: [ :column |
					  self inspectorCellOf: column for: row at: index ] ]
		  objects: [ :row | self inspectorObjectOfRow: row ]
		  offset: offset
		  limit: limit
]

{ #category : 'pls - inspector' }
PLSServer >> inspectorViewsOf: anObject [
	"Answer the views of anObject, as id and title: Raw, Meta and the inspections its class adds to the inspector"

	| views |
	views := OrderedCollection new.
	(self inspectorContextsOf: anObject) do: [ :context |
			(self inspectorViewIdOf: context methodSelector) ifNotNil: [ :id |
					views add: {
							(#id -> id).
							(#title -> context title asString) } asDictionary ] ].
	(views anySatisfy: [ :view | (view at: #id) = 'raw' ]) ifFalse: [
			views addFirst: {
					(#id -> 'raw').
					(#title -> 'Raw') } asDictionary ].
	(views anySatisfy: [ :view | (view at: #id) = 'meta' ]) ifFalse: [
			views addLast: {
					(#id -> 'meta').
					(#title -> 'Meta') } asDictionary ].
	^ views asArray
]

{ #category : 'pls - env changes' }
PLSServer >> isSubscribedToEnvironmentChanges [

	^ envChangesMutex notNil
]

{ #category : 'pls - mcp' }
PLSServer >> mcpEnabledIn: initializationOptions [
	"The MCP server starts unless the client says otherwise"

	| options |
	initializationOptions isDictionary ifFalse: [ ^ true ].
	options := initializationOptions at: #mcp ifAbsent: [ ^ true ].
	options isDictionary ifFalse: [ ^ true ].
	^ (options at: #enabled ifAbsent: [ true ]) ~= false
]

{ #category : 'pls - mcp' }
PLSServer >> mcpEndpoint [
	"The address of the MCP server of the image, as announced in the capabilities, or nil when it does not run"

	<jrpc: #'pls:mcpEndpoint'>
	^ mcpEndpoint ifNotNil: [ :endpoint |
		  endpoint isRunning ifTrue: [ endpoint asJRPCJSON ] ]
]

{ #category : 'pls - mcp' }
PLSServer >> mcpStartWith: initializationOptions [
	"Start the MCP server of evref-BL/MCP in this image, so that agents work on it, unless the client disabled it (initializationOptions.mcp.enabled = false) or PharoLanguageServer-MCP is not loaded. Answer it, or nil.
	 A failure to start leaves the language server working without it"

	| endpointClass |
	(self mcpEnabledIn: initializationOptions) ifFalse: [ ^ nil ].
	endpointClass := self class environment
		                 at: #PLSMCPEndpoint
		                 ifAbsent: [ ^ nil ].
	self mcpStop.
	^ [ mcpEndpoint := endpointClass start ]
		  on: Error
		  do: [ :error |
				  self record:
					  'Unable to start the MCP server: ' , error messageText.
				  error return: nil ]
]

{ #category : 'pls - mcp' }
PLSServer >> mcpStop [

	mcpEndpoint ifNotNil: [ :endpoint | endpoint stop ].
	mcpEndpoint := nil
]

{ #category : 'lsp - navigation' }
PLSServer >> navCallItemOf: aMethod [
	"Answer the CallHierarchyItem of aMethod. Its data keeps the pls-env id of the method"

	| source ast id |
	source := aMethod sourceCode.
	ast := RBParser parseFaultyMethod: source.
	id := self envMethodIdOf: aMethod.
	^ {
		  (#name -> (self envPathOf: id)).
		  (#kind -> 6).
		  (#detail -> aMethod package name).
		  (#uri -> (self navUriOfMethod: aMethod)).
		  (#range -> (self navRangeFrom: 1 to: source size in: source)).
		  (#selectionRange -> (self navRangeOf: ast in: source)).
		  (#data -> { (#id -> id) } asDictionary) } asDictionary
]

{ #category : 'lsp - navigation' }
PLSServer >> navClassOf: document at: position [
	"Answer the class at position, or else the class of the method or definition document is about, or nil"

	| context |
	(self navTargetIn: document at: position) ifNotNil: [ :target |
		(target at: #kind) = #class ifTrue: [ ^ target at: #class ] ].
	context := self navContextOf: document at: position.
	(context notNil and: [ (context at: #behavior) notNil ]) ifTrue: [
		^ (context at: #behavior) instanceSide ].
	(document isKindOf: PLSTonelDocument) ifTrue: [
		^ self navTonelClassOf: document text ].
	^ nil
]

{ #category : 'lsp - navigation' }
PLSServer >> navClassOfItem: item [
	"Answer the class of a TypeHierarchyItem, or nil if the image no longer holds it"

	^ [ self envClassNamed: (self envPathOf: ((item at: #data) at: #id)) ]
		  on: PLSUnknownEntity
		  do: [ nil ]
]

{ #category : 'lsp - navigation' }
PLSServer >> navClassTarget: aClass [

	^ {
		  (#kind -> #class).
		  (#name -> aClass name).
		  (#class -> aClass) } asDictionary
]

{ #category : 'lsp - navigation' }
PLSServer >> navContextOf: document at: position [
	"Answer a dictionary that places position in the code of document:
	 - #source, the source of the method or script that holds position;
	 - #offset, the index in #source of the character after position;
	 - #start, the index in the text of document of the first character of #source;
	 - #behavior, the class of the method, or nil;
	 - #isMethod, whether #source is a method rather than a script.
	 Answer nil for a position outside the methods of a Tonel document"

	| text offset |
	text := document text.
	offset := (text plsToPosition: position) + 1.
	(document isKindOf: PLSTonelDocument) ifTrue: [
		^ self navTonelContextOf: text at: offset ].
	^ {
		  (#source -> text).
		  (#offset -> offset).
		  (#start -> 1).
		  (#behavior
		   -> (document isMethodSource ifTrue: [ document behavior ])).
		  (#isMethod -> document isMethodSource) } asDictionary
]

{ #category : 'lsp - navigation' }
PLSServer >> navDeclarationsOf: target [
	"Answer the locations where target is declared, for the references that include declarations"

	| kind |
	kind := target at: #kind.
	kind = #selector ifTrue: [
		^ self navImplementorsOf: (target at: #name) ].
	kind = #class ifTrue: [
		^ { (self navLocationOfClass: (target at: #class)) } ].
	kind = #instVar ifTrue: [
			^ { (self
				   navLocationOfClass: (target at: #class)
				   declaring: (target at: #name)) } ].
	((target at: #binding) isKindOf: ClassVariable) ifTrue: [
			^ { (self
				   navLocationOfClass: (target at: #binding) definingClass
				   declaring: (target at: #name)) } ].
	^ #(  )
]

{ #category : 'lsp - navigation' }
PLSServer >> navImplementorOf: aSelector sentTo: receiver from: aBehavior [
	"Answer the method most likely run by sending aSelector to the receiver node from a method of aBehavior, or nil:
	 the lookup from aBehavior for self, from its superclass for super, from the class side of a class named as receiver,
	 and else the implementor that is defined the highest in its hierarchy, a class rather than a trait, the most general one.
	 The nodes come from a parse without semantic analysis: self and super are known by their names"

	| implementors |
	receiver isVariable ifTrue: [
			aBehavior ifNotNil: [
					receiver name = 'self' ifTrue: [
						^ aBehavior lookupSelector: aSelector ].
					receiver name = 'super' ifTrue: [
							^ aBehavior superclass ifNotNil: [ :superclass |
								  superclass lookupSelector: aSelector ] ] ].
			((aBehavior ifNil: [ UndefinedObject ]) bindingOf: receiver name)
				ifNotNil: [ :binding |
						(binding value isClassOrTrait and: [
							 binding value name = receiver name ]) ifTrue: [
								(binding value classSide lookupSelector: aSelector) ifNotNil: [
									:method | ^ method ] ] ] ].
	implementors := (SystemNavigation default allImplementorsOf:
		                 aSelector) reject: [ :method | method isFromTrait ].
	implementors ifEmpty: [ ^ nil ].
	(implementors reject: [ :method | method methodClass isTrait ])
		ifNotEmpty: [ :classMethods | implementors := classMethods ].
	^ (implementors asArray sort: [ :a :b |
			   | depthA depthB |
			   depthA := a methodClass instanceSide allSuperclasses size.
			   depthB := b methodClass instanceSide allSuperclasses size.
			   depthA = depthB
				   ifTrue: [ a methodClass name <= b methodClass name ]
				   ifFalse: [ depthA < depthB ] ]) first
]

{ #category : 'lsp - navigation' }
PLSServer >> navImplementorsOf: aSelector [
	"Answer the locations of the selectors of the implementors of aSelector"

	^ self
		  navLocationsIn:
		  (SystemNavigation default allImplementorsOf: aSelector)
		  where: [ :node | node isMethod ]
]

{ #category : 'lsp - navigation' }
PLSServer >> navLine: line character: character [

	^ {
		  (#line -> line).
		  (#character -> character) } asDictionary
]

{ #category : 'lsp - navigation' }
PLSServer >> navLocationOfClass: aClass [

	^ self navLocationOfClass: aClass declaring: nil
]

{ #category : 'lsp - navigation' }
PLSServer >> navLocationOfClass: aClass declaring: aVariableName [
	"Answer the location of the editor of the definition of aClass, at the declaration of aVariableName if any"

	| definition range |
	definition := self envTonelDefinitionOf: aClass instanceSide.
	range := self navRangeFrom: 1 to: 0 in: definition.
	aVariableName ifNotNil: [
			| index |
			index := definition indexOfSubCollection:
				         '''' , aVariableName , ''''.
			index > 0 ifTrue: [
					range := self
						         navRangeFrom: index + 1
						         to: index + aVariableName size
						         in: definition ] ].
	^ {
		  (#uri -> (self navUriOfClass: aClass)).
		  (#range -> range) } asDictionary
]

{ #category : 'lsp - navigation' }
PLSServer >> navLocationsIn: methods where: aBlock [
	"Answer the LSP locations of the nodes of methods for which aBlock is true, in the editors of methods"

	^ (self navSorted: methods) flatCollect: [ :method |
			  | uri |
			  uri := self navUriOfMethod: method.
			  (self navRangesIn: method where: aBlock) collect: [ :range |
					  {
						  (#uri -> uri).
						  (#range -> range) } asDictionary ] ]
]

{ #category : 'lsp - navigation' }
PLSServer >> navMatcherOf: target [
	"Answer a block that tells whether a node of a method uses target"

	| name |
	name := target at: #name.
	(target at: #kind) = #selector ifTrue: [
			^ [ :node |
				  (node isMessage and: [ node selector == name ]) or: [
					  node isLiteralNode and: [ node value == name ] ] ] ].
	^ [ :node | node isVariable and: [ node name = name ] ]
]

{ #category : 'lsp - navigation' }
PLSServer >> navMethodOfItem: item [
	"Answer the method of a CallHierarchyItem, or nil if the image no longer holds it"

	^ [
	  self envMethodNamed: (self envPathOf: ((item at: #data) at: #id)) ]
		  on: PLSUnknownEntity
		  do: [ nil ]
]

{ #category : 'lsp - navigation' }
PLSServer >> navPosition: index in: text [
	"Answer the LSP position before the character at index in text. index is text size + 1 at the end of text"

	| line start |
	text ifEmpty: [ ^ self navLine: 0 character: 0 ].
	line := -1.
	start := 1.
	text plsLineIndicesDo: [ :lineStart :lineEnd :next |
			line := line + 1.
			start := lineStart.
			index <= next ifTrue: [
					^ self
						  navLine: line
						  character: (index - lineStart min: lineEnd - lineStart + 1) ] ].
	^ self navLine: line character: index - start
]

{ #category : 'lsp - navigation' }
PLSServer >> navRangeFrom: start to: stop in: text [
	"Answer the LSP range of the characters from start to stop of text"

	^ {
		  (#start -> (self navPosition: start in: text)).
		  (#end -> (self navPosition: stop + 1 in: text)) } asDictionary
]

{ #category : 'lsp - navigation' }
PLSServer >> navRangeOf: node in: source [
	"Answer the range of node in source. A message or a method is located by its selector"

	(node isMessage or: [ node isMethod ]) ifTrue: [
			^ self
				  navRangeFrom: node keywordsIntervals first first
				  to: node keywordsIntervals last last
				  in: source ].
	^ self navRangeFrom: node start to: node stop in: source
]

{ #category : 'lsp - navigation' }
PLSServer >> navRangesIn: aMethod where: aBlock [
	"Answer the ranges, in the source of aMethod, of its nodes for which aBlock is true.
	 A method that holds none of them, such as a method that refers to a selector only through a pragma, answers its beginning"

	| source ranges |
	source := aMethod sourceCode.
	ranges := ((RBParser parseFaultyMethod: source) allChildren select:
		           aBlock) collect: [ :node |
		          self navRangeOf: node in: source ].
	^ ranges ifEmpty: [ { (self navRangeFrom: 1 to: 0 in: source) } ]
]

{ #category : 'lsp - navigation' }
PLSServer >> navReferencingMethodsOf: target [

	| kind |
	kind := target at: #kind.
	kind = #selector ifTrue: [
		^ SystemNavigation default allSendersOf: (target at: #name) ].
	kind = #class ifTrue: [
			^ SystemNavigation default allReferencesTo:
				  (target at: #class) binding ].
	kind = #binding ifTrue: [
		^ SystemNavigation default allReferencesTo: (target at: #binding) ].
	kind = #instVar ifTrue: [
		^ ((target at: #class) slotNamed: (target at: #name)) usingMethods ].
	^ #(  )
]

{ #category : 'lsp - navigation' }
PLSServer >> navSelectorTarget: aSelector [

	^ {
		  (#kind -> #selector).
		  (#name -> aSelector asSymbol) } asDictionary
]

{ #category : 'lsp - navigation' }
PLSServer >> navSorted: methods [
	"Answer methods without the copies of trait methods in the classes that use them, sorted by class then selector"

	^ (methods reject: [ :method | method isFromTrait ]) asSet asArray
		  sort: [ :a :b |
				  a methodClass name = b methodClass name
					  ifTrue: [ a selector <= b selector ]
					  ifFalse: [ a methodClass name <= b methodClass name ] ]
]

{ #category : 'lsp - navigation' }
PLSServer >> navSubtypesOf: aClass deep: aBoolean [
	"Answer the subclasses of aClass, and the classes that use it when it is a trait, sorted by name. With aBoolean, all of their own subtypes too"

	| subtypes |
	subtypes := (aClass isTrait
		             ifTrue: [
		             aClass users asArray select: [ :each |
			             each isInstanceSide ] ]
		             ifFalse: [ aClass subclasses ]) asArray sort: [ :a :b |
		            a name <= b name ].
	aBoolean ifFalse: [ ^ subtypes ].
	^ subtypes flatCollect: [ :each |
		  { each } , (self navSubtypesOf: each deep: true) ]
]

{ #category : 'lsp - navigation' }
PLSServer >> navSymbolTarget: aSymbol [
	"A symbol names a class, as in a class definition, or a selector, as in a perform:"

	(aSymbol notEmpty and: [ aSymbol first isUppercase ]) ifTrue: [
			(self class environment classOrTraitNamed: aSymbol) ifNotNil: [
				:class |
				class isClassSide ifFalse: [ ^ self navClassTarget: class ] ] ].
	^ self navSelectorTarget: aSymbol
]

{ #category : 'lsp - navigation' }
PLSServer >> navTargetIn: document at: position [
	"Answer what position designates in document, as a dictionary whose #kind is one of:
	 - #selector, with its #name;
	 - #class, with its #name and #class;
	 - #instVar, with its #name and the #class that defines it;
	 - #binding, a class or global variable, with its #name and #binding;
	 - #temp, a temporary or argument, with its #name, the #scope node that defines it and the #context of its method.
	 Answer nil when position designates none of them"

	| context |
	context := self navContextOf: document at: position.
	context ifNotNil: [
			| ast |
			ast := (context at: #isMethod)
				       ifTrue: [
				       RBParser parseFaultyMethod: (context at: #source) ]
				       ifFalse: [
				       RBParser parseFaultyExpression: (context at: #source) ].
			context at: #ast put: ast.
			"The character after position, then the one before, so that a cursor at the end of a word designates it"
			{
				(context at: #offset).
				((context at: #offset) - 1) } do: [ :offset |
					(ast bestNodeFor: (offset to: offset)) ifNotNil: [ :node |
							(self navTargetOf: node at: offset in: context) ifNotNil: [
								:target | ^ target ] ] ] ].
	^ self
		  navWordTargetAt: position
		  in: document text
		  of: ((document isKindOf: PLSTonelDocument) ifTrue: [
				   self navTonelClassOf: document text ])
]

{ #category : 'lsp - navigation' }
PLSServer >> navTargetOf: node at: offset in: context [

	(node isMessage or: [ node isMethod ]) ifTrue: [
			^ (node keywordsIntervals anySatisfy: [ :each |
				   each rangeIncludes: offset ]) ifTrue: [
					  (self navSelectorTarget: node selector)
						  at: #node put: node;
						  at: #context put: context;
						  yourself ] ].
	(node isLiteralNode and: [ node value isSymbol ]) ifTrue: [
		^ self navSymbolTarget: node value ].
	node isVariable ifTrue: [ ^ self navVariableTarget: node in: context ].
	^ nil
]

{ #category : 'lsp - navigation' }
PLSServer >> navTempLocationsOf: target in: uri [
	"Answer the locations of the uses of the temporary or argument target in the document uri"

	| context scope text |
	context := target at: #context.
	scope := target at: #scope.
	text := (self context textItem: uri) text.
	^ ((scope allChildren select: [ :node |
			    node isVariable and: [
					    node name = (target at: #name) and: [
						    (node whoDefines: node name) == scope ] ] ]) collect: [
			   :node |
			   {
				   (#uri -> uri).
				   (#range -> (self
					     navRangeFrom: node start + (context at: #start) - 1
					     to: node stop + (context at: #start) - 1
					     in: text)) } asDictionary ]) asArray
]

{ #category : 'lsp - navigation' }
PLSServer >> navTonelClassOf: text [
	"Answer the class that the Tonel text defines or extends, or nil"

	([ PLSTonelParser parseString: text ]
		 on: Error
		 do: [ #(  ) ])
		detect: [ :each | each isClassDefinition ]
		ifFound: [ :definition |
				^ (self class environment classOrTraitNamed: definition className)
					  ifNotNil: [ :class | class instanceSide ] ].
	^ nil
]

{ #category : 'lsp - navigation' }
PLSServer >> navTonelContextOf: text at: offset [
	"Answer the context of offset in the method of the Tonel text that holds it, or nil.
	 #source is the method as written in text, from its selector to its closing bracket excluded, with its opening bracket blanked:
	 its indexes are the ones of text shifted by #start - 1"

	| definitions method start open source class |
	definitions := [ PLSTonelParser parseString: text ]
		               on: Error
		               do: [ ^ nil ].
	method := definitions
		          detect: [ :each |
				          each isMethodDefinition and: [
					          offset between: each startPos and: each endPos ] ]
		          ifNone: [ ^ nil ].
	start := (text indexOfSubCollection: '>>' startingAt: method startPos)
	         + 2.
	[ start < method bodyStartPos and: [ (text at: start) isSeparator ] ]
		whileTrue: [ start := start + 1 ].
	offset < start ifTrue: [ ^ nil ].
	open := text indexOf: $[ startingAt: method bodyStartPos.
	source := text copyFrom: start to: method endPos - 1.
	source at: open - start + 1 put: Character space.
	class := self class environment classOrTraitNamed: method className.
	^ {
		  (#source -> source).
		  (#offset -> (offset - start + 1)).
		  (#start -> start).
		  (#behavior -> (class ifNotNil: [
				    method classIsMeta
					    ifTrue: [ class classSide ]
					    ifFalse: [ class ] ])).
		  (#isMethod -> true) } asDictionary
]

{ #category : 'lsp - navigation' }
PLSServer >> navTypeItemOf: aClass [
	"Answer the TypeHierarchyItem of aClass. Its data keeps the pls-env id of the class"

	| location id |
	location := self navLocationOfClass: aClass.
	id := self envClassIdOf: aClass.
	^ {
		  (#name -> aClass name).
		  (#kind -> (aClass isTrait
			    ifTrue: [ 11 ]
			    ifFalse: [ 5 ])).
		  (#detail -> aClass package name).
		  (#uri -> (location at: #uri)).
		  (#range -> (location at: #range)).
		  (#selectionRange -> (location at: #range)).
		  (#data -> { (#id -> id) } asDictionary) } asDictionary
]

{ #category : 'lsp - navigation' }
PLSServer >> navUriOfClass: aClass [

	^ self
		  envUriOf: (self envClassIdOf: aClass instanceSide)
		  inPackage: aClass instanceSide package name
]

{ #category : 'lsp - navigation' }
PLSServer >> navUriOfMethod: aMethod [

	^ self
		  envUriOf: (self envMethodIdOf: aMethod)
		  inPackage: aMethod package name
]

{ #category : 'lsp - navigation' }
PLSServer >> navVariableTarget: node in: context [

	| name behavior binding |
	name := node name.
	(#( 'self' 'super' 'thisContext' ) includes: name) ifTrue: [ ^ nil ].
	(node whoDefines: name) ifNotNil: [ :scope |
			^ {
				  (#kind -> #temp).
				  (#name -> name).
				  (#scope -> scope).
				  (#context -> context) } asDictionary ].
	behavior := context at: #behavior.
	(behavior notNil and: [ behavior allInstVarNames includes: name ])
		ifTrue: [
				^ {
					  (#kind -> #instVar).
					  (#name -> name).
					  (#class -> (behavior whichClassDefinesInstVar: name)) }
					  asDictionary ].
	binding := (behavior ifNil: [ UndefinedObject ]) bindingOf: name.
	binding ifNil: [ ^ nil ].
	(binding value isClassOrTrait and: [ binding value name = name ])
		ifTrue: [ ^ self navClassTarget: binding value ].
	^ {
		  (#kind -> #binding).
		  (#name -> name).
		  (#binding -> binding) } asDictionary
]

{ #category : 'lsp - navigation' }
PLSServer >> navWordTargetAt: position in: text of: aClass [
	"Answer what the word at position in text names, outside of a method: a class, as in a Tonel class definition or method header,
	 or a variable declared by the Tonel definition of aClass, on either side. Answer nil otherwise.
	 The keyword of a Tonel definition, such as `Class {`, names no class"

	| offset start stop next word class |
	offset := (text plsToPosition: position) + 1.
	start := offset.
	[ start > 1 and: [ (text at: start - 1) isAlphaNumeric ] ]
		whileTrue: [ start := start - 1 ].
	stop := offset - 1.
	[ stop < text size and: [ (text at: stop + 1) isAlphaNumeric ] ]
		whileTrue: [ stop := stop + 1 ].
	stop < start ifTrue: [ ^ nil ].
	word := text copyFrom: start to: stop.
	aClass ifNotNil: [
			{
				aClass.
				aClass classSide } do: [ :side |
					(side allInstVarNames includes: word) ifTrue: [
							^ {
								  (#kind -> #instVar).
								  (#name -> word).
								  (#class -> (side whichClassDefinesInstVar: word)) }
								  asDictionary ] ].
			(aClass classVarNames includes: word asSymbol) ifTrue: [
					^ {
						  (#kind -> #binding).
						  (#name -> word).
						  (#binding -> (aClass classVariableNamed: word asSymbol)) }
						  asDictionary ] ].
	word first isUppercase ifFalse: [ ^ nil ].
	next := stop + 1.
	[ next <= text size and: [ (text at: next) isSeparator ] ]
		whileTrue: [ next := next + 1 ].
	(next <= text size and: [ (text at: next) = ${ ]) ifTrue: [ ^ nil ].
	class := self class environment classOrTraitNamed: word.
	(class isNil or: [ class isClassSide ]) ifTrue: [ ^ nil ].
	^ self navClassTarget: class
]

{ #category : 'lsp - initialization' }
PLSServer >> onInitializeTrace: trace processId: processId locale: locale clientInfo: clientInfo rootPath: rootPath workspaceFolders: workspaceFolders capabilities: capabilities rootUri: rootUri initializationOptions: initializationOptions [

	<jrpc: #initialize>
	| result |
	self context clientContext: (PLPInitializeParams new
			 trace: trace;
			 processId: processId;
			 locale: locale;
			 clientInfo: clientInfo;
			 rootPath: rootPath;
			 workspaceFolders: workspaceFolders;
			 capabilities: (PLPClientCapabilities from: capabilities);
			 rootUri: rootUri;
			 yourself).
	trace ifNotNil: [ self context traceValue: trace ].
	result := PLSInitializeResult new.
	(self mcpStartWith: initializationOptions) ifNotNil: [ :endpoint |
		result capabilities experimental at: #mcp put: endpoint asJRPCJSON ].
	(self uiStartWith: initializationOptions) ifNotNil: [ :ui |
		result capabilities experimental at: #'pls-ui' put: ui ].
	^ result
]

{ #category : 'lsp - text synchronisation' }
PLSServer >> openDocument: textDocument [
	"Register the document sent by the client and answer it"

	| document |
	document := self context
		            textItem: (textDocument at: #uri)
		            put: (PLSDocument from: textDocument).
	document server: self.
	document savedText: document text.
	^ document
]

{ #category : 'pls' }
PLSServer >> plsCreateClass: className packageName: packageName superclassName: superclassName instanceVariables: instanceVariables [

	<jrpc: #'pls:createClass'>
	| normalizedClassName normalizedPackageName normalizedSuperclassName normalizedInstanceVariables superclass existingClass createdClass |
	normalizedClassName := className ifNil: [ '' ].
	normalizedClassName := normalizedClassName trimBoth.
	normalizedClassName ifEmpty: [
		self error: 'Class name cannot be empty.' ].

	normalizedPackageName := packageName ifNil: [ '' ].
	normalizedPackageName := normalizedPackageName trimBoth.
	normalizedPackageName ifEmpty: [
		self error: 'Package name cannot be empty.' ].

	normalizedSuperclassName := superclassName ifNil: [ 'Object' ].
	normalizedSuperclassName := normalizedSuperclassName trimBoth.
	normalizedSuperclassName ifEmpty: [
		normalizedSuperclassName := 'Object' ].

	normalizedInstanceVariables := instanceVariables ifNil: [ '' ].
	normalizedInstanceVariables := normalizedInstanceVariables trimBoth.

	self plsCreatePackage: normalizedPackageName.
	existingClass := self class environment
		                 at: normalizedClassName asSymbol
		                 ifAbsent: [ nil ].
	existingClass ifNotNil: [
		^ 'Class ' , normalizedClassName , ' already exists.' ].

	superclass := self class environment
		              at: normalizedSuperclassName asSymbol
		              ifAbsent: [
		              self error:
			              'Superclass not found: ' , normalizedSuperclassName ].
	createdClass := superclass classInstaller make: [ :builder |
		                builder
			                superclass: superclass;
			                name: normalizedClassName asSymbol;
			                slotsFromString: normalizedInstanceVariables;
			                sharedVariablesFromString: '';
			                package: normalizedPackageName;
			                environment: superclass environment ].
	^ 'Class ' , createdClass name , ' created in package '
	  , normalizedPackageName
]

{ #category : 'pls' }
PLSServer >> plsCreatePackage: packageName [

	<jrpc: #'pls:createPackage'>
	| normalizedPackageName wasExisting |
	normalizedPackageName := packageName ifNil: [ '' ].
	normalizedPackageName := normalizedPackageName trimBoth.
	normalizedPackageName ifEmpty: [
		self error: 'Package name cannot be empty.' ].
	wasExisting := self packageOrganizer hasPackage:
		               normalizedPackageName.
	self packageOrganizer ensurePackage: normalizedPackageName.
	^ wasExisting
		  ifTrue: [ 'Package ' , normalizedPackageName , ' already exists.' ]
		  ifFalse: [ 'Package ' , normalizedPackageName , ' created.' ]
]

{ #category : 'debug' }
PLSServer >> plsDebugBreakpoints [
	"Answer the breakpoints of the image on lines of methods, except the function breakpoints: the debug points that stop, whoever set them, so that the client shows the ones it does not know"

	<jrpc: #'pls-debug:breakpoints'>
	| functions |
	functions := self debugPoints at: #function ifAbsent: [ #(  ) ].
	^ ((DebugPoint all asArray select: [ :each |
			    (each isKindOf: BreakDebugPoint) and: [
				    (functions includes: each) not ] ]) collect: [ :each |
		   self debugDescriptionOf: each ]) reject: [ :each | each isNil ]
]

{ #category : 'debug' }
PLSServer >> plsDebugDismiss: aDebugSessionId [
	"Forget the process that stopped on an exception and end it, when the client does not debug it"

	<jrpc: #'pls-debug:dismiss'>
	| session |
	session := [ self debugSessionAt: aDebugSessionId ]
		           on: PLSUnknownEntity
		           do: [ :error | ^ false ].
	session terminate.
	^ true
]

{ #category : 'debug' }
PLSServer >> plsDebugSetBreakpoints: entity breakpoints: breakpoints [
	"Replace the breakpoints of the method entity, a pls-env id, by breakpoints, the source breakpoints of VS Code: a line of the source of the method, and an optional condition, hitCondition and logMessage. Each one is a debug point of Pharo on the first statement of its line or after it. Answer for each one whether it is installed and the line where it stops"

	<jrpc: #'pls-debug:setBreakpoints'>
	| method |
	method := [ self envMethodNamed: (self envPathOf: entity) ]
		          on: PLSUnknownEntity
		          do: [ :error |
				          self debugPointsAt: entity put: #(  ).
				          ^ breakpoints collect: [ :each |
					            self debugUnverified: error messageText ] ].
	^ self
		  debugInstall: (breakpoints collect: [ :each |
				   each -> (self debugNodeIn: method atLine: (each at: #line)) ])
		  at: entity
]

{ #category : 'debug' }
PLSServer >> plsDebugSetFunctionBreakpoints: breakpoints [
	"Replace the function breakpoints by breakpoints, the function breakpoints of VS Code: the name of a method, as Class>>selector or Class class>>selector, and an optional condition and hitCondition. Each one is a debug point of Pharo on the first statement of its method"

	<jrpc: #'pls-debug:setFunctionBreakpoints'>
	^ self
		  debugInstall: (breakpoints collect: [ :each |
					   each -> ([
						    | method |
						    method := self envMethodNamed:
							              ((each at: #name) trimBoth
								               copyReplaceAll: '>>#'
								               with: '>>').
						    method ast statements
							    ifEmpty: [ method ast ]
							    ifNotEmpty: [ :statements | statements first ] ]
						    on: PLSUnknownEntity
						    do: [ :error | error messageText ]) ])
		  at: #function
]

{ #category : 'pls' }
PLSServer >> plsExecuteClass: class test: testMethod [
	<jrpc: #'pls:executeClassTest'>
	| result |
	result := (self class environment at: class asSymbol)
		run: testMethod asSymbol.
	^ result printString
	"{(#failures -> (result failures collect: #printString as: Array)).
	(#errors -> (result errors collect: #printString as: Array)).
	(#skipped -> (result skipped collect: #printString as: Array)).
	(#passed -> (result passed collect: #printString as: Array))}
		asDictionary"
]

{ #category : 'pls' }
PLSServer >> plsExecuteClassTests: className [
	<jrpc: #'pls:executeClassTests'>
	| result |
	result := (self class environment at: className asSymbol) suite run.
	^ result printString
	"{(#failures -> (result failures collect: #printString as: Array)).
	(#errors -> (result errors collect: #printString as: Array)).
	(#skipped -> (result skipped collect: #printString as: Array)).
	(#passed -> (result passed collect: #printString as: Array))}
		asDictionary"
]

{ #category : 'pls' }
PLSServer >> plsGetClassContent: class [

	<jrpc: #'pls:classContent'>
	| className |
	className := ((class substrings: '/') last withoutSuffix: '.st')
		             withoutSuffix: '.class'.
	^ String streamContents: [ :stream |
		  TonelWriter
			  exportClass: (self class environment at: className asSymbol)
			  on: stream ]
]

{ #category : 'pls' }
PLSServer >> plsGetClasses: package [
	<jrpc: #'pls:classes'>
	^ [ package asPackage classes
		collect: [ :class | package , '/' , class name , '.class.st' ]
		as: Array ]
		on: Error
		do: [ {} asArray ]
]

{ #category : 'pls' }
PLSServer >> plsGetPackages [
	<jrpc: #'pls:packages'>
	^ (self packageOrganizer packages collect: #name)
		asArray
]

{ #category : 'pls - gtk' }
PLSServer >> plsGtkInspectIt: line textDocument: textDocumentURI [

	"| compiler inspector |
	compiler := self compilerFor: nil.
	inspector := (PLSApplication current new: StInspector).
	inspector model: (StInspectorModel on: ([ compiler evaluate: line ] on: Exception do: [ :error | error ])).
	inspector openWithSpec."

	<jrpc: #'pls-gtk:inspectIt'>
	| app compiler answer2 |
	compiler := self compilerFor: (textDocumentURI at: #path).
	answer2 := [ compiler evaluate: line ] on: Exception do: [ :error | 'error' record. error ].
	[ 
	app := SpApplication new
		       useBackend: #Gtk;
		       yourself.

	(StInspectorPresenter onObject: answer2)
		application: app;
		open ]
		on: Error
		do: [ :err | ^ err message printString ].
	'opened with spec' record.
	^ 'ok'
]

{ #category : 'pls - developer' }
PLSServer >> plsOpenLog [

	<jrpc: #'pls-developer:openLog'>
	(TinyLogger default ensureMoreFileLoggerNamed: 'LSP.log') open.
	^ 'success'
]

{ #category : 'pls - developer' }
PLSServer >> plsResetLog [

	<jrpc: #'pls-developer:clearLog'>
	(TinyLogger default ensureMoreFileLoggerNamed: 'LSP.log') clearLog.
	^ 'success'
]

{ #category : 'pls' }
PLSServer >> plsTestCaseOf: aTestURI [
	"Answer the test case of the method of a test: pharoImage://<package>/<class>.class.st#<selector>"

	| className |
	className := ((aTestURI at: #path) substrings: '/') last
		             withoutSuffix: '.class.st'.
	^ (self class environment at: className asSymbol) selector:
		  (aTestURI at: #fragment) asSymbol
]

{ #category : 'pls' }
PLSServer >> plsTestDebugTest: aTestURI [
	"Run a test so that its failure or error opens the debugger of the client, which can fix it and restart it.
	 Answer the result of the test, or the failure or error that opened the debugger"

	<jrpc: #'pls:test-debug-test'>
	^ self
		  debugEvaluate: [
		  self plsTestResultOf: (self plsTestCaseOf: aTestURI) debug ]
		  ifStopped: [ :exception |
				  | description |
				  description := exception description
				                 , ' (opened in the debugger)'.
				  (exception isKindOf: TestFailure)
					  ifTrue: [ { (#failures -> { description }) } asDictionary ]
					  ifFalse: [ { (#errors -> { description }) } asDictionary ] ]
]

{ #category : 'pls' }
PLSServer >> plsTestExecuteTest: aTestURI [

	<jrpc: #'pls:test-execute-test'>
	^ self plsTestResultOf: (self plsTestCaseOf: aTestURI) run
]

{ #category : 'pls - tests' }
PLSServer >> plsTestInClass: aClassURI [

	<jrpc: #'pls:test-in-class'>
	| className |
	className := ((aClassURI at: #path) substrings: '/') last
		             withoutSuffix: '.class.st'.
		
	^ (self class environment at: className asSymbol) suite tests
		  collect: [ :test | (aClassURI at: #external) , '#' , test selector ]
		  as: Array
]

{ #category : 'pls - tests' }
PLSServer >> plsTestInPackage: aPackageURI [

	<jrpc: #'pls:test-in-package'>
	^ [
	  (((aPackageURI at: #path) withoutPrefix: '/') asPackage classes select: [ :class |
		   (class name endsWith: 'Tests') or: [ class name endsWith: 'Test' ] ])
		  collect: [ :class | class plsURIString ]
		  as: Array ]
		  on: Error
		  do: [ {  } asArray ]
]

{ #category : 'pls - tests' }
PLSServer >> plsTestPackages [

	<jrpc: #'pls:test-packages'>
	^ (TestCase allSubclasses
		   reject: #isAbstract
		   thenCollect: [ :class | class package ]) asSet
		  collect: [ :package | package plsURIString ]
		  as: Array

	"'pharoImage://' , class package name , '/' , class name
			   , '.class.st'"
]

{ #category : 'pls' }
PLSServer >> plsTestResultOf: result [
	"Answer the failures, errors, skipped and passed tests of a TestResult as the client reads them"

	^ {
		  (#failures -> (result failures collect: #printString as: Array)).
		  (#errors -> (result errors collect: #printString as: Array)).
		  (#skipped -> (result skipped collect: #printString as: Array)).
		  (#passed -> (result passed collect: #printString as: Array)) }
		  asDictionary
]

{ #category : 'lsp - text synchronisation' }
PLSServer >> publishDiagnosticsFor: document [

	self context clientContext capabilities textDocument ifNotNil: [ :td |
		td diagnostic ifNil: [ self sendDiagnosticsforDocument: document ] ]
]

{ #category : 'pls - playground' }
PLSServer >> resetBindings: textDocument [
	"Forget the variables of a playground page, so that its next evaluation starts afresh"

	<jrpc: #'pls:resetBindings'>
	(self context textItem: (textDocument at: #uri at: #path)) binder
		bindings removeAll.
	^ nil
]

{ #category : 'lsp - diagnostics' }
PLSServer >> sendDiagnosticsforDocument: document [

	self
		sendNotification: 'textDocument/publishDiagnostics'
		params: (PLSPublishDiagnosticsParams new
				 diagnostics: (self diagnosticsOf: document);
				 uri: document uri;
				 version: document version;
				 yourself)
]

{ #category : 'lsp - initialization' }
PLSServer >> serverInitialized [
	"The client is ready for notifications: start sending it the changes of the environment and the Transcript"

	super serverInitialized.
	self envSubscribe.
	self transcriptSubscribe
]

{ #category : 'dap' }
PLSServer >> startDapServer [

	<jrpc: #'dap:startServer'>
	'Start DAP Server.' record.
	^ DAPServer new
		  plsServer: self;
		  debugMode: self debugMode;
		  start
]

{ #category : 'starting' }
PLSServer >> stop [

	self envUnsubscribe.
	self transcriptUnsubscribe.
	self mcpStop.
	super stop
]

{ #category : 'pls - system' }
PLSServer >> systemContextOf: aProcess [
	"Answer the context aProcess runs, the context of the sender for the process that answers"

	^ aProcess == Processor activeProcess
		  ifTrue: [ thisContext sender ]
		  ifFalse: [ aProcess suspendedContext ]
]

{ #category : 'pls - system' }
PLSServer >> systemDebug: id [
	"Suspend the process of the id and give it to a debugger of the client, which opens at once (see #debugRegister:atOnce:). Answer the id of the debug session"

	<jrpc: #'pls-system:debug'>
	| target session |
	target := self systemProcessAt: id.
	target == Processor activeProcess ifTrue: [
			^ JRPCInvalidParameters signal:
				  'The process answering the client cannot be debugged' ].
	target isSuspended ifFalse: [ target suspend ].
	session := target
		           newDebugSessionNamed: target name asString
		           startedAt: target suspendedContext.
	^ { (#debugSessionId -> (self debugRegister: session atOnce: true)) }
		  asDictionary
]

{ #category : 'pls - system' }
PLSServer >> systemDescriptionOfProcess: aProcess ui: uiProcess [
	"Answer the description of aProcess: its id, name, priority, state, the method it runs and whether it is the UI process or the one answering"

	| context |
	context := self systemContextOf: aProcess.
	^ {
		  (#id -> aProcess identityHash).
		  (#name -> (aProcess name ifNil: [ 'a Process' ]) asString).
		  (#priority -> aProcess priority).
		  (#state -> (self systemStateOf: aProcess)).
		  (#method
		   -> (context ifNotNil: [ self systemLabelOfContext: context ])).
		  (#uri -> (context ifNotNil: [ self systemUriOfContext: context ])).
		  (#ui -> (aProcess == uiProcess)).
		  (#current -> (aProcess == Processor activeProcess)) } asDictionary
]

{ #category : 'pls - system' }
PLSServer >> systemLabelOfContext: aContext [
	"Answer Class>>selector for the method aContext runs, [] in Class>>selector for a block, with the class of the receiver when it inherits the method"

	^ self
		  systemLabelOfMethod: aContext method
		  receiverClass: ([ thisContext objectClass: aContext receiver ]
				   on: Error
				   do: [ :error | nil ])
]

{ #category : 'pls - system' }
PLSServer >> systemLabelOfMethod: aCompiledCode receiverClass: aClass [
	"Answer Class>>selector for aCompiledCode, [] in Class>>selector for a block, with aClass when it inherits the method"

	| method label |
	method := aCompiledCode method.
	label := (aClass isNil or: [ aClass == method methodClass ])
		         ifTrue: [ method methodClass name , '>>' , method selector ]
		         ifFalse: [
			         aClass name , '(' , method methodClass name , ')>>'
			         , method selector ].
	^ aCompiledCode isCompiledBlock
		  ifTrue: [ '[] in ' , label ]
		  ifFalse: [ label asString ]
]

{ #category : 'pls - system' }
PLSServer >> systemLabelOfTally: aTally [
	"Answer the label of the method of aTally, as the profiler of Pharo shows it (see #systemLabelOfMethod:receiverClass:)"

	^ aTally method ifNil: [ '?' ] ifNotNil: [ :method |
		  self systemLabelOfMethod: method receiverClass: aTally theClass ]
]

{ #category : 'pls - system' }
PLSServer >> systemProcessAt: id [
	"Answer the process of the id, which is not terminated"

	^ Process allSubInstances
		  detect: [ :each |
		  each identityHash = id and: [ each isTerminated not ] ]
		  ifNone: [
		  PLSUnknownEntity signal: 'Unknown process: ' , id printString ]
]

{ #category : 'pls - system' }
PLSServer >> systemProcesses [
	"Answer the processes of the image that are not terminated, the highest priority first, with their name, priority, state and the method they run"

	<jrpc: #'pls-system:processes'>
	| ui items |
	ui := [ UIManager default uiProcess ]
		      on: Error
		      do: [ :error | nil ].
	items := (Process allSubInstances reject: [ :each |
		          each isTerminated ]) collect: [ :each |
		         self systemDescriptionOfProcess: each ui: ui ].
	^ { (#items -> (items asArray sort: [ :a :b |
			    (a at: #priority) > (b at: #priority) or: [
					    (a at: #priority) = (b at: #priority) and: [
						    (a at: #name) <= (b at: #name) ] ] ])) } asDictionary
]

{ #category : 'pls - system' }
PLSServer >> systemProfile: expression textDocumentURI: textDocumentURI [
	"Evaluate expression with the bindings of the document, as the playground does, while MessageTally samples its process every millisecond. Answer the time it took, the number of samples, the error it signalled if any, and the tree of the calls sampled from the do it, each with its samples and the samples of the method itself"

	<jrpc: #'pls-system:profile'>
	| compiler error tally milliseconds root |
	(self inspectorSyntaxErrorOf: expression) ifNotNil: [ :message |
		^ JRPCInvalidParameters signal: message ].
	compiler := self compilerFor:
		            (textDocumentURI ifNotNil: [ :uri | uri at: #path ]).
	tally := MessageTally new.
	milliseconds := Time millisecondsToRun: [
			                tally spyEvery: 1 on: [
					                [ compiler evaluate: expression ]
						                on: Error
						                do: [ :exception |
								                error := exception.
								                exception return: nil ] ] ].
	root := self systemProfileRootOf: tally.
	^ {
		  (#milliseconds -> milliseconds).
		  (#samples -> root tally).
		  (#error -> (error ifNotNil: [ error description asString ])).
		  (#root -> (self
			    systemProfileNodeOf: root
			    label: expression lines first
			    threshold: (root tally * self systemProfileThreshold) ceiling
			    depth: 0)) } asDictionary
]

{ #category : 'pls - system' }
PLSServer >> systemProfileNodeOf: aTally label: aString threshold: threshold depth: depth [
	"Answer the node of a profile for aTally, with the calls it made that were sampled at least threshold times. Under the root, a node shows its method"

	| children method |
	children := depth >= 200
		            ifTrue: [ #(  ) ]
		            ifFalse: [
				            ((aTally receivers select: [ :each |
					              each tally >= threshold ]) sort: [ :a :b |
					             a tally > b tally ]) collect: [ :each |
						            self
							            systemProfileNodeOf: each
							            label: nil
							            threshold: threshold
							            depth: depth + 1 ] ].
	method := aTally method ifNotNil: [ :compiledCode |
		          compiledCode method ].
	^ {
		  (#label -> (aString ifNil: [ self systemLabelOfTally: aTally ])).
		  (#uri -> ((aString isNil and: [
			     method notNil and: [
				     method isInstalled and: [ method isDoIt not ] ] ]) ifTrue: [
				    [ self navUriOfMethod: method ]
					    on: Error
					    do: [ :e | nil ] ])).
		  (#samples -> aTally tally).
		  (#selfSamples -> (aTally tally
		    -
		    (aTally receivers
			     inject: 0
			     into: [ :sum :each | sum + each tally ]))).
		  (#children -> children asArray) } asDictionary
]

{ #category : 'pls - system' }
PLSServer >> systemProfileRootOf: aTally [
	"Answer the tally of the do it evaluated under aTally, the root of a profile, or aTally when there is none"

	| pending |
	pending := OrderedCollection with: aTally.
	[ pending isEmpty ] whileFalse: [
			| tally |
			tally := pending removeFirst.
			(tally method notNil and: [ tally method method isDoIt ]) ifTrue: [
				^ tally ].
			pending addAll: tally receivers ].
	^ aTally
]

{ #category : 'pls - system' }
PLSServer >> systemProfileThreshold [
	"Calls sampled less than this part of all the samples are left out of a profile"

	^ 0.002
]

{ #category : 'pls - system' }
PLSServer >> systemStack: id limit: limit [
	"Answer the frames of the stack of the process of the id, the top first, at most limit of them (50 by default)"

	<jrpc: #'pls-system:stack'>
	| context frames |
	context := self systemContextOf: (self systemProcessAt: id).
	frames := context
		          ifNil: [ #(  ) ]
		          ifNotNil: [ context stackOfSize: (limit ifNil: [ 50 ]) ].
	^ { (#items -> (frames collect: [ :frame |
			    {
				    (#label -> (self systemLabelOfContext: frame)).
				    (#uri -> (self systemUriOfContext: frame)) } asDictionary ])
		   asArray) } asDictionary
]

{ #category : 'pls - system' }
PLSServer >> systemStateOf: aProcess [
	"Answer the state of aProcess: running, ready, waiting (on a semaphore), suspended or terminated"

	aProcess isTerminated ifTrue: [ ^ 'terminated' ].
	aProcess == Processor activeProcess ifTrue: [ ^ 'running' ].
	aProcess suspendingList ifNil: [ ^ 'suspended' ].
	(aProcess suspendingList isKindOf: Semaphore) ifTrue: [ ^ 'waiting' ].
	^ 'ready'
]

{ #category : 'pls - system' }
PLSServer >> systemTerminate: id [
	"Terminate the process of the id. The process that answers cannot be terminated"

	<jrpc: #'pls-system:terminate'>
	| target |
	target := self systemProcessAt: id.
	target == Processor activeProcess ifTrue: [
			^ JRPCInvalidParameters signal:
				  'The process answering the client cannot be terminated' ].
	target terminate.
	^ nil
]

{ #category : 'pls - system' }
PLSServer >> systemUriOfContext: aContext [
	"Answer the URI of the editor of the method aContext runs, or nil when the method is not installed (a do it)"

	| method |
	method := aContext method method.
	(method isInstalled and: [ method isDoIt not ]) ifFalse: [ ^ nil ].
	^ [ self navUriOfMethod: method ]
		  on: Error
		  do: [ :error | nil ]
]

{ #category : 'lsp - completion' }
PLSServer >> textDocumentCompletionWithContext: context position: position textDocument: textDocument [

	<jrpc: #'textDocument/completion'>
	| completionList completionTool document |
	document := self context textItem: (textDocument at: #uri).
	completionTool := PLSCompletion new
		                  source: document text;
		                  position: position;
		                  yourself.
	(PLSDocument isTonelDocument: textDocument)
		ifTrue: [
				completionTool sourceClass:
					(([ PLSTonelParser parseString: document text ]
						  on: Error
						  do: [ ^ {  } ]) detect: #isClassDefinition) actualClass ]
		ifFalse: [
				completionTool
					sourceClass: document completionClass;
					sourceIsMethod: document isMethodSource ].
	completionList := PLSCompletionList new.
	completionList completionItems: completionTool entries asArray.
	^ completionList
]

{ #category : 'lsp - hover' }
PLSServer >> textDocumentHoverWithPosition: position textDocument: textDocument [
	<jrpc: #'textDocument/hover'>
	| hover document |
	document := (self context textItem: (textDocument at: #uri)). 
	hover := PLSHover new
		context: self context;
		source: document;
		position: position;
		yourself.
	^ { #contents -> hover contents } asDictionary
]

{ #category : 'lsp - navigation' }
PLSServer >> textDocumentImplementationWithPosition: position textDocument: textDocument [
	"Answer the implementors of the selector at position, or the subclasses and users of the class or trait at position"

	<jrpc: #'textDocument/implementation'>
	| target |
	target := self
		          navTargetIn:
		          (self context textItem: (textDocument at: #uri))
		          at: position.
	target ifNil: [ ^ #(  ) ].
	(target at: #kind) = #selector ifTrue: [
		^ (self navImplementorsOf: (target at: #name)) asArray ].
	(target at: #kind) = #class ifTrue: [
			^ ((self navSubtypesOf: (target at: #class) deep: true) collect: [
				   :class | self navLocationOfClass: class ]) asArray ].
	^ #(  )
]

{ #category : 'lsp - completion' }
PLSServer >> textDocumentInlineCompletionWithContext: context position: position textDocument: textDocument [

	<jrpc: #'textDocument/inlineCompletion'>
	| internalTextDocument api answer userPosition result |
	internalTextDocument := self context textItem:
		                        (textDocument at: #uri).
	userPosition := internalTextDocument text plsToPosition: position.
	api := LLMAPI fim.
	api host: 'api.mistral.ai'.

	api payload
		temperature: 0.2;
		model: 'codestral-2501';
		top_p: 1;
		max_tokens: 250;
		prompt: (internalTextDocument text copyFrom: 1 to: userPosition).
	userPosition = internalTextDocument text size ifFalse: [
		api payload suffix: (internalTextDocument text
				 copyFrom: userPosition
				 to: internalTextDocument text size) ].

	result := api performRequest.
	answer := result choices anyOne message content.

	^ (PLSInlineCompletionList new
		   items: { (PLSInlineCompletionItem new insertText:
					    (self postDealAnswer: answer)) };
		   yourself) asJRPCJSON
]

{ #category : 'lsp - navigation' }
PLSServer >> textDocumentReferencesWithPosition: position textDocument: textDocument context: context [
	"Answer the locations where the entity at position is used: the senders of a selector, the references to a class or variable.
	 They are located in the editors of the methods, except the uses of a temporary, which stay in textDocument"

	<jrpc: #'textDocument/references'>
	| target locations |
	target := self
		          navTargetIn:
		          (self context textItem: (textDocument at: #uri))
		          at: position.
	target ifNil: [ ^ #(  ) ].
	(target at: #kind) = #temp ifTrue: [
		^ self navTempLocationsOf: target in: (textDocument at: #uri) ].
	locations := OrderedCollection new.
	(context notNil and: [
		 context at: #includeDeclaration ifAbsent: [ false ] ]) ifTrue: [
		locations addAll: (self navDeclarationsOf: target) ].
	locations addAll: (self
			 navLocationsIn: (self navReferencingMethodsOf: target)
			 where: (self navMatcherOf: target)).
	^ locations asArray
]

{ #category : 'lsp - signature help' }
PLSServer >> textDocumentSignatureHelpWithPosition: position textDocument: textDocument anContext: context [
	<jrpc: #'textDocument/signatureHelp'>
	| text positionChar selector node |
	text := (self context textItem: (textDocument at: #uri)) text.
	positionChar := text plsToPosition: position.
	node := (RBParser parseFaultyExpression: text)
		bestNodeFor: (Interval from: positionChar to: positionChar).
	"Node can be nil with this piece of code: `true :` (the ':' is not correctly parsed, so node becomes nil)"
	selector := (node isNotNil and: [ node isMessage ])
		ifTrue: [ node selector ]
		ifFalse: [ '' ].
	^ PLSSignatureHelp new
		signatures:
			((SystemNavigation new allImplementorsOf: selector)
				collect: [ :implementor | 
					PLSSignatureInformation new
						label: implementor printString;
						documentation: implementor compiledMethod comment;
						parameters:
							(implementor argumentNames
								collect: [ :name | 
									PLSParameterInformation new
										label: name;
										yourself ]
								as: Array);
						yourself ]
				as: Array);
		yourself
]

{ #category : 'pls - playground' }
PLSServer >> transcriptShow: aString [

	clientOutStream ifNil: [ ^ self ].
	self
		sendNotification: 'pls/transcript'
		params: { (#text -> aString asString) } asDictionary
]

{ #category : 'pls - playground' }
PLSServer >> transcriptSubscribe [
	"Send what is shown on the Transcript to the client in pls/transcript notifications.
	 The entries are announced in the process of the Transcript, so sending one never signals an error into the process that shows it"

	self transcriptUnsubscribe.
	transcriptSubscription := SystemAnnouncer uniqueInstance
		                          when: NewEntryToTranscript
		                          do: [ :announcement |
				                          [
				                          self transcriptShow: announcement entry ]
					                          on: Error
					                          do: [ :error | error return: nil ] ]
		                          for: Transcript
]

{ #category : 'pls - playground' }
PLSServer >> transcriptUnsubscribe [

	transcriptSubscription ifNotNil: [ :subscription |
		SystemAnnouncer uniqueInstance removeSubscription: subscription ].
	transcriptSubscription := nil
]

{ #category : 'lsp - type definition' }
PLSServer >> typeDefinitionAt: position in: textDocument [

	<jrpc: #'textDocument/typeDefinition'>
	| document canBeClass aClass |
	document := self context textItem: (textDocument at: #uri).
	canBeClass := document nodeAt: position.
	canBeClass ifNil: [ ^ {  } ].
	((canBeClass isKindOf: RBProgramNode) not or: [ 
		 canBeClass isVariable not ]) ifTrue: [ ^ {  } ].
	aClass := self class environment
		          at: canBeClass name asSymbol
		          ifAbsent: [ ^ {  } ].
	aClass isClass ifFalse: [ ^ {  } ].
	^ PLSLocation new
		  uri: aClass plsURIString;
		  range: (PLSRange
				   start: (PLSPosition line: 0 character: 0)
				   end: (PLSPosition line: 0 character: 0));
		  yourself
]

{ #category : 'lsp - navigation' }
PLSServer >> typeHierarchyPrepareWithPosition: position textDocument: textDocument [
	"Answer the item of the class at position, or of the class the document is about"

	<jrpc: #'textDocument/prepareTypeHierarchy'>
	^ (self
		   navClassOf: (self context textItem: (textDocument at: #uri))
		   at: position)
		  ifNil: [ #(  ) ]
		  ifNotNil: [ :class | { (self navTypeItemOf: class) } ]
]

{ #category : 'lsp - navigation' }
PLSServer >> typeHierarchySubtypes: item [
	"Answer the subclasses of the class of item, or the classes that use the trait of item"

	<jrpc: #'typeHierarchy/subtypes'>
	^ (self navClassOfItem: item) ifNil: [ #(  ) ] ifNotNil: [ :class |
			  ((self navSubtypesOf: class deep: false) collect: [ :each |
				   self navTypeItemOf: each ]) asArray ]
]

{ #category : 'lsp - navigation' }
PLSServer >> typeHierarchySupertypes: item [
	"Answer the superclass of the class of item, then the traits it uses"

	<jrpc: #'typeHierarchy/supertypes'>
	| class supertypes |
	class := self navClassOfItem: item.
	class ifNil: [ ^ #(  ) ].
	supertypes := OrderedCollection new.
	class isTrait ifFalse: [
		class superclass ifNotNil: [ :superclass |
			supertypes add: superclass ] ].
	supertypes addAll:
		(class traits asArray sort: [ :a :b | a name <= b name ]).
	^ (supertypes collect: [ :each | self navTypeItemOf: each ]) asArray
]

{ #category : 'pls - ui' }
PLSServer >> uiBrowseClass: aClass selector: aSelectorOrNil [
	"Open the editor of aClass, or of its method aSelectorOrNil when it has one, in the client"

	| uri |
	uri := (aSelectorOrNil notNil and: [
		        aClass includesSelector: aSelectorOrNil ])
		       ifTrue: [ self navUriOfMethod: aClass >> aSelectorOrNil ]
		       ifFalse: [ self navUriOfClass: aClass ].
	self
		showDocument: uri
		external: false
		withFocus: true
		atRange: nil
]

{ #category : 'pls - ui' }
PLSServer >> uiEnabledIn: initializationOptions [
	"The client shows the tools and the questions of the image only when it says so (initializationOptions.ui.version), since an older client would not answer them"

	| options |
	initializationOptions isDictionary ifFalse: [ ^ false ].
	options := initializationOptions at: #ui ifAbsent: [ ^ false ].
	options isDictionary ifFalse: [ ^ false ].
	^ (options at: #version ifAbsent: [ 0 ]) isInteger and: [
		  (options at: #version) >= 1 ]
]

{ #category : 'pls - ui' }
PLSServer >> uiForwards [
	"Whether the tools and the questions of the image go to the client"

	^ uiEnabled == true and: [ self debugMode not ]
]

{ #category : 'pls - ui' }
PLSServer >> uiInspect: anObject label: aStringOrNil [
	"Open the Inspector view of the client on anObject. The client releases the reference when it closes the page"

	self sendNotification: 'pls-ui/inspect' params: {
			(#ref -> (self inspectorRegister: anObject)).
			(#label -> (aStringOrNil ifNotNil: [ :label | label asString ])) }
			asDictionary
]

{ #category : 'pls - ui' }
PLSServer >> uiInstallTools [
	"Register the tools that open the views of the client, keeping the original ones to restore them"

	| registry |
	registry := Smalltalk tools.
	uiPreviousTools := Dictionary new.
	self uiToolClasses keysAndValuesDo: [ :role :toolClass |
			| original |
			original := [ registry toolNamed: role ]
				            on: Error
				            do: [ :error | error return: nil ].
			(original isKindOf: PLSClientTool) ifTrue: [
				original := original originalTool ].
			uiPreviousTools at: role put: original.
			registry
				register: (toolClass on: self replacing: original)
				as: role ]
]

{ #category : 'pls - ui' }
PLSServer >> uiJobChanged: aJobChange [
	"Report the job to the client when its percentage or its title changed, so that a job counting fast sends a hundred reports at most"

	| job state percentage |
	job := aJobChange job.
	state := self uiProgressAt: job ifAbsent: [ ^ self ].
	percentage := self uiPercentageOf: job.
	(percentage = (state at: 2) and: [ job title = (state at: 3) ])
		ifTrue: [ ^ self ].
	state
		at: 2 put: percentage;
		at: 3 put: job title.
	self uiSendProgress: (state at: 1) value: {
			(#kind -> 'report').
			(#message -> (job title ifNil: [ '' ]) asString).
			(#percentage -> percentage) } asDictionary
]

{ #category : 'pls - ui' }
PLSServer >> uiJobEnded: aJobEnd [

	| state |
	state := self uiProgressRemove: aJobEnd job ifAbsent: [ ^ self ].
	self
		uiSendProgress: (state at: 1)
		value: { (#kind -> 'end') } asDictionary
]

{ #category : 'pls - ui' }
PLSServer >> uiJobStarted: aJobStart [
	"Create a progress in the client for the job; the job waits for the client to create it"

	| job token created |
	job := aJobStart job.
	token := 'pls-job-' , job identityHash printString.
	created := [
		           self
			           sendRequestAndWait: 'window/workDoneProgress/create'
			           params: { (#token -> token) } asDictionary
		           timeout: 2 seconds.
		           true ]
		           on: PLSClientRequestFailed
		           do: [ :error | error return: false ].
	created ifFalse: [ ^ self ].
	(self
		 uiProgressAt: job
		 put:
		 (Array with: token with: (self uiPercentageOf: job) with: job title))
		ifFalse: [ ^ self ].
	self uiSendProgress: token value: {
			(#kind -> 'begin').
			(#title -> (job title ifNil: [ '' ]) asString).
			(#percentage -> (self uiPercentageOf: job)) } asDictionary
]

{ #category : 'pls - ui' }
PLSServer >> uiPercentageOf: aJob [
	"The percentage of aJob done, from 0 to 100, or nil when it has no range"

	| min max current |
	min := aJob min.
	max := aJob max.
	current := aJob currentValue.
	(min isNumber and: [ max isNumber and: [ current isNumber and: [ max > min ] ] ])
		ifFalse: [ ^ nil ].
	^ (((current - min) / (max - min) * 100) rounded max: 0) min: 100
]

{ #category : 'pls - ui' }
PLSServer >> uiProgressAt: aJob ifAbsent: aBlock [

	| mutex |
	mutex := uiProgressMutex ifNil: [ ^ aBlock value ].
	^ mutex critical: [
			  (uiProgressTokens ifNil: [ ^ aBlock value ])
				  at: aJob
				  ifAbsent: [ ^ aBlock value ] ]
]

{ #category : 'pls - ui' }
PLSServer >> uiProgressAt: aJob put: aState [
	"Answer false when the progress stopped meanwhile"

	| mutex |
	mutex := uiProgressMutex ifNil: [ ^ false ].
	^ mutex critical: [
			  uiProgressTokens ifNil: [ false ] ifNotNil: [ :tokens |
					  tokens at: aJob put: aState.
					  true ] ]
]

{ #category : 'pls - ui' }
PLSServer >> uiProgressRemove: aJob ifAbsent: aBlock [

	| mutex |
	mutex := uiProgressMutex ifNil: [ ^ aBlock value ].
	^ mutex critical: [
			  (uiProgressTokens ifNil: [ ^ aBlock value ])
				  removeKey: aJob
				  ifAbsent: [ ^ aBlock value ] ]
]

{ #category : 'pls - ui' }
PLSServer >> uiRequest: aMethodString params: aDictionary [
	"Ask the client aMethodString and answer its answer, or nil when the user cancelled or the client could not answer"

	^ [ self sendRequestAndWait: aMethodString params: aDictionary ]
		  on: PLSClientRequestFailed
		  do: [ :error |
				  self record: aMethodString , ' failed: ' , error messageText.
				  error return: nil ]
]

{ #category : 'pls - ui' }
PLSServer >> uiRestoreTools [
	"Put back the tools that were registered before #uiInstallTools, when ours are still registered"

	| registry |
	uiPreviousTools ifNil: [ ^ self ].
	registry := Smalltalk tools.
	uiPreviousTools keysAndValuesDo: [ :role :original |
			| current |
			current := [ registry toolNamed: role ]
				           on: Error
				           do: [ :error | error return: nil ].
			((current isKindOf: PLSClientTool) and: [ original notNil ])
				ifTrue: [ registry register: original as: role ] ].
	uiPreviousTools := nil
]

{ #category : 'pls - ui' }
PLSServer >> uiSendProgress: aToken value: aDictionary [

	self sendNotification: '$/progress' params: {
			(#token -> aToken).
			(#value -> aDictionary) } asDictionary
]

{ #category : 'pls - ui' }
PLSServer >> uiStartProgress [
	"Report the jobs of the image (Job, displayProgress:from:to:during:) as work done progress of the client"

	self uiStopProgress.
	uiProgressMutex := Mutex new.
	uiProgressTokens := IdentityDictionary new.
	Job jobAnnouncer
		when: JobStart send: #uiJobStarted: to: self;
		when: JobChange send: #uiJobChanged: to: self;
		when: JobEnd send: #uiJobEnded: to: self
]

{ #category : 'pls - ui' }
PLSServer >> uiStartWith: initializationOptions [
	"Let the client show the tools, the questions and the progress of the image when it asked for it and the server is not in debug mode, where they stay in Pharo. Answer the capability to announce, or nil"

	self uiStop.
	uiEnabled := (self uiEnabledIn: initializationOptions) and: [
		             self debugMode not ].
	uiEnabled ifFalse: [ ^ nil ].
	self uiInstallTools.
	self uiStartProgress.
	^ { (#version -> 1) } asDictionary
]

{ #category : 'pls - ui' }
PLSServer >> uiStop [
	"Give the tools back to Pharo and stop reporting the progress"

	self uiRestoreTools.
	self uiStopProgress.
	uiEnabled := false
]

{ #category : 'pls - ui' }
PLSServer >> uiStopProgress [

	Job jobAnnouncer unsubscribe: self.
	uiProgressTokens := nil
]

{ #category : 'pls - ui' }
PLSServer >> uiToolClasses [
	"The tools of the image (Smalltalk tools) the client shows, by role"

	^ {
		  (#inspector -> PLSInspectorTool).
		  (#browser -> PLSBrowserTool) } asDictionary
]

{ #category : 'lsp - workspace symbol' }
PLSServer >> workspaceSymbol: query [
	"Answer the classes and methods that match query, as pls-env:search finds them, located in the editors of the entities"

	<jrpc: #'workspace/symbol'>
	(query isNil or: [ query trimBoth isEmpty ]) ifTrue: [ ^ #(  ) ].
	^ ((self envSearch: query kinds: #( 'class' 'method' ) limit: 100)
		   at: #items) collect: [ :item | self envSymbolOf: item ]
]
