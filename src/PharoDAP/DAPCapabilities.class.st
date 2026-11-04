Class {
	#name : 'DAPCapabilities',
	#superclass : 'DAPJsonableObject',
	#instVars : [
		'supportsConfigurationDoneRequest',
		'supportsFunctionBreakpoints',
		'supportsConditionalBreakpoints',
		'supportsHitConditionalBreakpoints',
		'supportsEvaluateForHovers',
		'exceptionBreakpointFilters',
		'supportsStepBack',
		'supportsSetVariable',
		'supportsRestartFrame',
		'supportsGotoTargetsRequest',
		'supportsStepInTargetsRequest',
		'supportsCompletionsRequest',
		'completionTriggerCharacters',
		'supportsModulesRequest',
		'additionalModuleColumns',
		'supportedChecksumAlgorithms',
		'supportsRestartRequest',
		'supportsExceptionOptions',
		'supportsValueFormattingOptions',
		'supportsExceptionInfoRequest',
		'supportTerminateDebuggee',
		'supportsDelayedStackTraceLoading',
		'supportsLoadedSourcesRequest',
		'supportsLogPoints',
		'supportsTerminateThreadsRequest',
		'supportsSetExpression',
		'supportsTerminateRequest',
		'supportsDataBreakpoints',
		'supportsReadMemoryRequest',
		'supportsDisassembleRequest',
		'supportsCancelRequest',
		'supportsBreakpointLocationsRequest',
		'supportsClipboardContext',
		'supportsSteppingGranularity',
		'supportsInstructionBreakpoints',
		'supportsExceptionFilterOptions'
	],
	#category : 'PharoDAP-Types',
	#package : 'PharoDAP',
	#tag : 'Types'
}

{ #category : 'accessing' }
DAPCapabilities class >> exceptionBreakpointFilters [
	"The exception filters of the client: which unhandled exceptions of the image stop for its debugger (see PLSServer>>#debugShouldStopOn:). A breakpoint always stops"

	^ {
		  {
			  (#filter -> 'error').
			  (#label -> 'Unhandled Errors').
			  (#description
			   ->
			   'Stop on the errors and warnings nobody handles. The condition names the classes of the errors that stop, separated by commas.').
			  (#default -> true).
			  (#supportsCondition -> true).
			  (#conditionDescription
			   -> 'Classes of the errors, such as ZeroDivide, KeyNotFound') }
			  asDictionary.
		  {
			  (#filter -> 'messageNotUnderstood').
			  (#label -> 'Message Not Understood').
			  (#description
			   ->
			   'Stop on the messages not understood nobody handles, even when Unhandled Errors is off.').
			  (#default -> false) } asDictionary.
		  {
			  (#filter -> 'halt').
			  (#label -> 'Halts').
			  (#description -> 'Stop on self halt and Halt now.').
			  (#default -> true) } asDictionary.
		  {
			  (#filter -> 'deprecation').
			  (#label -> 'Deprecations').
			  (#description -> 'Stop when a deprecated method is called.').
			  (#default -> false) } asDictionary }
]

{ #category : 'converting' }
DAPCapabilities >> asDAPJSON [

	| dic |
	dic := super asDAPJSON.
	self supportsDelayedStackTraceLoading ifNotNil: [
			dic
				at: #supportsDelayedStackTraceLoading
				put: self supportsDelayedStackTraceLoading ].
	dic at: #supportTerminateDebuggee put: true.
	"What the debugger of a process stopped on an exception does"
	dic at: #supportsRestartFrame put: true.
	dic at: #supportsExceptionInfoRequest put: true.
	dic at: #supportsEvaluateForHovers put: true.
	dic at: #supportsTerminateThreadsRequest put: true.
	"The breakpoints, debug points of the image"
	dic at: #supportsConditionalBreakpoints put: true.
	dic at: #supportsHitConditionalBreakpoints put: true.
	dic at: #supportsLogPoints put: true.
	dic at: #supportsFunctionBreakpoints put: true.
	dic at: #supportsExceptionFilterOptions put: true.
	dic
		at: #exceptionBreakpointFilters
		put: self class exceptionBreakpointFilters.
	^ dic
]

{ #category : 'initialization' }
DAPCapabilities >> initialize [

	super initialize.
	supportsDelayedStackTraceLoading := true.
	supportsConfigurationDoneRequest := true.
	supportsDataBreakpoints := true.
	supportsConditionalBreakpoints := true
]

{ #category : 'accessing' }
DAPCapabilities >> supportsDelayedStackTraceLoading [
	^ supportsDelayedStackTraceLoading
]

{ #category : 'accessing' }
DAPCapabilities >> supportsDelayedStackTraceLoading: anObject [
	supportsDelayedStackTraceLoading := anObject
]
