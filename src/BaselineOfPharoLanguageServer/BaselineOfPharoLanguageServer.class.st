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
BaselineOfPharoLanguageServer >> customProjectAttributes [
    self class environment at: #RTView ifPresent: [ ^ #(#WithRoassal2) ].
	self class environment at: #RSCanvas ifPresent: [ ^ #(#WithRoassal3) ].
    ^ #()
]

{ #category : #baselines }
BaselineOfPharoLanguageServer >> defineDependencies: spec [

	spec
		baseline: 'JRPC' with: [ 
			spec
				repository: 'github://juliendelplanque/JRPC:v3.2.1/src';
				loads: #( 'Deployment' ) ];
		import: 'JRPC'.
	spec
		baseline: 'TinyLogger'
		with: [ spec repository: 'github://jecisc/TinyLogger:v1.x.x/src' ].
	spec
		baseline: 'SpecGtk'
		with: [ spec repository: 'github://pharo-spec/Spec-Gtk:/src' ]
]

{ #category : #baselines }
BaselineOfPharoLanguageServer >> defineGroups: spec [

	spec group: 'DAP' with: #( 'PharoDAP' )
]

{ #category : #baselines }
BaselineOfPharoLanguageServer >> definePackages: spec [

	spec
		package: 'PharoLanguageServer'
		with: [ spec requires: #( 'JRPC' 'TinyLogger' ) ];
		package: 'PharoLanguageServer-Tests'
		with: [ spec requires: #( 'PharoLanguageServer' ) ];
		package: 'PharoDAP' with: [ spec requires: #( 'TinyLogger' ) ];
		package: 'PharoLanguageServer-Gtk'
		with: [ spec requires: #( 'SpecGtk' ) ].
	spec for: #WithRoassal2 do: [ spec package: 'PLS-Pharo8-Extension' ].
	spec for: #WithRoassal3 do: [ spec package: 'PLS-Pharo9-Extension' ]
]
