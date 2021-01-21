Extension { #name : #Array }

{ #category : #'*PharoDAP' }
Array >> asDAPJSON [
	^ self collect: #asDAPJSON
]
