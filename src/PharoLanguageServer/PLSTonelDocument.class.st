Class {
	#name : 'PLSTonelDocument',
	#superclass : 'PLSDocument',
	#category : 'PharoLanguageServer-Document',
	#package : 'PharoLanguageServer',
	#tag : 'Document'
}

{ #category : 'instance creation' }
PLSTonelDocument class >> fromDocumentDictionary: aDocumentDictionary [
	^ self new
		version: (aDocumentDictionary at: #version);
		text: (aDocumentDictionary at: #text);
		languageId: (aDocumentDictionary at: #languageId);
		uri: (aDocumentDictionary at: #uri);
		yourself
]

{ #category : 'lsp - accessing' }
PLSTonelDocument >> codeLens [

	| parsed className |
	[ parsed := self parsed ]
		on: Error
		do: [ ^ {  } ].
	parsed
		detect: #isClassDefinition
		ifFound: [ :classDef | 
			className := classDef className.
			(className endsWith: #Test) ifFalse: [ ^ {  } ] ]
		ifNone: [ ^ {  } ].
	^ ((parsed
		    select: [ :el | 
			    el isMethodDefinition and: [ 
				    el isErrorDefinition not and: [ el selector beginsWith: #test ] ] ]
		    thenCollect: [ :methodDef | 
			    PLSCodeLens new
				    range: (PLSRange
						     start: (self text toLineCharacter: methodDef startPos + 1)
						     end: (self text toLineCharacter: methodDef startPos + 1));
				    command: (PLSCommand new
						     title: #'Run Test';
						     command: #'pharo.executeTest';
						     arguments: { 
								     methodDef className.
								     methodDef selector } yourself);
				    yourself ]) asOrderedCollection , { (PLSCodeLens new
		    range: (PLSRange
				     start: (self text toLineCharacter: 0)
				     end: (self text toLineCharacter: 0));
		    command: (PLSCommand new
				     title: #'Run Class Tests';
				     command: #'pharo.executeClassTests';
				     arguments: { className })) }) asArray
]

{ #category : 'lsp - accessing' }
PLSTonelDocument >> diagnostics [

	| diagnostics parsed |
	parsed := self parsed.
	diagnostics := (parsed
		                select: [ :el | el isMethodDefinition and: [ el isErrorDefinition ] ]
		                thenCollect: [ :errorDef | 
			                PLSDiagnostic new
				                message: #'error in method definition';
				                range: (PLSRange start: (self text toLineCharacter: errorDef startPos) end: (self text toLineCharacter: errorDef endPos)) ])
		               asOrderedCollection.
	diagnostics addAll: (parsed
			 select: [ :el | el isMethodDefinition and: [ el isErrorDefinition not ] ]
			 thenCollect: [ :el | 
				 ((PLSDiagnosticsParamsEngine new
					   document: self;
					   source: el source;
					   sourceIsMethod: true;
					   yourself) requestor: self binder) computeDiagnostics diagnostics collect: [ :diag | 
					 | lineCharMethod |
					 lineCharMethod := self text toLineCharacter: el startPos.
					 diag range start at: #line put: (diag range start at: #line) + (lineCharMethod at: #line) + 2.
					 diag range end at: #line put: (diag range end at: #line) + (lineCharMethod at: #line) + 2.
					 diag ] ]).
	^ (PLSPublishDiagnosticsParams new
		   diagnostics: diagnostics flattened asArray asJRPCJSON;
		   uri: self uri;
		   version: self version;
		   yourself) asJRPCJSON
]

{ #category : 'testing' }
PLSTonelDocument >> isTonelDocument [
	^ true
]

{ #category : 'lsp - accessing' }
PLSTonelDocument >> nodeAt: aPosition [

	| charPos parsed methodDefinition |
	charPos := self text plsToPosition: aPosition.
	[ parsed := self parsed ]
		on: Error
		do: [ 
			^ RGDefinition new
				  name: '';
				  yourself ].
	methodDefinition := parsed
		                    detect: [ :el | el isMethodDefinition and: [ el startPos < charPos and: [ el endPos > charPos ] ] ]
		                    ifNone: [ 
			                    ^ RGDefinition new
				                      name: '';
				                      yourself ].
	^ (RBParser parseFaultyExpression: methodDefinition source) bestNodeFor: (Interval
			   from: charPos - methodDefinition bodyStartPos + methodDefinition selector size - 1
			   to: charPos - methodDefinition bodyStartPos + methodDefinition selector size - 1)
]

{ #category : 'private' }
PLSTonelDocument >> parsed [
	^ PLSTonelParser parseString: self text
]

{ #category : 'lsp - accessing' }
PLSTonelDocument >> symbols [
	| parsed classDef children |
	[ parsed := self parsed ]
		on: Error
		do: [ ^ {} ].
	classDef := parsed detect: #isClassDefinition ifNone: [ ^ {} ].
	children := (parsed
		select: [ :el | el isMethodDefinition and: [ el isErrorDefinition not ] ]
		thenCollect: [ :methodDef | 
			PLSDocumentSymbol new
				name: methodDef selector;
				kind: PLSSymbolKind method;
				range:
					(PLSRange
						start: (self text toLineCharacter: methodDef startPos + 1)
						end: (self text toLineCharacter: methodDef endPos + 1));
				selectionRange:
					(PLSRange
						start: (self text toLineCharacter: methodDef startPos + 1)
						end: (self text toLineCharacter: methodDef endPos + 1));
				yourself ]) asArray.
	^ {(PLSDocumentSymbol new
		name: classDef className;
		kind: PLSSymbolKind classID;
		range:
			(PLSRange
				start: (PLSPosition line: 0 character: 0)
				end: (self text toLineCharacter: self text size) );
		selectionRange:
			(PLSRange
				start: (PLSPosition line: 0 character: 0)
				end: (PLSPosition line: 6 character: 1));
		children: children;
		yourself)}
]
