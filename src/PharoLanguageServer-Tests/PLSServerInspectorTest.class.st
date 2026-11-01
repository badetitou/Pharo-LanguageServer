"
I test the pls-inspector:* requests of PLSServer, with which a client inspects objects of the image and navigates through their views.
"
Class {
	#name : 'PLSServerInspectorTest',
	#superclass : 'TestCase',
	#instVars : [
		'server'
	],
	#category : 'PharoLanguageServer-Tests',
	#package : 'PharoLanguageServer-Tests'
}

{ #category : 'helpers' }
PLSServerInspectorTest >> evaluate: expression [

	^ server
		  inspectorEvaluate: expression
		  textDocumentURI: nil
		  receiver: nil
]

{ #category : 'helpers' }
PLSServerInspectorTest >> itemsOf: aPage [

	^ aPage at: #items
]

{ #category : 'running' }
PLSServerInspectorTest >> setUp [

	super setUp.
	server := PLSServer new
]

{ #category : 'running' }
PLSServerInspectorTest >> tearDown [

	server inspectorRelease: nil all: true.
	super tearDown
]

{ #category : 'tests' }
PLSServerInspectorTest >> testASyntaxErrorAnswersInvalidParams [

	| response |
	response := [ self evaluate: '1 +' ]
		            on: JRPCError
		            do: [ :error | error asJRPCResponseWithId: 1 ].
	self assert: response error code equals: -32602
]

{ #category : 'tests' }
PLSServerInspectorTest >> testAnErrorIsTheResultOfTheEvaluation [

	| description |
	description := self evaluate: '1/0'.
	self assert: (description at: #className) equals: 'ZeroDivide'.
	self assert: (description at: #error) notEmpty
]

{ #category : 'tests' }
PLSServerInspectorTest >> testCapabilitiesAnnounceTheInspector [

	self
		assert:
			((PLSServerCapabilities forPharo experimental at: #'pls-inspector')
				 at: #version)
		equals: 1
]

{ #category : 'tests' }
PLSServerInspectorTest >> testEvaluateDescribesTheResult [

	| description |
	description := self evaluate: '3 @ 4'.
	self assert: (description at: #className) equals: 'Point'.
	self assert: (description at: #printString) equals: '(3@4)'.
	self assert: (description at: #hasChildren).
	self assert: (description at: #error) isNil.
	self
		assert: ((description at: #views) collect: [ :view | view at: #id ])
		equals: #( 'raw' 'meta' )
]

{ #category : 'tests' }
PLSServerInspectorTest >> testEvaluateWithAReceiverBindsSelf [

	| point result |
	point := self evaluate: '3 @ 4'.
	result := server
		          inspectorEvaluate: 'self x + 1'
		          textDocumentURI: nil
		          receiver: (point at: #ref).
	self assert: (result at: #printString) equals: '4'
]

{ #category : 'tests' }
PLSServerInspectorTest >> testItemsViewIsATable [

	| description view |
	description := self evaluate: '#(10 $a)'.
	self
		assert:
		((description at: #views) collect: [ :each | each at: #id ]) first
		equals: 'inspectionItems:'.
	view := server
		        inspectorView: (description at: #ref)
		        view: 'inspectionItems:'
		        offset: nil
		        limit: nil.
	self assert: (view at: #kind) equals: 'table'.
	self assert: (view at: #columns) equals: #( 'Index' 'Value' ).
	self
		assert: ((self itemsOf: view) collect: [ :item | item at: #cells ])
		equals: #( #( '1' '10' ) #( '2' '$a' ) ).
	self
		assert: ((self itemsOf: view) last at: #className)
		equals: 'Character'
]

{ #category : 'tests' }
PLSServerInspectorTest >> testMetaViewListsTheClassHierarchy [

	| view |
	view := server
		        inspectorView: ((self evaluate: '3 @ 4') at: #ref)
		        view: 'meta'
		        offset: nil
		        limit: nil.
	self assert: (view at: #kind) equals: 'table'.
	self
		assert: ((self itemsOf: view) collect: [ :item | item at: #name ])
		equals:
			(Point withAllSuperclasses collect: [ :class | class name asString ])
				asArray
]

{ #category : 'tests' }
PLSServerInspectorTest >> testRawViewNavigatesSeveralLevels [

	| smalltalk globals tally |
	smalltalk := self evaluate: 'Smalltalk'.
	globals := (self itemsOf: (server
			             inspectorView: (smalltalk at: #ref)
			             view: 'raw'
			             offset: nil
			             limit: nil)) detect: [ :item |
		           (item at: #name) = 'globals' ].
	self assert: (globals at: #className) equals: 'SystemEnvironment'.
	tally := (self itemsOf:
		          (server
			           inspectorChildren: (globals at: #ref)
			           offset: nil
			           limit: nil)) detect: [ :item |
		         (item at: #name) = 'tally' ].
	self
		assert: (tally at: #printString)
		equals: Smalltalk globals size printString.
	self
		assert:
		((server inspectorInspect: (smalltalk at: #ref)) at: #printString)
		equals: 'Smalltalk'
]

{ #category : 'tests' }
PLSServerInspectorTest >> testReleaseForgetsTheReferences [

	| point response |
	point := self evaluate: '3 @ 4'.
	server inspectorRelease: { (point at: #ref) } all: nil.
	response := [ server inspectorInspect: (point at: #ref) ]
		            on: PLSUnknownEntity
		            do: [ :error | error asJRPCResponseWithId: 1 ].
	self assert: response error code equals: -32602
]

{ #category : 'tests' }
PLSServerInspectorTest >> testTextViewAnswersTheText [

	| view |
	view := server
		        inspectorView: ((self evaluate: '''hello''') at: #ref)
		        view: 'inspectionFullString:'
		        offset: nil
		        limit: nil.
	self assert: (view at: #kind) equals: 'text'.
	self assert: (view at: #text) equals: 'hello'
]

{ #category : 'tests' }
PLSServerInspectorTest >> testViewPagesItsItems [

	| view |
	view := server
		        inspectorView: ((self evaluate: '#(10 20 30 40)') at: #ref)
		        view: 'raw'
		        offset: 1
		        limit: 2.
	self assert: (view at: #total) equals: 4.
	self
		assert:
		((self itemsOf: view) collect: [ :item | item at: #printString ])
		equals: #( '20' '30' )
]
