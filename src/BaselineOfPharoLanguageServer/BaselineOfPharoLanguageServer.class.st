Class {
	#name : #BaselineOfPharoLanguageServer,
	#superclass : #BaselineOf,
	#category : #BaselineOfPharoLanguageServer
}

{ #category : #baselines }
BaselineOfPharoLanguageServer >> baseline: spec [
	<baseline>
	self defineDependencies: spec.
	self definePackages: spec.
	self defineGroups: spec
]

{ #category : #baselines }
BaselineOfPharoLanguageServer >> defineDependencies: spec [
	spec
		baseline: 'JRPC'
			with: [ spec
				repository: 'github://juliendelplanque/JRPC:v3.2.1/src';
				loads: #('Deployment') ];
		import: 'JRPC'
]

{ #category : #baselines }
BaselineOfPharoLanguageServer >> defineGroups: spec [
]

{ #category : #baselines }
BaselineOfPharoLanguageServer >> definePackages: spec [
	spec
		package: 'PharoLanguageServer' with: [ spec requires: #('JRPC') ];
		package: 'PharoLanguageServer-Tests'
			with: [ spec requires: #('PharoLanguageServer' 'PLS-DAP-Helper') ];
		package: 'PharoDAP'
			with: [ spec requires: #('PharoLanguageServer' 'PLS-DAP-Helper') ];
		package: 'PLS-DAP-Helper'.
	spec for: #'pharo8.x' do: [ spec package: 'PLS-Pharo8-Extension' ]
]
