"
I test the pls-env:read, pls-env:compile and pls-env:remove requests of PLSServer, and the method documents they back.
I edit a probe class that I remove after each test.
"
Class {
	#name : 'PLSServerEntityEditionTest',
	#superclass : 'TestCase',
	#instVars : [
		'server',
		'probeClass'
	],
	#category : 'PharoLanguageServer-Tests',
	#package : 'PharoLanguageServer-Tests'
}

{ #category : 'running' }
PLSServerEntityEditionTest >> completionsIn: uri line: line character: character [

	^ (server
		   textDocumentCompletionWithContext: nil
		   position: {
				   (#line -> line).
				   (#character -> character) } asDictionary
		   textDocument: { (#uri -> uri) } asDictionary) completionItems
		  collect: [ :item | item label ]
]

{ #category : 'running' }
PLSServerEntityEditionTest >> open: uri text: aString [

	server didOpen: {
			(#uri -> uri).
			(#version -> 1).
			(#languageId -> 'pharo').
			(#text -> aString) } asDictionary.
	^ server context textItem: uri
]

{ #category : 'running' }
PLSServerEntityEditionTest >> probePackageName [

	^ 'PLSEntityEditionProbe'
]

{ #category : 'running' }
PLSServerEntityEditionTest >> setUp [

	super setUp.
	server := PLSServer new.
	server clientOutStream: (WriteStream on: ByteArray new).
	server context clientContext: (PLPInitializeParams new
			 capabilities: (PLPClientCapabilities from: {  } asDictionary);
			 yourself).
	probeClass := (Object << #PLSEntityEditionProbe)
		              slots: { #count };
		              package: self probePackageName;
		              install.
	probeClass
		compile: 'count
	^ count'
		classified: 'accessing'
]

{ #category : 'running' }
PLSServerEntityEditionTest >> tearDown [

	self packageOrganizer
		packageNamed: self probePackageName
		ifPresent: [ :package | package removeFromSystem ].
	super tearDown
]

{ #category : 'tests - edition' }
PLSServerEntityEditionTest >> testCapabilitiesAnnounceEdition [

	| experimental |
	experimental := (PLSInitializeResult new asJRPCJSON at: #capabilities)
		                at: #experimental.
	self assert: ((experimental at: #'pls-env') at: #edit)
]

{ #category : 'tests - edition' }
PLSServerEntityEditionTest >> testCompileARemovedMethodIsAConflict [

	| version conflict |
	version := self versionOf: 'method:PLSEntityEditionProbe>>count'.
	probeClass removeSelector: #count.
	conflict := [
		            server
			            envCompile: 'method:PLSEntityEditionProbe>>count'
			            source: 'count ^ 1'
			            protocol: nil
			            expectedVersion: version ]
		            on: PLSEntityConflict
		            do: [ :error | error ].
	self assert: conflict class equals: PLSEntityConflict.
	self assert: conflict currentVersion isNil.
	self deny: (probeClass includesSelector: #count)
]

{ #category : 'tests - edition' }
PLSServerEntityEditionTest >> testCompileARemovedMethodWithoutVersionRecreatesIt [

	probeClass removeSelector: #count.
	self assert: ((server
			  envCompile: 'method:PLSEntityEditionProbe>>count'
			  source: 'count ^ 1'
			  protocol: nil
			  expectedVersion: nil) at: #compiled).
	self assert: probeClass new count equals: 1
]

{ #category : 'tests - edition' }
PLSServerEntityEditionTest >> testCompileBrokenClassDefinition [

	| result |
	result := server
		          envCompile: 'class:PLSEntityEditionProbe'
		          source: 'Class { #name : '
		          protocol: nil
		          expectedVersion: nil.
	self deny: (result at: #compiled).
	self assert: (result at: #diagnostics) notEmpty
]

{ #category : 'tests - edition' }
PLSServerEntityEditionTest >> testCompileClassDefinition [

	| read result |
	read := server envRead: 'class:PLSEntityEditionProbe'.
	result := server
		          envCompile: 'class:PLSEntityEditionProbe'
		          source: ((read at: #source)
				           copyReplaceAll: '''count'''
				           with: '''count'', ''step''')
		          protocol: nil
		          expectedVersion: (read at: #version).
	self assert: (result at: #compiled).
	self assert: probeClass instVarNames equals: #( #count #step ).
	self
		assert: (result at: #version)
		equals: (self versionOf: 'class:PLSEntityEditionProbe')
]

{ #category : 'tests - edition' }
PLSServerEntityEditionTest >> testCompileMethod [

	| result |
	result := server
		          envCompile: 'method:PLSEntityEditionProbe>>count'
		          source: 'count
	^ count ifNil: [ 0 ]'
		          protocol: nil
		          expectedVersion:
		          (self versionOf: 'method:PLSEntityEditionProbe>>count').
	self assert: (result at: #compiled).
	self
		assert: (result at: #id)
		equals: 'method:PLSEntityEditionProbe>>count'.
	self
		assert: (result at: #version)
		equals: (self versionOf: 'method:PLSEntityEditionProbe>>count').
	self assert: probeClass new count equals: 0.
	self assert: (probeClass >> #count) protocolName equals: #accessing
]

{ #category : 'tests - edition' }
PLSServerEntityEditionTest >> testCompileNewMethodInASide [

	| result |
	result := server
		          envCompile: 'side:PLSEntityEditionProbe class'
		          source: 'default ^ 7'
		          protocol: 'defaults'
		          expectedVersion: nil.
	self
		assert: (result at: #id)
		equals: 'method:PLSEntityEditionProbe class>>default'.
	self assert: probeClass default equals: 7.
	self
		assert: (probeClass class >> #default) protocolName
		equals: #defaults
]

{ #category : 'tests - edition' }
PLSServerEntityEditionTest >> testCompileWithAStaleVersionIsAConflict [

	| version conflict |
	version := self versionOf: 'method:PLSEntityEditionProbe>>count'.
	probeClass compile: 'count ^ 42' classified: 'accessing'.
	conflict := [
		            server
			            envCompile: 'method:PLSEntityEditionProbe>>count'
			            source: 'count ^ 1'
			            protocol: nil
			            expectedVersion: version ]
		            on: PLSEntityConflict
		            do: [ :error | error ].
	self assert: conflict class equals: PLSEntityConflict.
	self
		assert: conflict currentVersion
		equals: (self versionOf: 'method:PLSEntityEditionProbe>>count').
	self
		assert: (conflict asJRPCResponseWithId: 1) error code
		equals: -32001.
	self assert: probeClass new count equals: 42
]

{ #category : 'tests - documents' }
PLSServerEntityEditionTest >> testCompletionInClassSideMethodDocumentKnowsArguments [

	self
		open:
		'pharo:/PLS/PLSEntityEditionProbe/PLSEntityEditionProbe/class/new%3A.st'
		text: 'new: aNumber ^ aN'.
	self
		assert: (self
				 completionsIn:
				 'pharo:/PLS/PLSEntityEditionProbe/PLSEntityEditionProbe/class/new%3A.st'
				 line: 0
				 character: 17) asArray
		equals: #( #aNumber )
]

{ #category : 'tests - documents' }
PLSServerEntityEditionTest >> testCompletionInMethodDocumentKnowsInstanceVariables [

	self
		open:
		'pharo:/PLS/PLSEntityEditionProbe/PLSEntityEditionProbe/instance/next.st'
		text: 'next
	^ co'.
	self
		assert: (self
				 completionsIn:
				 'pharo:/PLS/PLSEntityEditionProbe/PLSEntityEditionProbe/instance/next.st'
				 line: 1
				 character: 5) asArray
		equals: #( #count )
]

{ #category : 'tests - documents' }
PLSServerEntityEditionTest >> testCompletionInMethodDocumentKnowsSelf [

	self
		open:
		'pharo:/PLS/PLSEntityEditionProbe/PLSEntityEditionProbe/instance/next.st'
		text: 'next
	^ self cou'.
	self assert: ((self
			  completionsIn:
			  'pharo:/PLS/PLSEntityEditionProbe/PLSEntityEditionProbe/instance/next.st'
			  line: 1
			  character: 11) includes: #count)
]

{ #category : 'tests - documents' }
PLSServerEntityEditionTest >> testMethodDocumentDiagnosticsAndFormatting [

	| document |
	document := self
		            open:
		            'pharo:/PLS/PLSEntityEditionProbe/PLSEntityEditionProbe/instance/next.st'
		            text: 'next ^ count +'.
	self assert: document diagnostics size equals: 1.
	document := self
		            open:
		            'pharo:/PLS/PLSEntityEditionProbe/PLSEntityEditionProbe/instance/next.st'
		            text: 'next |a| a:=count. ^ a+1'.
	self assert: document diagnostics isEmpty.
	self
		assert: (server
				 formatTextDocument: { (#uri -> document uri) } asDictionary
				 withOptions: nil) first newText
		equals: 'next

	| a |
	a := count.
	^ a + 1'.
	self
		assert:
			(server documentSymbol: { (#uri -> document uri) } asDictionary)
				first name
		equals: #next
]

{ #category : 'tests - documents' }
PLSServerEntityEditionTest >> testMethodDocumentKnowsItsClassAndSide [

	self
		assert: (self
				 open:
				 'pharo:/PLS/PLSEntityEditionProbe/PLSEntityEditionProbe/instance/count.st'
				 text: 'count ^ count') behavior
		equals: probeClass.
	self
		assert: (self
				 open:
				 'pharo:/PLS/PLSEntityEditionProbe/PLSEntityEditionProbe/class/new%3A.st'
				 text: 'new: x ^ self') behavior
		equals: probeClass class.
	self
		assert: (self
				 open: 'pharo:/PLS/Kernel/Number/instance/%2F%2F.st'
				 text: '// x ^ self') class
		equals: PLSMethodDocument
]

{ #category : 'tests - edition' }
PLSServerEntityEditionTest >> testOnlyClassesAndMethodsAreEdited [

	self
		should: [ server envRead: 'package:' , self probePackageName ]
		raise: PLSUnknownEntity.
	self
		should: [
				server
					envRemove: 'package:' , self probePackageName
					expectedVersion: nil ]
		raise: PLSUnknownEntity.
	self
		should: [
				server
					envCompile: 'package:' , self probePackageName
					source: 'foo'
					protocol: nil
					expectedVersion: nil ]
		raise: PLSUnknownEntity
]

{ #category : 'tests - documents' }
PLSServerEntityEditionTest >> testOtherDocumentsAreNotMethodDocuments [

	self
		assert:
		(self open: 'file:///tmp/instance/script.st' text: '1 + 2') class
		equals: PLSScriptDocument.
	self
		assert: (self
				 open:
				 'pharo:/PLS/PLSEntityEditionProbe/PLSEntityEditionProbe.class.st'
				 text: '') class
		equals: PLSTonelDocument
]

{ #category : 'tests - edition' }
PLSServerEntityEditionTest >> testReadClassGivesItsTonelDefinition [

	| source |
	probeClass comment: 'A probe'.
	source := (server envRead: 'class:PLSEntityEditionProbe') at: #source.
	self assert:
		(source beginsWith: '"' , String lf , 'A probe' , String lf , '"').
	self assert:
		(source includesSubstring: '#name : ''PLSEntityEditionProbe''').
	self deny: (source includesSubstring: '^ count')
]

{ #category : 'tests - edition' }
PLSServerEntityEditionTest >> testReadMethod [

	| read |
	read := server envRead: 'method:PLSEntityEditionProbe>>count'.
	self assert: (read at: #source) equals: 'count
	^ count'.
	self assert: (read at: #protocol) equals: #accessing.
	self assert: (read at: #side) equals: 'side:PLSEntityEditionProbe'.
	self
		assert: (read at: #version)
		equals:
			((server envEntity: 'method:PLSEntityEditionProbe>>count') at:
				 #version)
]

{ #category : 'tests - edition' }
PLSServerEntityEditionTest >> testRemoveMethod [

	server
		envRemove: 'method:PLSEntityEditionProbe>>count'
		expectedVersion:
		(self versionOf: 'method:PLSEntityEditionProbe>>count').
	self deny: (probeClass includesSelector: #count)
]

{ #category : 'tests - edition' }
PLSServerEntityEditionTest >> testRemoveWithAStaleVersionIsAConflict [

	self
		should: [
				server
					envRemove: 'method:PLSEntityEditionProbe>>count'
					expectedVersion: 'stale' ]
		raise: PLSEntityConflict.
	self assert: (probeClass includesSelector: #count)
]

{ #category : 'tests - edition' }
PLSServerEntityEditionTest >> testRenamedSelectorCreatesANewMethod [

	| result |
	result := server
		          envCompile: 'method:PLSEntityEditionProbe>>count'
		          source: 'total ^ 3'
		          protocol: nil
		          expectedVersion: nil.
	self
		assert: (result at: #id)
		equals: 'method:PLSEntityEditionProbe>>total'.
	self assert: (probeClass includesSelector: #count).
	self assert: (probeClass >> #total) protocolName equals: #accessing
]

{ #category : 'tests - edition' }
PLSServerEntityEditionTest >> testSemanticErrorAnswersARange [

	| diagnostic |
	diagnostic := ((server
		                envCompile: 'method:PLSEntityEditionProbe>>count'
		                source: 'count self := 3'
		                protocol: nil
		                expectedVersion: nil) at: #diagnostics) first.
	self
		assert: (diagnostic at: #message)
		equals: 'Assignment to read-only variable'.
	self assert: ((diagnostic at: #range) at: #start) equals: {
			(#line -> 0).
			(#character -> 6) } asDictionary.
	self assert: ((diagnostic at: #range) at: #end) equals: {
			(#line -> 0).
			(#character -> 10) } asDictionary
]

{ #category : 'tests - edition' }
PLSServerEntityEditionTest >> testSyntaxErrorAnswersARange [

	| result range |
	result := server
		          envCompile: 'method:PLSEntityEditionProbe>>count'
		          source: 'count' , String cr , '	^ count +'
		          protocol: nil
		          expectedVersion: nil.
	self deny: (result at: #compiled).
	self assert: (result at: #id) isNil.
	self
		assert: ((result at: #diagnostics) first at: #severity)
		equals: 1.
	range := (result at: #diagnostics) first at: #range.
	self assert: ((range at: #start) at: #line) equals: 1.
	self assert: ((range at: #start) at: #character) equals: 10.
	self assert: (probeClass >> #count) sourceCode equals: 'count
	^ count'
]

{ #category : 'tests - edition' }
PLSServerEntityEditionTest >> testUndeclaredVariableIsAWarning [

	| result |
	result := server
		          envCompile: 'side:PLSEntityEditionProbe'
		          source: 'other ^ plsEntityEditionUndeclared'
		          protocol: nil
		          expectedVersion: nil.
	[
		self assert: (result at: #compiled).
		self
			assert: ((result at: #diagnostics) first at: #severity)
			equals: 2.
		self assert: (probeClass includesSelector: #other) ] ensure: [
		Undeclared removeKey: #plsEntityEditionUndeclared ifAbsent: [ ] ]
]

{ #category : 'running' }
PLSServerEntityEditionTest >> versionOf: id [

	^ (server envRead: id) at: #version
]
