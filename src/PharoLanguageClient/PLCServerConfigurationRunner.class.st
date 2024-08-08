"
Use me to start already installed server from pharo (usefull when creating a client)
"
Class {
	#name : 'PLCServerConfigurationRunner',
	#superclass : 'OSPlatformVisitor',
	#instVars : [
		'tcpPort'
	],
	#category : 'PharoLanguageClient',
	#package : 'PharoLanguageClient'
}

{ #category : 'as yet unclassified' }
PLCServerConfigurationRunner class >> newFor: aProgrammingLanguageString [

	^ (self allSubclasses detect: [ :clazz |
		   clazz supportedLanguages includes: aProgrammingLanguageString ])
		  new
]

{ #category : 'as yet unclassified' }
PLCServerConfigurationRunner class >> supportedLanguages [

	^ self subclassResponsibility
]

{ #category : 'testing' }
PLCServerConfigurationRunner >> isTCPHost [
	^ self subclassResponsibility
]

{ #category : 'accessing' }
PLCServerConfigurationRunner >> tcpPort [

	^ tcpPort
]

{ #category : 'accessing' }
PLCServerConfigurationRunner >> tcpPort: anObject [

	tcpPort := anObject
]
