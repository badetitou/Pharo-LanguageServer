"
I test that PLSServer starts the MCP server of evref-BL/MCP on initialize, announces its endpoint to the client, lets the client disable it, and stops it with the language server.
"
Class {
	#name : 'PLSServerMCPTest',
	#superclass : 'TestCase',
	#instVars : [
		'server'
	],
	#category : 'PharoLanguageServer-MCP-Tests',
	#package : 'PharoLanguageServer-MCP-Tests'
}

{ #category : 'running' }
PLSServerMCPTest >> initializeWith: initializationOptions [

	^ (server
		   onInitializeTrace: nil
		   processId: nil
		   locale: nil
		   clientInfo: nil
		   rootPath: nil
		   workspaceFolders: nil
		   capabilities: Dictionary new
		   rootUri: nil
		   initializationOptions: initializationOptions) asJRPCJSON at:
		  #capabilities
]

{ #category : 'running' }
PLSServerMCPTest >> setUp [

	super setUp.
	server := PLSServer new
]

{ #category : 'running' }
PLSServerMCPTest >> tearDown [

	server mcpStop.
	super tearDown
]

{ #category : 'tests' }
PLSServerMCPTest >> testInitializeAgainReplacesTheMCPServer [

	| first |
	self initializeWith: nil.
	first := PLSMCPEndpoint started detect: [ :each |
		         each url = (server mcpEndpoint at: #url) ].
	self initializeWith: nil.
	self deny: first isRunning.
	self assert: server mcpEndpoint notNil
]

{ #category : 'tests' }
PLSServerMCPTest >> testInitializeAnnouncesTheMCPServer [

	| mcp |
	mcp := (self initializeWith: nil) at: #experimental at: #mcp.
	self assert: (server mcpEndpoint at: #url) equals: (mcp at: #url).
	self assert: ((mcp at: #url) beginsWith: 'http://127.0.0.1:').
	self assert:
		((mcp at: #protocolVersions) includes: MCP latestProtocolVersion)
]

{ #category : 'tests' }
PLSServerMCPTest >> testInitializeKeepsTheEnvironmentCapabilities [

	self assert:
		(((self initializeWith: nil) at: #experimental) includesKey:
			 #'pls-env')
]

{ #category : 'tests' }
PLSServerMCPTest >> testInitializeStartsTheMCPServerOnAFreePort [

	| port |
	self initializeWith: nil.
	port := ((server mcpEndpoint at: #url) copyAfterLast: $:) allButLast
		        asNumber.
	self deny: port equals: 4000.
	self assert: (MCP allServers anySatisfy: [ :each |
			 each port = port and: [ each isRunning ] ])
]

{ #category : 'tests' }
PLSServerMCPTest >> testStopStopsTheMCPServer [

	| endpoint |
	self initializeWith: nil.
	endpoint := PLSMCPEndpoint started detect: [ :each |
		            each url = (server mcpEndpoint at: #url) ].
	server mcpStop.
	self deny: endpoint isRunning.
	self deny: (PLSMCPEndpoint started includes: endpoint).
	self assert: server mcpEndpoint isNil
]

{ #category : 'tests' }
PLSServerMCPTest >> testTheClientCanDisableTheMCPServer [

	| capabilities |
	capabilities := self initializeWith:
		                { (#mcp -> { (#enabled -> false) } asDictionary) }
			                asDictionary.
	self deny: ((capabilities at: #experimental) includesKey: #mcp).
	self assert: server mcpEndpoint isNil
]

{ #category : 'tests' }
PLSServerMCPTest >> testTheMCPServerStartsWithOtherOptions [

	self initializeWith:
		{ (#mcp -> { (#enabled -> true) } asDictionary) } asDictionary.
	self assert: server mcpEndpoint notNil.
	server mcpStop.
	self initializeWith: { (#other -> 1) } asDictionary.
	self assert: server mcpEndpoint notNil
]

{ #category : 'tests' }
PLSServerMCPTest >> testTwoServersHaveTheirOwnMCPServer [

	| other |
	other := PLSServer new.
	[
		self initializeWith: nil.
		other
			onInitializeTrace: nil
			processId: nil
			locale: nil
			clientInfo: nil
			rootPath: nil
			workspaceFolders: nil
			capabilities: Dictionary new
			rootUri: nil
			initializationOptions: nil.
		self
			deny: (server mcpEndpoint at: #url)
			equals: (other mcpEndpoint at: #url) ] ensure: [ other mcpStop ]
]
