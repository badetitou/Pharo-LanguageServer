Class {
	#name : #DAPInitializeRequestArguments,
	#superclass : #DAPJsonableObject,
	#instVars : [
		'clientID',
		'clientName',
		'adapterID',
		'locale',
		'linesStartAt1',
		'columnsStartAt1',
		'pathFormat',
		'supportsVariableType',
		'supportsVariablePaging',
		'supportsRunInTerminalRequest',
		'supportsMemoryReferences',
		'supportsProgressReporting',
		'supportsInvalidatedEvent'
	],
	#category : #'PharoDAP-Structure'
}
