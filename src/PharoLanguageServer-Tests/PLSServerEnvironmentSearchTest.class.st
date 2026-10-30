"
I test pls-env:search and workspace/symbol, the search of the entities of the image.
"
Class {
	#name : 'PLSServerEnvironmentSearchTest',
	#superclass : 'TestCase',
	#instVars : [
		'server'
	],
	#category : 'PharoLanguageServer-Tests',
	#package : 'PharoLanguageServer-Tests'
}

{ #category : 'running' }
PLSServerEnvironmentSearchTest >> setUp [

	super setUp.
	server := PLSServer new
]

{ #category : 'tests' }
PLSServerEnvironmentSearchTest >> testCapabilitiesAnnounceTheSearch [

	| capabilities |
	capabilities := PLSInitializeResult new asJRPCJSON at: #capabilities.
	self assert: (capabilities at: #workspaceSymbolProvider).
	self assert:
		((capabilities at: #experimental) at: #'pls-env' at: #search)
]

{ #category : 'tests' }
PLSServerEnvironmentSearchTest >> testClassAndTermFindInheritedMethods [

	| items |
	items := (server envSearch: 'Array col' kinds: nil limit: 10) at:
		         #items.
	self
		assert: items first
		equals:
		(items detect: [ :item | (item at: #label) = 'Array>>collect:' ]).
	self
		assert: (items first at: #id)
		equals: 'method:SequenceableCollection>>collect:'.
	self assert: (items first at: #kind) equals: 'method'.
	self
		assert: (items first at: #package)
		equals: 'package:Collections-Sequenceable'
]

{ #category : 'tests' }
PLSServerEnvironmentSearchTest >> testClassSideAndSelectorSyntax [

	#( 'Array class>>#new:' 'Array class new:' ) do: [ :query |
			self
				assert:
					(((server envSearch: query kinds: nil limit: 1) at: #items) first
						 at: #label)
				equals: 'Array class>>new:' ]
]

{ #category : 'tests' }
PLSServerEnvironmentSearchTest >> testEmptyQueryFindsNothing [

	self assert:
		((server envSearch: '  ' kinds: nil limit: nil) at: #items) isEmpty.
	self assert: (server workspaceSymbol: '') isEmpty
]

{ #category : 'tests' }
PLSServerEnvironmentSearchTest >> testExactNameComesFirst [

	| items |
	items := (server envSearch: 'array' kinds: #( 'class' ) limit: 5)
		         at: #items.
	self assert: (items first at: #id) equals: 'class:Array'.
	self assert:
		(items allSatisfy: [ :item | (item at: #kind) = 'class' ])
]

{ #category : 'tests' }
PLSServerEnvironmentSearchTest >> testKindsAreLimitedEachOnItsOwn [

	| result |
	result := server
		          envSearch: 'col'
		          kinds: #( 'class' 'method' )
		          limit: 3.
	self deny: (result at: #complete).
	self
		assert:
		((result at: #items) count: [ :item | (item at: #kind) = 'class' ])
		equals: 3.
	self
		assert:
		((result at: #items) count: [ :item | (item at: #kind) = 'method' ])
		equals: 3
]

{ #category : 'tests' }
PLSServerEnvironmentSearchTest >> testPackagesAndProjects [

	self
		assert: (((server
				   envSearch: 'PharoLanguageServer-Tests'
				   kinds: #( 'package' )
				   limit: 1) at: #items) first at: #id)
		equals: 'package:PharoLanguageServer-Tests'.
	self
		assert: (((server
				   envSearch: 'pharolanguageserver'
				   kinds: #( 'project' )
				   limit: 1) at: #items) first at: #id)
		equals: 'project:PharoLanguageServer'
]

{ #category : 'tests' }
PLSServerEnvironmentSearchTest >> testWorkspaceSymbolLocatesTheEntityEditor [

	| symbol |
	symbol := (server workspaceSymbol: 'Number>>//') first.
	self assert: (symbol at: #name) equals: 'Number>>//'.
	self assert: (symbol at: #kind) equals: 6.
	self assert: (symbol at: #containerName) equals: 'Kernel'.
	self
		assert: (symbol at: #location at: #uri)
		equals: 'pharo:/' , Smalltalk imageFile basenameWithoutExtension
			, '/Kernel/Number/instance/%252F%252F.st'
]

{ #category : 'tests' }
PLSServerEnvironmentSearchTest >> testWorkspaceSymbolNamesTheDefinerOfAnInheritedMethod [

	| symbol |
	symbol := (server workspaceSymbol: 'Array col') first.
	self assert: (symbol at: #name) equals: 'Array>>collect:'.
	self
		assert: (symbol at: #containerName)
		equals: 'SequenceableCollection (Collections-Sequenceable)'.
	self assert: ((symbol at: #location at: #uri) endsWith:
			 '/Collections-Sequenceable/SequenceableCollection/instance/collect%3A.st')
]
