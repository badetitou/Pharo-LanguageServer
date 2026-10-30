"
I am the source of one method of the image, opened by the client as an entity document.
My URI is pharo:/<image>/<package>/<class>/<side>/<selector>.st, where side is instance or class and each segment is percent-encoded. It tells me the class and the side the method belongs to, so that completion knows self, super and the instance variables.
I am read with pls-env:read and saved with pls-env:compile.
"
Class {
	#name : 'PLSMethodDocument',
	#superclass : 'PLSDocument',
	#category : 'PharoLanguageServer-Document',
	#package : 'PharoLanguageServer',
	#tag : 'Document'
}

{ #category : 'testing' }
PLSMethodDocument class >> behaviorPathFromUri: aUri [
	"Answer the name of the class of the method document aUri, followed by ' class' for its class side, or nil if aUri is not a method document"

	| uri segments side |
	uri := self extractUriFrom: aUri.
	((uri beginsWith: 'pharo:') and: [
			 (uri endsWith: '.class.st') not and: [
				 (uri endsWith: '.extension.st') not and: [ uri endsWith: '.st' ] ] ])
		ifFalse: [ ^ nil ].
	segments := (uri allButFirst: 6) substrings: '/'.
	segments size < 3 ifTrue: [ ^ nil ].
	side := ZnPercentEncoder new decode: (segments at: segments size - 1).
	(#( 'instance' 'class' ) includes: side) ifFalse: [ ^ nil ].
	^ (ZnPercentEncoder new decode: (segments at: segments size - 2))
	  , (side = 'class'
			   ifTrue: [ ' class' ]
			   ifFalse: [ '' ])
]

{ #category : 'testing' }
PLSMethodDocument class >> supportDocument: aTextDocument [

	^ self supportDocumentUri: (aTextDocument at: #uri)
]

{ #category : 'testing' }
PLSMethodDocument class >> supportDocumentUri: aTextDocumentUri [

	^ (self behaviorPathFromUri: aTextDocumentUri) notNil
]

{ #category : 'accessing' }
PLSMethodDocument >> behavior [
	"Answer the class or metaclass of my method, or nil if the image does not hold it"

	| path class |
	path := self class behaviorPathFromUri: self uri.
	path ifNil: [ ^ nil ].
	class := self class environment classOrTraitNamed:
		         (path withoutSuffix: ' class').
	(class isNil or: [ class isClassSide ]) ifTrue: [ ^ nil ].
	^ (path endsWith: ' class')
		  ifTrue: [ class classSide ]
		  ifFalse: [ class ]
]

{ #category : 'accessing' }
PLSMethodDocument >> completionClass [

	^ self behavior
]

{ #category : 'accessing' }
PLSMethodDocument >> diagnostics [

	(self text isNil or: [ self text isEmpty ]) ifTrue: [
		^ {  } asArray asJRPCJSON ].
	^ ((PLSDiagnosticsParamsEngine new
		    document: self;
		    source: self text;
		    sourceIsMethod: true;
		    yourself) requestor: self binder) computeDiagnostics asArray
		  asJRPCJSON
]

{ #category : 'accessing' }
PLSMethodDocument >> formattedText [

	^ (RBParser parseMethod: self text) formattedCode
]

{ #category : 'accessing' }
PLSMethodDocument >> isMethodSource [

	^ true
]

{ #category : 'accessing' }
PLSMethodDocument >> nodeAt: aPosition [

	| positionChar |
	positionChar := self text plsToPosition: aPosition.
	^ (RBParser parseFaultyMethod: self text) bestNodeFor:
		  (Interval from: positionChar to: positionChar)
]

{ #category : 'accessing' }
PLSMethodDocument >> symbols [

	| ast |
	ast := RBParser parseFaultyMethod: self text.
	ast isFaulty ifTrue: [ ^ {  } ].
	^ { (PLSDocumentSymbol new
		   name: ast selector;
		   kind: PLSSymbolKind method;
		   range: (PLSRange
				    start: (PLSPosition line: 0 character: 0)
				    end: (self text toLineCharacter: self text size));
		   selectionRange: (PLSRange
				    start: (PLSPosition line: 0 character: 0)
				    end: (self text toLineCharacter: self text lines first size));
		   yourself) }
]
