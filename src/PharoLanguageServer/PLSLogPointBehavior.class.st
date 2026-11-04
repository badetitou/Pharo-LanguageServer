"
I turn a breakpoint into a logpoint, as the log message of a breakpoint of VS Code: when the debug point is hit, I write my message on the Transcript, each `{expression}` replaced by the print string of the expression evaluated in the context of the hit, and the debug point does not stop.
"
Class {
	#name : 'PLSLogPointBehavior',
	#superclass : 'DebugPointCheckBehavior',
	#instVars : [
		'message'
	],
	#category : 'PharoLanguageServer-Debug',
	#package : 'PharoLanguageServer',
	#tag : 'Debug'
}

{ #category : 'execution' }
PLSLogPointBehavior >> execute [
	"Write the message on the Transcript. Answer false: a logpoint never stops"

	Transcript
		show: (self textIn: (self getArgument: #context));
		cr.
	^ false
]

{ #category : 'initialization' }
PLSLogPointBehavior >> initialize [

	super initialize.
	self priority: 10
]

{ #category : 'accessing' }
PLSLogPointBehavior >> message [

	^ message
]

{ #category : 'accessing' }
PLSLogPointBehavior >> message: aString [

	message := aString
]

{ #category : 'execution' }
PLSLogPointBehavior >> printStringOf: anExpression in: aContext [

	^ [
		  (Smalltalk compiler
			   source: anExpression;
			   context: aContext;
			   receiver: aContext receiver;
			   bindings: { (#thisContext -> aContext) };
			   evaluate) printString ]
		  on: Error
		  do: [ :error | '<' , error description , '>' ]
]

{ #category : 'execution' }
PLSLogPointBehavior >> textIn: aContext [
	"My message, each {expression} replaced by the print string of its value in aContext"

	^ String streamContents: [ :stream |
			  | rest |
			  rest := message.
			  [ rest includes: ${ ] whileTrue: [
					  | open close |
					  open := rest indexOf: ${.
					  close := rest indexOf: $} startingAt: open.
					  close = 0
						  ifTrue: [
								  stream nextPutAll: rest.
								  rest := '' ]
						  ifFalse: [
								  stream nextPutAll: (rest copyFrom: 1 to: open - 1).
								  stream nextPutAll: (self
										   printStringOf: (rest copyFrom: open + 1 to: close - 1)
										   in: aContext).
								  rest := rest allButFirst: close ] ].
			  stream nextPutAll: rest ]
]
