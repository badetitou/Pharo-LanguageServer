Extension { #name : #RubShoutStylerDecorator }

{ #category : #'*PharoLanguageClientLocal' }
RubShoutStylerDecorator >> defaultStyler [

	^ PLCLTextStyler new
		  view: self;
		  yourself
]
