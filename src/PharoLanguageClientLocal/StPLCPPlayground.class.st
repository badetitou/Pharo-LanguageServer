Class {
	#name : #StPLCPPlayground,
	#superclass : #StPlayground,
	#category : #'PharoLanguageClientLocal-GraphicalStack'
}

{ #category : #'world menu' }
StPLCPPlayground class >> defaultTitle [ 

	^ 'AI.Playground'
]

{ #category : #'world menu' }
StPLCPPlayground class >> menuCommandOn: aBuilder [

	<worldMenu>
	(aBuilder item: #'AI.Playground')
		parent: #PharoLanguageClient;
		action: [ self open ];
		order: 1;
		keyText: 'a, w';
		help:
			'A window used as a scratchpad area where fragments of Pharo code can be entered, stored, edited, and evaluated.';
		icon: (self iconNamed: #workspace)
]

{ #category : #'world menu' }
StPLCPPlayground class >> open [

	<script>
	^ self new open
]

{ #category : #'private - factory' }
StPLCPPlayground >> newDefaultPlaygroundPage [

	^ StPLCPPlaygroundPage new
]
