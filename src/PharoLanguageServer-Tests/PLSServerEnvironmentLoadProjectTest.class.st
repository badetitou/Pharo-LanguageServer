"
I test pls-env:loadProject: finding the sources of a working copy and refusing what cannot be loaded. Loading a real baseline needs a git working copy and Metacello, so it is checked by hand (see docs/environment-model.md of vscode-pharo).
"
Class {
	#name : 'PLSServerEnvironmentLoadProjectTest',
	#superclass : 'TestCase',
	#instVars : [
		'server',
		'directory'
	],
	#category : 'PharoLanguageServer-Tests',
	#package : 'PharoLanguageServer-Tests'
}

{ #category : 'running' }
PLSServerEnvironmentLoadProjectTest >> setUp [

	super setUp.
	server := PLSServer new.
	directory := FileSystem memory root / 'project'.
	directory ensureCreateDirectory
]

{ #category : 'tests' }
PLSServerEnvironmentLoadProjectTest >> testCapabilitiesAnnounceLoadProject [

	self assert:
		((PLSServerCapabilities forPharo experimental at: #'pls-env') at:
			 #loadProject)
]

{ #category : 'tests' }
PLSServerEnvironmentLoadProjectTest >> testLoadFailureIsAnInternalError [

	| response |
	response := (PLSProjectLoadFailed new messageText: 'boom')
		            asJRPCResponseWithId: 1.
	self
		assert: response error code
		equals: JRPCErrorObject internalError code.
	self assert: response error message equals: 'boom'
]

{ #category : 'tests' }
PLSServerEnvironmentLoadProjectTest >> testLoadingAFolderWithoutTheBaselineFailsWithItsName [

	| error |
	error := [
		         server
			         envLoadProject: FileLocator imageDirectory fullName
			         baseline: 'BaselineOfPLSNoSuchProject'
			         groups: nil.
		         nil ]
		         on: PLSProjectLoadFailed
		         do: [ :e | e ].
	self assert:
		(error messageText includesSubstring: 'BaselineOfPLSNoSuchProject')
]

{ #category : 'tests' }
PLSServerEnvironmentLoadProjectTest >> testLoadingAMissingFolderFails [

	self
		should: [
				server
					envLoadProject: (directory / 'missing') fullName
					baseline: 'Foo'
					groups: nil ]
		raise: PLSProjectLoadFailed
]

{ #category : 'tests' }
PLSServerEnvironmentLoadProjectTest >> testSourceDirectoryFollowsTheProjectFile [

	directory / '.project' writeStreamDo: [ :stream |
		stream nextPutAll: '{ ''srcDirectory'' : ''src'' }' ].
	self
		assert: (server envSourceDirectoryOf: directory)
		equals: directory / 'src'
]

{ #category : 'tests' }
PLSServerEnvironmentLoadProjectTest >> testSourceDirectoryIgnoresAnUnreadableProjectFile [

	directory / '.project' writeStreamDo: [ :stream |
		stream nextPutAll: 'not ston {' ].
	self
		assert: (server envSourceDirectoryOf: directory)
		equals: directory
]

{ #category : 'tests' }
PLSServerEnvironmentLoadProjectTest >> testSourceDirectoryIsTheWorkingCopyWithoutProjectFile [

	self
		assert: (server envSourceDirectoryOf: directory)
		equals: directory
]
