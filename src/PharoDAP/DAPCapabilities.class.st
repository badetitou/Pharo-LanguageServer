Class {
	#name : #DAPCapabilities,
	#superclass : #DAPJsonableObject,
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
	#category : #'PharoDAP-Types'
}

{ #category : #converting }
DAPCapabilities >> asDAPJSON [
	| dic |
	dic := super asDAPJSON.
	self supportsDelayedStackTraceLoading
		ifNotNil: [ dic
				at: #supportsDelayedStackTraceLoading
				put: self supportsDelayedStackTraceLoading ].
	^ dic
]

{ #category : #initialization }
DAPCapabilities >> initialize [
	super initialize.
	supportsDelayedStackTraceLoading := true.
]

{ #category : #accessing }
DAPCapabilities >> supportsDelayedStackTraceLoading [
	^ supportsDelayedStackTraceLoading
]

{ #category : #accessing }
DAPCapabilities >> supportsDelayedStackTraceLoading: anObject [
	supportsDelayedStackTraceLoading := anObject
]
