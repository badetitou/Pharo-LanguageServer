Extension { #name : 'Metaclass' }

{ #category : '*PharoLanguageServer' }
Metaclass >> plsURIString [

	^ 'pharoImage:/' , self package name , '/' , self instanceSide name
	  , '.class.st'
]
