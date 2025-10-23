Class {
	#name : 'BaselineOfPharoLanguageServer',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfPharoLanguageServer',
	#package : 'BaselineOfPharoLanguageServer'
}

{ #category : 'baselines' }
BaselineOfPharoLanguageServer >> baseline: spec [
	<baseline>
	self defineDependencies: spec.
	self definePackages: spec.
	self defineGroups: spec
]

{ #category : 'baselines' }
BaselineOfPharoLanguageServer >> customProjectAttributes [
    self class environment at: #RTView ifPresent: [ ^ #(#WithRoassal2) ].
	self class environment at: #RSCanvas ifPresent: [ ^ #(#WithRoassal3) ].
    ^ #()
]

{ #category : 'baselines' }
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
		baseline: 'LLMAPI'
		with: [ spec repository: 'github://Evref-BL/Pharo-LLMAPI:main/src' ].

	spec
		baseline: 'SpecToplo'
		with: [
		spec repository: 'github://pharo-graphics/Spec-Toplo:1d7d888/src' ].


	spec baseline: 'Roassal' with: [
		spec
			repository: 'github://pharo-graphics/Roassal:Pharo13';
			loads: #( 'BlocFull' ) ]
]

{ #category : 'baselines' }
BaselineOfPharoLanguageServer >> defineGroups: spec [

	spec group: 'default' with: #( 'LSP' 'DAP' 'LSC' 'Tests' ).
	spec group: 'LSC' with: #( 'PharoLanguageClient' ).
	spec
		group: 'LSP'
		with:
			#( 'PLSDAP-Helpers' 'PharoLanguageServer' 'PharoLanguageServer-Tests'
			   'PLS-Pharo9-Extension' ).
	spec group: 'LSP-GTK' with: #( 'LSP' 'PharoLanguageServer-Gtk' ).
	spec group: 'LSP-Toplo' with: #( 'LSP' 'SpecToplo' 'Roassal' 'PharoLanguageProtocol-Toplo' ).
	spec group: 'DAP' with: #( 'PharoDAP' ).
	spec group: 'Tests' with: #( 'PharoLanguageProtocol-Tests' ).
	spec
		group: 'localClient'
		with: #( 'default' 'PharoLanguageClientLocal' )
]

{ #category : 'baselines' }
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
					   'LLMAPI' ) ];
		package: 'PharoLanguageServer-Tests'
		with: [ spec requires: #( 'PharoLanguageServer' ) ];
		package: 'PharoDAP'
		with: [ spec requires: #( 'MoreLogger' 'PLSDAP-Helpers' ) ];
		package: 'PharoLanguageServer-Gtk'
		with: [ spec requires: #( 'SpecGtk' ) ].
	spec
		package: 'PharoLanguageServer-Toplo'
		with: [ spec requires: #( 'SpecToplo' 'Roassal' ) ].
	spec package: 'PLS-Pharo9-Extension'.

	"client"
	spec
		package: 'PharoLanguageClient'
		with: [ spec requires: #( 'JRPC' 'PharoLanguageProtocol' ) ].

	spec
		package: 'PharoLanguageClienLocal'
		with: [ spec requires: #( 'PharoLanguageClient' ) ]
]
