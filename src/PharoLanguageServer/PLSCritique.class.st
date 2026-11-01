"
I am a Renraku critique of a document. I answer the diagnostic that shows me, the code action that applies my transformation, and the code actions that ban my rule.
My stamp names the computation of the critiques of my document, so that a code action of former critiques is not applied to new ones.
"
Class {
	#name : 'PLSCritique',
	#superclass : 'Object',
	#instVars : [
		'critique',
		'critiqueSource',
		'index',
		'stamp'
	],
	#classVars : [
		'NextStamp'
	],
	#category : 'PharoLanguageServer-Structure-Diagnostic',
	#package : 'PharoLanguageServer',
	#tag : 'Structure-Diagnostic'
}

{ #category : 'instance creation' }
PLSCritique class >> critique: aCritique source: aCritiqueSource index: anInteger stamp: aStamp [

	^ self new
		  setCritique: aCritique
		  source: aCritiqueSource
		  index: anInteger
		  stamp: aStamp
]

{ #category : 'instance creation' }
PLSCritique class >> nextStamp [
	"Answer a stamp for a new computation of the critiques of a document"

	^ NextStamp := (NextStamp ifNil: [ 0 ]) + 1
]

{ #category : 'code actions' }
PLSCritique >> banActionsFor: aUri [
	"Answer the code actions banning my rule for one of the entities that can ban it, as the ban of Pharo does.
	 The ban is kept in the manifest of the package"

	^ self banEntities withIndexCollect: [ :entity :level |
			  | title |
			  title := 'Ignore "' , self title , '" for '
			           , (self labelOf: entity).
			  PLSCodeAction new
				  title: title;
				  kind: PLSCodeActionKind quickfix;
				  diagnostics: { self diagnostic };
				  command: (PLSCommand new
						   title: title;
						   command: PLSServer critiquesBanCommand;
						   arguments: {
								   aUri.
								   stamp.
								   index.
								   level };
						   yourself);
				  yourself ]
]

{ #category : 'code actions' }
PLSCritique >> banAt: aLevel [
	"Ban my rule for the entity at aLevel of my banEntities"

	(self banEntities at: aLevel) ban: critique
]

{ #category : 'code actions' }
PLSCritique >> banEntities [
	"Answer the method, class and package that can ban my rule in the manifest of their package"

	| entity class |
	entity := critiqueSource bannableEntity.
	class := entity isCompiledMethod
		         ifTrue: [ entity methodClass ]
		         ifFalse: [ entity ].
	^ (entity isCompiledMethod
		   ifTrue: [ { entity } ]
		   ifFalse: [ #(  ) ]) , {
		  class instanceSide.
		  class package }
]

{ #category : 'accessing' }
PLSCritique >> critique [

	^ critique
]

{ #category : 'converting' }
PLSCritique >> diagnostic [
	"Answer the diagnostic showing me. Its source and its code, the class of my rule, tell it from the errors of compilation.
	 Its data lets a code action find me back"

	^ PLSDiagnostic new
		  message: self message;
		  range: (critiqueSource rangeOf: critique);
		  severity: self severity;
		  source: 'Renraku';
		  code: critique rule class name asString;
		  data: {
				  (#critique -> index).
				  (#stamp -> stamp) } asDictionary;
		  yourself
]

{ #category : 'code actions' }
PLSCritique >> fixActionFor: aUri [
	"Answer the code action applying the transformation of my critique to the document aUri, or nil if it provides none"

	| change |
	critique providesChange ifFalse: [ ^ nil ].
	change := [ critique change ]
		          on: Error
		          do: [ ^ nil ].
	(change isKindOf: RBAddMethodChange) ifFalse: [ ^ nil ].
	^ PLSCodeAction new
		  title: 'Fix: ' , self title;
		  kind: PLSCodeActionKind quickfix;
		  isPreferred: true;
		  diagnostics: { self diagnostic };
		  edit: (PLSWorkspaceEdit new
				   changes:
					   { (aUri -> { (critiqueSource textEditFor: change source) }) }
						   asDictionary;
				   yourself);
		  yourself
]

{ #category : 'accessing' }
PLSCritique >> index [

	^ index
]

{ #category : 'code actions' }
PLSCritique >> labelOf: anEntity [

	anEntity isCompiledMethod ifTrue: [
		^ 'method ' , anEntity printString ].
	anEntity isBehavior ifTrue: [ ^ 'class ' , anEntity name ].
	^ 'package ' , anEntity name
]

{ #category : 'converting' }
PLSCritique >> message [

	| hint |
	hint := [ critique tinyHint ]
		        on: Error
		        do: [ nil ].
	^ (hint isNil or: [ hint isEmpty ])
		  ifTrue: [ self title ]
		  ifFalse: [ self title , ' (' , hint asString , ')' ]
]

{ #category : 'initialization' }
PLSCritique >> setCritique: aCritique source: aCritiqueSource index: anInteger stamp: aStamp [

	critique := aCritique.
	critiqueSource := aCritiqueSource.
	index := anInteger.
	stamp := aStamp
]

{ #category : 'converting' }
PLSCritique >> severity [
	"Answer the LSP severity of my rule. A critique is never shown as an error, which is kept for compilation"

	^ critique rule severity = #information
		  ifTrue: [ 3 ]
		  ifFalse: [ 2 ]
]

{ #category : 'accessing' }
PLSCritique >> stamp [

	^ stamp
]

{ #category : 'accessing' }
PLSCritique >> title [

	^ critique title asString
]
