Extension { #name : #Dictionary }

{ #category : #'*PharoDAP' }
Dictionary >> asDAPJSON [
	^ (self associations collect: [ :assoc |
		self assert: assoc key isString.
		assoc key -> assoc value asDAPJSON ]) asDictionary
]
