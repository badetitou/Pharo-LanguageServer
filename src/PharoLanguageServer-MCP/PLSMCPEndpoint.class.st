"
I am the MCP server of evref-BL/MCP that a Pharo Language Server starts in its image, so that agents (Copilot, Claude Code, Codex, OpenCode...) work on the same image as the editor.

I listen on the loopback, on a free port chosen by the system: several images can run at the same time, each exposing its own server. The language server describes my endpoint to its client in the capabilities answered to initialize (experimental.mcp), and on the pls:mcpEndpoint request.

My class remembers the servers it started. A saved image restarts them by itself on their old port, so #stopAll stops them before a new language server starts its own.
"
Class {
	#name : 'PLSMCPEndpoint',
	#superclass : 'Object',
	#instVars : [
		'mcp'
	],
	#classInstVars : [
		'started'
	],
	#category : 'PharoLanguageServer-MCP',
	#package : 'PharoLanguageServer-MCP'
}

{ #category : 'instance creation' }
PLSMCPEndpoint class >> start [
	"Answer a new endpoint, listening on a free port"

	^ self new
		  start;
		  yourself
]

{ #category : 'accessing' }
PLSMCPEndpoint class >> started [
	"The endpoints started and not stopped yet, including the ones a saved image restarted"

	^ started ifNil: [ started := IdentitySet new ]
]

{ #category : 'stopping' }
PLSMCPEndpoint class >> stopAll [

	self started copy do: [ :each | each stop ]
]

{ #category : 'converting' }
PLSMCPEndpoint >> asJRPCJSON [

	^ {
		  (#url -> self url).
		  (#protocolVersions -> self protocolVersions) } asDictionary
]

{ #category : 'starting' }
PLSMCPEndpoint >> isRunning [

	^ mcp notNil and: [ mcp isRunning ]
]

{ #category : 'accessing' }
PLSMCPEndpoint >> port [

	^ mcp port
]

{ #category : 'accessing' }
PLSMCPEndpoint >> protocolVersions [

	^ MCP supportedProtocolVersions asArray
]

{ #category : 'starting' }
PLSMCPEndpoint >> start [
	"Port 0 lets the system choose a free port, and always makes a new server"

	mcp := MCP startOnPort: 0.
	self class started add: self
]

{ #category : 'starting' }
PLSMCPEndpoint >> stop [

	mcp ifNil: [ ^ self ].
	[ mcp stop ] ensure: [
			self class started remove: self ifAbsent: [ ].
			mcp := nil ]
]

{ #category : 'accessing' }
PLSMCPEndpoint >> url [
	"The server listens on 127.0.0.1 only: naming localhost could reach ::1 first"

	^ 'http://127.0.0.1:' , self port asString , '/'
]
