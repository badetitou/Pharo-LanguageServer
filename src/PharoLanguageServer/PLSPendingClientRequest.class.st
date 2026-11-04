"
I am a request the language server sent to the client and whose answer a process of the image waits for (PLSAbstractServer>>sendRequestAndWait:params:).

The process that reads the messages of the client gives me the result (#answer:) or the error (#fail:) of the response; #cancel releases the waiting process without an answer. #wait answers the result, or signals PLSClientRequestFailed.
"
Class {
	#name : 'PLSPendingClientRequest',
	#superclass : 'Object',
	#instVars : [
		'semaphore',
		'result',
		'error',
		'answered'
	],
	#category : 'PharoLanguageServer-Messaging',
	#package : 'PharoLanguageServer',
	#tag : 'Messaging'
}

{ #category : 'answering' }
PLSPendingClientRequest >> answer: anObject [
	"The client answered anObject"

	self settle: [ result := anObject ]
]

{ #category : 'answering' }
PLSPendingClientRequest >> cancel [
	"Release the waiting process without an answer of the client"

	self settle: [
			error := Dictionary new
				         at: 'message' put: 'The request was cancelled';
				         yourself ]
]

{ #category : 'answering' }
PLSPendingClientRequest >> fail: aDictionary [
	"The client answered the error aDictionary ({code, message})"

	self settle: [ error := aDictionary ]
]

{ #category : 'initialization' }
PLSPendingClientRequest >> initialize [

	super initialize.
	semaphore := Semaphore new.
	answered := false
]

{ #category : 'testing' }
PLSPendingClientRequest >> isAnswered [

	^ answered
]

{ #category : 'private' }
PLSPendingClientRequest >> outcome [

	error ifNotNil: [
		^ PLSClientRequestFailed new
			  code: (error at: 'code' ifAbsent: [ nil ]);
			  signal: (error at: 'message' ifAbsent: [ 'The client failed' ]) asString ].
	^ result
]

{ #category : 'private' }
PLSPendingClientRequest >> settle: aBlock [
	"Keep the first answer only, and release the waiting process"

	answered ifTrue: [ ^ self ].
	answered := true.
	aBlock value.
	semaphore signal
]

{ #category : 'waiting' }
PLSPendingClientRequest >> wait [
	"Wait for the answer of the client, and answer its result. Signal PLSClientRequestFailed when it answered an error or the request was cancelled"

	semaphore wait.
	^ self outcome
]

{ #category : 'waiting' }
PLSPendingClientRequest >> waitAtMost: aDuration [
	"Like #wait, but give up after aDuration, as for a cancelled request"

	(semaphore waitTimeoutMilliseconds: aDuration asMilliSeconds) ifTrue: [
		"An answer that came meanwhile signaled the semaphore already, else #cancel does"
		self cancel.
		semaphore wait ].
	^ self outcome
]
