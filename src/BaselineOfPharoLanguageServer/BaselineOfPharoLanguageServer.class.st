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
		baseline: 'MoreLogger'
		with: [ spec repository: 'github://badetitou/MoreLogger:main/src' ].
	spec
		baseline: 'SpecGtk'
		with: [ spec repository: 'github://pharo-spec/Spec-Gtk:/src' ].

	spec
		baseline: 'PharoHuggingFace'
		with: [ 
		spec repository: 'github://Evref-BL/Pharo-HuggingFace:main/src' ]
]

{ #category : #baselines }
BaselineOfPharoLanguageServer >> defineGroups: spec [

	spec group: 'default' with: #( 'LSP' 'DAP' 'LSC' 'Tests' ).
	spec group: 'LSC' with: #( 'PharoLanguageClient' ).
	spec
		group: 'LSP'
		with:
			#( 'PLSDAP-Helpers' 'PharoLanguageServer' 'PharoLanguageServer-Tests'
			   'PLS-Pharo9-Extension' ).
	spec group: 'LSP-GTK' with: #( 'LSP' 'PharoLanguageServer-Gtk' ).
	spec group: 'DAP' with: #( 'PharoDAP' ).
	spec group: 'Tests' with: #( 'PharoLanguageProtocol-Tests' ).
	spec
		group: 'localClient'
		with: #( 'default' 'PharoLanguageClienLocal' )
]

{ #category : #baselines }
BaselineOfPharoLanguageServer >> definePackages: spec [
	"common"

	spec package: 'PharoLanguageProtocol'.
	spec
		package: 'PharoLanguageProtocol-Tests'
		with: [
		spec requires: #( 'PharoLanguageServer' 'PharoLanguageClient' ) ].
	"server"
	spec
		package: 'PLSDAP-Helpers';
		package: 'PharoLanguageServer' with: [
			spec requires:
					#( 'JRPC' 'PLSDAP-Helpers' 'MoreLogger' 'PharoLanguageProtocol'
					   'PharoHuggingFace' ) ];
		package: 'PharoLanguageServer-Tests'
		with: [ spec requires: #( 'PharoLanguageServer' ) ];
		package: 'PharoDAP'
		with: [ spec requires: #( 'MoreLogger' 'PLSDAP-Helpers' ) ];
		package: 'PharoLanguageServer-Gtk'
		with: [ spec requires: #( 'SpecGtk' ) ].
	spec package: 'PLS-Pharo9-Extension'.

	"client"
	spec
		package: 'PharoLanguageClient'
		with: [ spec requires: #( 'JRPC' 'PharoLanguageProtocol' ) ].

	spec
		package: 'PharoLanguageClienLocal'
		with: [ spec requires: #( 'PharoLanguageClient' ) ]
]
