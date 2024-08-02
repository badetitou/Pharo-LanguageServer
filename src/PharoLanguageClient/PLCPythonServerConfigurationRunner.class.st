"
# Python server

## Installation

First install the python server locally with 

```sh
npm install -g pyright
```
"
Class {
	#name : 'PLCPythonServerConfigurationRunner',
	#superclass : 'PLCServerConfigurationRunner',
	#category : 'PharoLanguageClient',
	#package : 'PharoLanguageClient'
}

{ #category : 'as yet unclassified' }
PLCPythonServerConfigurationRunner class >> supportedLanguages [

	^ { #python }
]

{ #category : 'visiting' }
PLCPythonServerConfigurationRunner >> visitWindows: aPlatform [

	^ LibC runCommand: (String streamContents: [ :stream |
			   stream << 'start powershell -noexit -noprofil -command "& { '.
			   stream << 'pyright-langserver.cmd --socket='.
			   self tcpPort printOn: stream.
			   stream << ' }"' ])
]
