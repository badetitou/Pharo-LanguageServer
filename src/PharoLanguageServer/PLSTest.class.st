"
# PLSTest

methods:

- testMethod
- anotherMethod

"
Class {
	#name : #PLSTest,
	#superclass : #Object,
	#category : #'PharoLanguageServer-Tests'
}

{ #category : #'field definition' }
PLSTest >> anotherMethod: bla anotherAttribute: blabla [
	Object new.
	^ 3
]

{ #category : #'field definition' }
PLSTest >> testMethod [
	"A new method"
    Object.
	^ 2
]
