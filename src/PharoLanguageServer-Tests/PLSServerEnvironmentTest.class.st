"
I test the pls-env:* requests of PLSServer, which expose the environment model: projects, packages, tags, classes, sides, protocols and methods, named by stable ids.
I use the classes of Pharo Language Server itself as fixtures.
"
Class {
	#name : 'PLSServerEnvironmentTest',
	#superclass : 'TestCase',
	#instVars : [
		'server'
	],
	#category : 'PharoLanguageServer-Tests',
	#package : 'PharoLanguageServer-Tests'
}

{ #category : 'running' }
PLSServerEnvironmentTest >> childrenIdsOf: id [

	^ ((server envChildren: id offset: nil limit: nil) at: #items)
		  collect: [ :node | node at: #id ]
]

{ #category : 'running' }
PLSServerEnvironmentTest >> plsRepository [
	"Answer the Iceberg repository holding the PLS packages, nil when there is none, as when the CI loads them through Metacello alone"

	^ IceRepository registry
		  detect: [ :repository |
				  repository workingCopy includesPackageNamed:
					  'PharoLanguageServer-Tests' ]
		  ifNone: [ nil ]
]

{ #category : 'running' }
PLSServerEnvironmentTest >> setUp [

	super setUp.
	server := PLSServer new
]

{ #category : 'tests' }
PLSServerEnvironmentTest >> testCapabilitiesAnnounceTheEnvironmentModel [

	| capabilities |
	capabilities := PLSInitializeResult new asJRPCJSON at: #capabilities.
	self
		assert:
		((capabilities at: #experimental) at: #'pls-env' at: #version)
		equals: 1
]

{ #category : 'tests' }
PLSServerEnvironmentTest >> testChildrenArePaginated [

	| all page |
	all := self childrenIdsOf: 'package:PharoLanguageServer'.
	page := server
		        envChildren: 'package:PharoLanguageServer'
		        offset: 2
		        limit: 3.
	self assert: (page at: #total) equals: all size.
	self
		assert: ((page at: #items) collect: [ :node | node at: #id ])
		equals: (all copyFrom: 3 to: 5).
	self assert: ((server
			  envChildren: 'package:PharoLanguageServer'
			  offset: all size
			  limit: 3) at: #items) isEmpty
]

{ #category : 'tests' }
PLSServerEnvironmentTest >> testClassChildrenAreItsTwoSides [

	self
		assert: (self childrenIdsOf: 'class:PLSServerCapabilities')
		equals:
		#( 'side:PLSServerCapabilities' 'side:PLSServerCapabilities class' )
]

{ #category : 'tests' }
PLSServerEnvironmentTest >> testClassEntity [

	| entity |
	entity := server envEntity: 'class:PLSServerEnvironmentTest'.
	self assert: (entity at: #kind) equals: 'class'.
	self
		assert: (entity at: #parent)
		equals: 'package:PharoLanguageServer-Tests'.
	self assert: (entity at: #superclass) equals: 'class:TestCase'.
	self
		assert: (entity at: #repository)
		equals:
		(self plsRepository ifNotNil: [ :repository | repository name ]).
	self assert: (entity at: #flags at: #test).
	self deny: (entity at: #flags at: #abstract)
]

{ #category : 'tests' }
PLSServerEnvironmentTest >> testClassSideMethodsKeepTheClassSuffix [

	| entity |
	self assert:
		((self childrenIdsOf: 'side:PLSServerCapabilities class') includes:
			 'protocol:PLSServerCapabilities class>>public').
	self assert:
		((self childrenIdsOf: 'protocol:PLSServerCapabilities class>>public')
			 includes: 'method:PLSServerCapabilities class>>forPharo').
	entity := server envEntity:
		          'method:PLSServerCapabilities class>>forPharo'.
	self
		assert: (entity at: #parent)
		equals: 'protocol:PLSServerCapabilities class>>public'.
	self assert: (entity at: #name) equals: #forPharo
]

{ #category : 'tests' }
PLSServerEnvironmentTest >> testEveryParentListsItsChild [

	#( 'package:PharoLanguageServer' 'tag:PharoLanguageServer/Context'
	   'class:PLSServer' 'side:PLSServer class' 'protocol:PLSServer>>pls - env'
	   'method:PLSServer>>envProjects' 'method:Object>>plsPrintString' ) do: [
			:id |
			| parent |
			parent := (server envEntity: id) at: #parent.
			id = 'method:Object>>plsPrintString'
				ifTrue: [
				self
					assert: parent
					equals: 'protocol:Object>>*PharoLanguageServer' ]
				ifFalse: [
				self assert: ((self childrenIdsOf: parent) includes: id) ] ]
]

{ #category : 'tests' }
PLSServerEnvironmentTest >> testExtensionsChildrenAreExtensionMethods [

	| ids |
	ids := self childrenIdsOf: 'extensions:PharoLanguageServer'.
	self assert: (ids includes: 'method:Object>>plsPrintString').
	self assert: ((server envEntity: 'method:Object>>plsPrintString')
			 at: #flags
			 at: #extension).
	self
		assert:
		((server envEntity: 'method:Object>>plsPrintString') at: #package)
		equals: 'package:PharoLanguageServer'
]

{ #category : 'tests' }
PLSServerEnvironmentTest >> testMethodFlags [

	| flags |
	flags := (server envEntity: 'method:PLSServerEnvironmentTest>>setUp')
		         at: #flags.
	self assert: (flags at: #override).
	self deny: (flags at: #test).
	self deny: (flags at: #abstract).
	self deny: (flags at: #extension).
	self deny: (flags at: #fromTrait).
	self deny: (flags at: #deprecated).
	self assert:
		((server envEntity:
			  'method:PLSServerEnvironmentTest>>testMethodFlags')
			 at: #flags
			 at: #test).
	self assert: ((server envEntity:
			  'method:PLSAbstractServer>>textDocumentHoverWithPosition:textDocument:')
			 at: #flags
			 at: #abstract)
]

{ #category : 'tests' }
PLSServerEnvironmentTest >> testMethodFromATraitNamesItsTrait [

	| class method |
	class := Object allSubclasses detect: [ :each |
			         each isTrait not and: [
					         each selectors anySatisfy: [ :selector |
						         (each >> selector) isFromTrait ] ] ].
	method := class >> (class selectors detect: [ :selector |
		           (class >> selector) isFromTrait ]).
	self
		assert:
			((server envNode: 'method:' , class name , '>>' , method selector)
				 at: #trait)
		equals: 'class:' , method origin instanceSide name.
	self assert:
		(((server envEntity: 'side:' , class name) at: #traits) includes:
			 'class:' , method origin instanceSide name).
	self deny:
		((server envNode: 'method:PLSAbstractServer>>initializeStreams')
			 includesKey: #trait)
]

{ #category : 'tests' }
PLSServerEnvironmentTest >> testPackageChildrenAreTagsThenRootClassesThenExtensions [

	| ids |
	ids := self childrenIdsOf: 'package:PharoLanguageServer'.
	self assert: ids first equals: 'tag:PharoLanguageServer/Context'.
	self assert: (ids includes: 'class:PLSServer').
	self assert: ids last equals: 'extensions:PharoLanguageServer'.
	self assert:
		((self childrenIdsOf: 'tag:PharoLanguageServer/Context') includes:
			 'class:PLSContext')
]

{ #category : 'tests' }
PLSServerEnvironmentTest >> testPackageEntityTellsWhetherItIsModified [

	| repository entity |
	repository := self plsRepository.
	entity := server envEntity: 'package:PharoLanguageServer-Tests'.
	self
		assert: (entity at: #repository)
		equals: (repository ifNotNil: [ repository name ]).
	self
		assert: (entity at: #modified)
		equals: (repository ifNil: [ false ] ifNotNil: [
					 (repository workingCopy packageNamed:
						  'PharoLanguageServer-Tests') isDirty ]).
	self deny:
		((server envEntity: 'class:PLSServerEnvironmentTest') includesKey:
			 #modified)
]

{ #category : 'tests' }
PLSServerEnvironmentTest >> testPackageParentIsItsProject [

	self
		assert:
		((server envEntity: 'package:PharoLanguageServer') at: #parent)
		equals: 'project:PharoLanguageServer'
]

{ #category : 'tests' }
PLSServerEnvironmentTest >> testProjectChildrenAreItsLoadedPackages [

	| ids |
	ids := self childrenIdsOf: 'project:PharoLanguageServer'.
	self assert: (ids includes: 'package:PharoLanguageServer').
	self assert: (ids includes: 'package:BaselineOfPharoLanguageServer').
	self assert: (ids allSatisfy: [ :id |
			 server packageOrganizer hasPackage: (id allButFirst: 8) ]).
	self deny: ((self childrenIdsOf: 'project:*') includes:
			 'package:PharoLanguageServer')
]

{ #category : 'tests' }
PLSServerEnvironmentTest >> testProjectEntityGivesTheRepositoryOfItsBaseline [

	| entity |
	entity := server envEntity: 'project:PharoLanguageServer'.
	self
		assert: (entity at: #repository)
		equals:
		(self plsRepository ifNotNil: [ :repository | repository name ]).
	self assert: (entity at: #package) isNil.
	self assert: ((entity at: #modified) isKindOf: Boolean)
]

{ #category : 'tests' }
PLSServerEnvironmentTest >> testProjectsAreTheBaselinesThenTheVolatileProject [

	| ids |
	ids := server envProjects collect: [ :node | node at: #id ].
	self assert: (ids includes: 'project:PharoLanguageServer').
	self assert: ids last equals: 'project:*'.
	self assert: (server envProjects last at: #flags at: #volatile)
]

{ #category : 'tests' }
PLSServerEnvironmentTest >> testSelectorHoldingGreaterThanSigns [

	| entity |
	entity := server envEntity: 'method:Behavior>>>>'.
	self assert: (entity at: #name) equals: #'>>'.
	self assert: ((entity at: #parent) beginsWith: 'protocol:Behavior>>')
]

{ #category : 'tests' }
PLSServerEnvironmentTest >> testSideEntityGivesSlotsTraitsAndRedefinedSelectors [

	| entity |
	entity := server envEntity: 'side:PLSAbstractServer'.
	self assert: ((entity at: #slots) includes: 'serverContext').
	self assert: ((entity at: #traits) includes: 'class:TPLPCommon').
	self assert: ((entity at: #overridden) includes:
			 'textDocumentHoverWithPosition:textDocument:').
	self deny: ((entity at: #overridden) includes: 'initializeStreams').
	self
		assert:
		((server envEntity: 'side:PLSAbstractServer class') at: #traits)
		equals: (entity at: #traits).
	self
		assert: ((server envEntity: 'side:PLSAbstractServer class') at:
				 #classVariables)
		equals: #(  )
]

{ #category : 'tests' }
PLSServerEnvironmentTest >> testUnknownIdAnswersInvalidParamsNamingTheEntity [

	| response |
	response := [ server envEntity: 'class:NoSuchClass' ]
		            on: PLSUnknownEntity
		            do: [ :error | error asJRPCResponseWithId: 3 ].
	self assert: response error code equals: -32602.
	self assert:
		(response error message includesSubstring: 'NoSuchClass')
]

{ #category : 'tests' }
PLSServerEnvironmentTest >> testUnknownIdsAreRejected [

	#( 'nothing' 'foo:Bar' 'class:NoSuchClass' 'class:Array class'
	   'class:Smalltalk' 'package:NoSuchPackage' 'project:NoSuchProject'
	   'method:Array>>noSuchSelector' 'protocol:Array>>no such protocol'
	   'tag:PharoLanguageServer/NoSuchTag' ) do: [ :id |
		self should: [ server envEntity: id ] raise: PLSUnknownEntity ]
]

{ #category : 'tests' }
PLSServerEnvironmentTest >> testVolatileProjectHasNoRepository [

	| entity |
	entity := server envEntity: 'project:*'.
	self assert: (entity at: #repository) isNil.
	self assert: ((entity at: #modified) isKindOf: Boolean)
]
