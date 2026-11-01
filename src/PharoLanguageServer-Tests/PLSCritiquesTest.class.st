"
I test the Renraku critiques of the documents: their diagnostics, their quick fixes and their bans.
"
Class {
	#name : 'PLSCritiquesTest',
	#superclass : 'TestCase',
	#instVars : [
		'server',
		'probeClass'
	],
	#category : 'PharoLanguageServer-Tests',
	#package : 'PharoLanguageServer-Tests'
}

{ #category : 'helpers' }
PLSCritiquesTest >> codeActionsOf: aUri [

	^ server
		  codeActionForDocument: { (#uri -> aUri) } asDictionary
		  atRange: nil
		  withContext: { (#diagnostics
			   -> (server diagnosticsOf: (server context textItem: aUri))) }
				  asDictionary
]

{ #category : 'helpers' }
PLSCritiquesTest >> critiquesIn: aDocument [

	^ (server diagnosticsOf: aDocument) select: [ :each |
		  (each at: #source) = 'Renraku' ]
]

{ #category : 'helpers' }
PLSCritiquesTest >> haltCritiqueIn: aDocument [

	^ (self critiquesIn: aDocument) detect: [ :each |
		  (each at: #code) = ReCodeCruftLeftInMethodsRule name ]
]

{ #category : 'helpers' }
PLSCritiquesTest >> haltSource [

	^ 'foo
	self halt.
	^ 1 + 2' withLineEndings: String lf
]

{ #category : 'helpers' }
PLSCritiquesTest >> methodUri [

	^ 'pharo:/img/' , self probePackageName
	  , '/PLSCritiquesProbe/instance/foo.st'
]

{ #category : 'helpers' }
PLSCritiquesTest >> open: aUri text: aString [

	^ server openDocument: {
			  (#uri -> aUri).
			  (#version -> 1).
			  (#text -> aString).
			  (#languageId -> 'pharo') } asDictionary
]

{ #category : 'running' }
PLSCritiquesTest >> probePackageName [

	^ 'PharoLanguageServer-CritiquesProbe'
]

{ #category : 'running' }
PLSCritiquesTest >> setUp [

	super setUp.
	server := PLSServer new.
	server clientOutStream: (WriteStream on: ByteArray new).
	server context clientContext: (PLPInitializeParams new
			 capabilities: (PLPClientCapabilities from: {
							  (#textDocument
							   -> { (#diagnostic -> Dictionary new) } asDictionary).
							  (#workspace -> Dictionary new) } asDictionary);
			 yourself).
	probeClass := (Object << #PLSCritiquesProbe)
		              package: self probePackageName;
		              install.
	probeClass comment: 'A probe for PLSCritiquesTest'
]

{ #category : 'running' }
PLSCritiquesTest >> tearDown [

	self packageOrganizer
		packageNamed: self probePackageName
		ifPresent: [ :package | package removeFromSystem ].
	super tearDown
]

{ #category : 'tests' }
PLSCritiquesTest >> testBanForTheMethodIsKeptInTheManifest [

	| document ban |
	probeClass compile: self haltSource classified: 'probe'.
	document := self open: self methodUri text: self haltSource.
	ban := (self codeActionsOf: self methodUri) detect: [ :each |
		       (each at: #title) includesSubstring: 'for method' ].
	server
		executeCommand: ((ban at: #command) at: #command)
		arguments: ((ban at: #command) at: #arguments)
		workDoneToken: nil.
	self assert: probeClass package packageManifestOrNil notNil.
	self deny: ((self critiquesIn: document) anySatisfy: [ :each |
			 (each at: #code) = ReCodeCruftLeftInMethodsRule name ])
]

{ #category : 'tests' }
PLSCritiquesTest >> testCritiquesAreNotComputedWhileTyping [

	| document |
	document := self open: self methodUri text: 'foo
	^ 1'.
	self assertEmpty: (self critiquesIn: document).
	document text: self haltSource.
	self assertEmpty: (self critiquesIn: document).
	document savedText: self haltSource.
	self denyEmpty: (self critiquesIn: document)
]

{ #category : 'tests' }
PLSCritiquesTest >> testDisabledCritiquesAreNotShown [

	| document |
	document := self open: self methodUri text: self haltSource.
	server didChangeConfiguration: { (#pharo
		 ->
		 { (#critiques -> { (#enabled -> false) } asDictionary) }
			 asDictionary) } asDictionary.
	self assertEmpty: (self critiquesIn: document).
	self assertEmpty: (self codeActionsOf: self methodUri)
]

{ #category : 'tests' }
PLSCritiquesTest >> testHaltHasAQuickFixRemovingIt [

	| fix edit |
	self open: self methodUri text: self haltSource.
	fix := (self codeActionsOf: self methodUri) detect: [ :each |
		       each includesKey: #edit ].
	self assert: (fix at: #kind) equals: 'quickfix'.
	edit := ((fix at: #edit) at: #changes) at: self methodUri.
	self assert: edit size equals: 1.
	self deny: ((edit first at: #newText) includesSubstring: 'halt').
	self assert: ((edit first at: #newText) includesSubstring: '^ 1 + 2')
]

{ #category : 'tests' }
PLSCritiquesTest >> testHaltIsAWarningOfRenraku [

	| critique |
	critique := self haltCritiqueIn:
		            (self open: self methodUri text: self haltSource).
	self assert: (critique at: #severity) equals: 2.
	self assert: (critique at: #source) equals: 'Renraku'
]

{ #category : 'tests' }
PLSCritiquesTest >> testNoQuickFixOnceTheTextChanged [

	| document diagnostics actions |
	document := self open: self methodUri text: self haltSource.
	diagnostics := server diagnosticsOf: document.
	document text: self haltSource , ' '.
	actions := server
		           codeActionForDocument:
		           { (#uri -> self methodUri) } asDictionary
		           atRange: nil
		           withContext:
		           { (#diagnostics -> diagnostics) } asDictionary.
	self denyEmpty: actions.
	self deny: (actions anySatisfy: [ :each | each includesKey: #edit ])
]

{ #category : 'tests' }
PLSCritiquesTest >> testParseErrorStaysAnError [

	| diagnostics |
	diagnostics := server diagnosticsOf:
		               (self open: self methodUri text: 'foo ^ (').
	self denyEmpty: diagnostics.
	self assert:
		(diagnostics allSatisfy: [ :each | (each at: #severity) = 1 ])
]

{ #category : 'tests' }
PLSCritiquesTest >> testTonelMethodCritiqueIsOnItsLines [

	| document critique text fix edit |
	text := 'Class {
	#name : #PLSCritiquesProbe,
	#superclass : #Object,
	#category : #''PharoLanguageServer-CritiquesProbe''
}

{ #category : #accessing }
PLSCritiquesProbe >> foo [
	self halt.
	^ 1 + 2
]
' withLineEndings: String lf.
	document := self open: self tonelUri text: text.
	critique := self haltCritiqueIn: document.
	self assert: (((critique at: #range) at: #start) at: #line) equals: 8.
	fix := (self codeActionsOf: self tonelUri) detect: [ :each |
		       each includesKey: #edit ].
	edit := (((fix at: #edit) at: #changes) at: self tonelUri) first.
	self
		assert: (text
				 copyReplaceFrom:
				 (text plsToPosition: ((edit at: #range) at: #start)) + 1
				 to: (text plsToPosition: ((edit at: #range) at: #end))
				 with: (edit at: #newText))
		equals: (text
				 copyReplaceAll: (String with: Character tab) , 'self halt.'
				 with: '')
]

{ #category : 'helpers' }
PLSCritiquesTest >> tonelUri [

	^ 'file:///tmp/PLSCritiquesProbe.class.st'
]
