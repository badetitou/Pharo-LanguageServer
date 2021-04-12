Class {
	#name : #PLSTonelDocument,
	#superclass : #PLSDocument,
	#category : #'PharoLanguageServer-Document'
}

{ #category : #'instance creation' }
PLSTonelDocument class >> fromDocumentDictionary: aDocumentDictionary [
	^ self new
		version: (aDocumentDictionary at: #version);
		text: (aDocumentDictionary at: #text);
		languageId: (aDocumentDictionary at: #languageId);
		uri: (aDocumentDictionary at: #uri);
		yourself
]

{ #category : #accessing }
PLSTonelDocument >> codeLens [
	| parsed className |
	[ parsed := self parsed ]
		on: Error
		do: [ ^ {} ].
	parsed
		detect: #isClassDefinition
		ifFound: [ :classDef |
			className := classDef name. 
			(classDef name endsWith: #Test)
				ifFalse: [ ^ {} ] ]
		ifNone: [ ^ {} ].
	^ ((parsed
		select: [ :el | el isMethodDefinition and: [ el selector beginsWith: #test ] ]
		thenCollect: [ :methodDef | 
			PLSCodeLens new
				range:
					(PLSRange
						start: (self text toLineCharacter: methodDef startPos + 1)
						end: (self text toLineCharacter: methodDef startPos + 1));
				command:
					(PLSCommand new
						title: #'Run Test';
						command: #'pharo.executeTest';
						arguments:
							{methodDef className.
							methodDef selector} yourself);
				yourself ]) asOrderedCollection 
		,
			{(PLSCodeLens new
				range:
					(PLSRange
						start: (self text toLineCharacter: 0)
						end: (self text toLineCharacter: 0));
				command:
					(PLSCommand new
						title: #'Run Class Tests';
						command: #'pharo.executeClassTests';
						arguments: {className}))}) asArray
]

{ #category : #testing }
PLSTonelDocument >> isTonelDocument [
	^ true
]

{ #category : #private }
PLSTonelDocument >> parsed [
	^ PLSTonelParser parseString: self text
]
