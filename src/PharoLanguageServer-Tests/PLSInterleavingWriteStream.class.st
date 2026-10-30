"
I am a write stream that yields the processor after each element I write.

I let tests check that messages written by concurrent processes are not interleaved.
"
Class {
	#name : 'PLSInterleavingWriteStream',
	#superclass : 'WriteStream',
	#category : 'PharoLanguageServer-Tests',
	#package : 'PharoLanguageServer-Tests'
}

{ #category : 'writing' }
PLSInterleavingWriteStream >> nextPutAll: aCollection [

	aCollection do: [ :each |
		self nextPut: each.
		Processor yield ].
	^ aCollection
]
