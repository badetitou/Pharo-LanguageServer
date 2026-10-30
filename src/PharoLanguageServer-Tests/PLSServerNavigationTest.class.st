"
I test the semantic navigation of PLSServer: textDocument/references, textDocument/implementation, the call hierarchy and the type hierarchy, on probe classes I install.
"
Class {
	#name : 'PLSServerNavigationTest',
	#superclass : 'TestCase',
	#instVars : [
		'server',
		'probeClass',
		'childClass'
	],
	#category : 'PharoLanguageServer-Tests',
	#package : 'PharoLanguageServer-Tests'
}

{ #category : 'running' }
PLSServerNavigationTest >> line: line character: character [

	^ server navLine: line character: character
]

{ #category : 'running' }
PLSServerNavigationTest >> open: aMethod [
	"Open the editor of aMethod, and answer its text document"

	| uri |
	uri := server navUriOfMethod: aMethod.
	server openDocument: {
			(#uri -> uri).
			(#version -> 1).
			(#languageId -> 'pharo').
			(#text -> aMethod sourceCode) } asDictionary.
	^ { (#uri -> uri) } asDictionary
]

{ #category : 'running' }
PLSServerNavigationTest >> open: uri text: aString [

	server openDocument: {
			(#uri -> uri).
			(#version -> 1).
			(#languageId -> 'pharo').
			(#text -> aString) } asDictionary.
	^ { (#uri -> uri) } asDictionary
]

{ #category : 'running' }
PLSServerNavigationTest >> probePackageName [

	^ 'PLSNavigationProbe'
]

{ #category : 'running' }
PLSServerNavigationTest >> referencesIn: textDocument line: line character: character [

	^ server
		  textDocumentReferencesWithPosition:
		  (self line: line character: character)
		  textDocument: textDocument
		  context: { (#includeDeclaration -> false) } asDictionary
]

{ #category : 'running' }
PLSServerNavigationTest >> setUp [

	super setUp.
	server := PLSServer new.
	server clientOutStream: (WriteStream on: ByteArray new).
	server context clientContext: (PLPInitializeParams new
			 capabilities: (PLPClientCapabilities from: {  } asDictionary);
			 yourself).
	probeClass := (Object << #PLSNavigationProbe)
		              slots: { #count };
		              package: self probePackageName;
		              install.
	childClass := (probeClass << #PLSNavigationProbeChild)
		              package: self probePackageName;
		              install.
	probeClass
		compile: 'count
	^ count'
		classified: 'accessing';
		compile: 'plsNavIncrement
	count := self count + 1'
		classified: 'probing';
		compile: 'plsNavReset
	| previous |
	previous := count.
	count := 0.
	^ self plsNavIncrement'
		classified: 'probing'.
	probeClass classSide
		compile: 'plsNavNew
	^ self new plsNavReset; yourself'
		classified: 'probing'.
	childClass
		compile: 'plsNavIncrement
	super plsNavIncrement.
	^ count'
		classified: 'probing'
]

{ #category : 'running' }
PLSServerNavigationTest >> tearDown [

	self packageOrganizer
		packageNamed: self probePackageName
		ifPresent: [ :package | package removeFromSystem ].
	super tearDown
]

{ #category : 'tests' }
PLSServerNavigationTest >> testCallHierarchyFromASendIsTheMethodItRuns [

	| items |
	items := server
		         callHierarchyPrepareWithPosition:
		         (self line: 4 character: 10)
		         textDocument: (self open: probeClass >> #plsNavReset).
	self
		assert: (items collect: [ :each | each at: #name ])
		equals: #( 'PLSNavigationProbe>>plsNavIncrement' ).
	self
		assert: ((items first at: #data) at: #id)
		equals: 'method:PLSNavigationProbe>>plsNavIncrement'
]

{ #category : 'tests' }
PLSServerNavigationTest >> testCallHierarchyIncomingCallsAreTheSenders [

	| calls |
	calls := (server callHierarchyIncomingCalls:
		          (server navCallItemOf: probeClass >> #plsNavIncrement))
		         select: [ :each |
		         ((each at: #from) at: #detail) = self probePackageName ].
	self
		assert: (calls collect: [ :each | (each at: #from) at: #name ])
		equals:
		#( 'PLSNavigationProbe>>plsNavReset'
		   'PLSNavigationProbeChild>>plsNavIncrement' ).
	self assert: (calls first at: #fromRanges) equals: { {
			(#start -> (self line: 4 character: 8)).
			(#end -> (self line: 4 character: 23)) } asDictionary }
]

{ #category : 'tests' }
PLSServerNavigationTest >> testCallHierarchyOfARemovedMethodIsEmpty [

	| item |
	item := server navCallItemOf: childClass >> #plsNavIncrement.
	childClass removeSelector: #plsNavIncrement.
	self assert: (server callHierarchyIncomingCalls: item) equals: #(  ).
	self assert: (server callHierarchyOutgoingCalls: item) equals: #(  )
]

{ #category : 'tests' }
PLSServerNavigationTest >> testCallHierarchyOutgoingCallsFollowSelfAndSuper [

	| calls |
	calls := server callHierarchyOutgoingCalls:
		         (server navCallItemOf: childClass >> #plsNavIncrement).
	self
		assert: (calls collect: [ :each | (each at: #to) at: #name ])
		equals: #( 'PLSNavigationProbe>>plsNavIncrement' ).
	calls := server callHierarchyOutgoingCalls:
		         (server navCallItemOf: probeClass >> #plsNavIncrement).
	"One call per selector sent: #+ to an unknown receiver goes to one of its implementors"
	self assert: calls size equals: 2.
	self assert: (calls anySatisfy: [ :each |
			 ((each at: #to) at: #name) = 'PLSNavigationProbe>>count' ])
]

{ #category : 'tests' }
PLSServerNavigationTest >> testCapabilitiesAnnounceTheNavigation [

	| capabilities |
	capabilities := PLSServerCapabilities forPharo asJRPCJSON.
	#( #referencesProvider #implementationProvider
	   #callHierarchyProvider #typeHierarchyProvider ) do: [ :each |
		self assert: (capabilities at: each) ]
]

{ #category : 'tests' }
PLSServerNavigationTest >> testImplementationOfASelectorListsItsImplementors [

	| locations |
	locations := server
		             textDocumentImplementationWithPosition:
		             (self line: 4 character: 10)
		             textDocument: (self open: probeClass >> #plsNavReset).
	self assert: (self urisOf: locations) equals: {
			(self uriOf: probeClass >> #plsNavIncrement).
			(self uriOf: childClass >> #plsNavIncrement) } asSet.
	self assert: (locations first at: #range) equals: {
			(#start -> (self line: 0 character: 0)).
			(#end -> (self line: 0 character: 15)) } asDictionary
]

{ #category : 'tests' }
PLSServerNavigationTest >> testKeywordOfAClassDefinitionNamesNoClass [

	| textDocument |
	textDocument := self
		                open: (server navUriOfClass: probeClass)
		                text: (server envTonelDefinitionOf: probeClass).
	self
		assert: (self referencesIn: textDocument line: 0 character: 2)
		equals: #(  )
]

{ #category : 'tests' }
PLSServerNavigationTest >> testPositionAtTheEndOfAText [

	self
		assert: (server navPosition: 5 in: 'ab
c')
		equals: (self line: 1 character: 1).
	self
		assert: (server navPosition: 4 in: 'ab
')
		equals: (self line: 1 character: 0).
	self
		assert: (server navPosition: 1 in: '')
		equals: (self line: 0 character: 0)
]

{ #category : 'tests' }
PLSServerNavigationTest >> testReferencesInATonelDocument [

	| text locations |
	text := (server envTonelDefinitionOf: probeClass) , '

{ #category : #probing }
PLSNavigationProbe >> plsNavTwice [
	self plsNavIncrement; plsNavIncrement
]
'.
	locations := self
		             referencesIn:
		             (self
			              open: 'file:///tmp/PLSNavigationProbe.class.st'
			              text: text)
		             line: (text lines findFirst: [ :each |
				              each includesSubstring: 'self plsNavIncrement' ])
			             - 1
		             character: 8.
	self assert: (self urisOf: locations) equals: {
			(self uriOf: probeClass >> #plsNavReset).
			(self uriOf: childClass >> #plsNavIncrement) } asSet
]

{ #category : 'tests' }
PLSServerNavigationTest >> testReferencesIncludeImplementorsAsDeclarations [

	| locations |
	locations := server
		             textDocumentReferencesWithPosition:
		             (self line: 4 character: 10)
		             textDocument: (self open: probeClass >> #plsNavReset)
		             context: { (#includeDeclaration -> true) } asDictionary.
	self assert: (self urisOf: locations) equals: {
			(self uriOf: probeClass >> #plsNavReset).
			(self uriOf: probeClass >> #plsNavIncrement).
			(self uriOf: childClass >> #plsNavIncrement) } asSet
]

{ #category : 'tests' }
PLSServerNavigationTest >> testReferencesOfAClass [

	| user locations |
	childClass
		compile: 'plsNavProbeClass
	^ PLSNavigationProbe'
		classified: 'probing'.
	user := childClass >> #plsNavProbeClass.
	locations := self
		             referencesIn: (self open: user)
		             line: 1
		             character: 5.
	self
		assert: (self urisOf: locations)
		equals: { (self uriOf: user) } asSet.
	self assert: (locations first at: #range) equals: {
			(#start -> (self line: 1 character: 3)).
			(#end -> (self line: 1 character: 21)) } asDictionary
]

{ #category : 'tests' }
PLSServerNavigationTest >> testReferencesOfASelectorAreItsSenders [

	| locations |
	locations := self
		             referencesIn: (self open: probeClass >> #plsNavReset)
		             line: 4
		             character: 10.
	self assert: (self urisOf: locations) equals: {
			(self uriOf: probeClass >> #plsNavReset).
			(self uriOf: childClass >> #plsNavIncrement) } asSet.
	self
		assert: ((locations detect: [ :each |
				  (each at: #uri) = (self uriOf: probeClass >> #plsNavReset) ])
				 at: #range)
		equals: {
				(#start -> (self line: 4 character: 8)).
				(#end -> (self line: 4 character: 23)) } asDictionary
]

{ #category : 'tests' }
PLSServerNavigationTest >> testReferencesOfATemporaryStayInItsDocument [

	| textDocument locations |
	textDocument := self open: probeClass >> #plsNavReset.
	locations := self referencesIn: textDocument line: 2 character: 3.
	self
		assert: (self urisOf: locations)
		equals: { (textDocument at: #uri) } asSet.
	self
		assert:
		(locations collect: [ :each | (each at: #range) at: #start ])
		equals: {
				(self line: 1 character: 3).
				(self line: 2 character: 1) }
]

{ #category : 'tests' }
PLSServerNavigationTest >> testReferencesOfAnInstanceVariableCoverItsSubclasses [

	| locations |
	locations := self
		             referencesIn: (self open: probeClass >> #plsNavReset)
		             line: 3
		             character: 2.
	self assert: (self urisOf: locations) equals: {
			(self uriOf: probeClass >> #count).
			(self uriOf: probeClass >> #plsNavIncrement).
			(self uriOf: probeClass >> #plsNavReset).
			(self uriOf: childClass >> #plsNavIncrement) } asSet.
	self assert: locations size equals: 5
]

{ #category : 'tests' }
PLSServerNavigationTest >> testReferencesOfAnInstanceVariableFromItsClassDefinition [

	| text locations |
	text := server envTonelDefinitionOf: probeClass.
	locations := self
		             referencesIn:
		             (self
			              open: (server navUriOfClass: probeClass)
			              text: text)
		             line:
			             (text lines findFirst: [ :each |
				              each includesSubstring: '''count''' ]) - 1
		             character: 3.
	self assert: (self urisOf: locations) equals: {
			(self uriOf: probeClass >> #count).
			(self uriOf: probeClass >> #plsNavIncrement).
			(self uriOf: probeClass >> #plsNavReset).
			(self uriOf: childClass >> #plsNavIncrement) } asSet
]

{ #category : 'tests' }
PLSServerNavigationTest >> testReferencesOfNothingAreEmpty [

	self
		assert: (self
				 referencesIn: (self open: probeClass >> #plsNavReset)
				 line: 4
				 character: 3)
		equals: #(  )
]

{ #category : 'tests' }
PLSServerNavigationTest >> testTypeHierarchyOfAClassInATonelDocument [

	| textDocument items |
	textDocument := self
		                open: 'file:///tmp/PLSNavigationProbe.class.st'
		                text: (server envTonelDefinitionOf: probeClass).
	items := server
		         typeHierarchyPrepareWithPosition:
		         (self line: 0 character: 0)
		         textDocument: textDocument.
	self
		assert: (items collect: [ :each | each at: #name ])
		equals: #( #PLSNavigationProbe ).
	self
		assert: (items first at: #uri)
		equals: (server navUriOfClass: probeClass).
	self
		assert:
			((server typeHierarchySupertypes: items first) collect: [ :each |
				 each at: #name ])
		equals: #( #Object ).
	self
		assert:
			((server typeHierarchySubtypes: items first) collect: [ :each |
				 each at: #name ])
		equals: #( #PLSNavigationProbeChild )
]

{ #category : 'tests' }
PLSServerNavigationTest >> testTypeHierarchyOfAMethodIsTheOneOfItsClass [

	| items |
	items := server
		         typeHierarchyPrepareWithPosition:
		         (self line: 1 character: 2)
		         textDocument: (self open: childClass >> #plsNavIncrement).
	self
		assert: (items collect: [ :each | each at: #name ])
		equals: #( #PLSNavigationProbeChild ).
	self
		assert:
			((server typeHierarchySubtypes: items first) collect: [ :each |
				 each at: #name ])
		equals: #(  )
]

{ #category : 'running' }
PLSServerNavigationTest >> uriOf: aMethod [

	^ server navUriOfMethod: aMethod
]

{ #category : 'running' }
PLSServerNavigationTest >> urisOf: locations [
	"Answer the URIs of the locations in the probe package. The tests also refer to the probe selectors"

	^ (locations
		   collect: [ :each | each at: #uri ]
		   thenSelect: [ :uri |
		   uri includesSubstring: '/' , self probePackageName , '/' ]) asSet
]
