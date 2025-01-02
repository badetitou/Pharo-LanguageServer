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
	#name : 'PLCDummyServerConfigurationRunner',
	#superclass : 'PLCServerConfigurationRunner',
	#category : 'PharoLanguageProtocol-Tests',
	#package : 'PharoLanguageProtocol-Tests'
}

{ #category : 'as yet unclassified' }
PLCDummyServerConfigurationRunner class >> supportedLanguages [

	^ { #dummy }
]

{ #category : 'testing' }
PLCDummyServerConfigurationRunner >> isTCPHost [

	^ false
]
