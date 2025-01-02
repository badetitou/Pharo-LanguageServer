"
# Python server

## Installation

First install the python server locally with 

```sh
pip install python-lsp-server
pip install 'python-lsp-server[websockets]'
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

{ #category : 'testing' }
PLCPythonServerConfigurationRunner >> isTCPHost [

	^ false
]

{ #category : 'as yet unclassified' }
PLCPythonServerConfigurationRunner >> visitWindows: aPlatform [

	^ LibC runCommand: (String streamContents: [ :stream |
			   stream << 'start powershell -noexit -noprofil -command "& { '.
			   stream << 'pylsp --tcp -vv --port '.
			   self tcpPort printOn: stream.
			   stream << ' }"' ])
]
