Extension { #name : 'Class' }

{ #category : '*PharoLanguageServer' }
Class >> plsURIString [

	^ 'pharoImage://' , self package name , '/' , self name , '.class.st'
]
