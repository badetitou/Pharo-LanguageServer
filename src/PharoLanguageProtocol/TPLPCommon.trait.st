Trait {
	#name : 'TPLPCommon',
	#instVars : [
		'currentId',
		'answerLoop',
		'clientInStream',
		'clientOutStream',
		'process',
		'data',
		'answerLoopPriority'
	],
	#category : 'PharoLanguageProtocol',
	#package : 'PharoLanguageProtocol'
}

{ #category : 'plp - answerLoop' }
TPLPCommon >> answerLoopPriority [

	^ answerLoopPriority ifNil: [
		  answerLoopPriority := Processor lowIOPriority ]
]

{ #category : 'accessing' }
TPLPCommon >> answerLoopPriority: anObject [

	answerLoopPriority := anObject
]

{ #category : 'id' }
TPLPCommon >> currentId [

	^ currentId
]

{ #category : 'id' }
TPLPCommon >> currentId: anObject [

	currentId := anObject
]

{ #category : 'plp - answerLoop' }
TPLPCommon >> extractLengthOf: aData [
	(aData beginsWith: 'Content-Length: ')
		ifTrue:
			[ ^ (aData copyFrom: 16 to: (aData indexOf: Character cr)) asInteger ]
		ifFalse: [ ^ -1 ]
]

{ #category : 'plp - answerLoop' }
TPLPCommon >> extractRequestFrom: stream [

	| length startingPoint endPoint result |
	"data is the current buffer state"
	length := -1.
	[ length = -1 and: [ answerLoop ] ] whileTrue: [
		[ data ifEmpty: [ data := (stream next: 25) asString ] ]
			on: ConnectionTimedOut
			do: [ self log: 'timeout but still work' ].
		length := self extractLengthOf: data ].
	startingPoint := data indexOf: ${.
	endPoint := data findCloseBracesFor: startingPoint.
	result := String new: length.
	"three options"
	"startingPoint and endPoint are found"
	(startingPoint ~= 0 and: [ endPoint ~= 0 ]) ifTrue: [
		result := data copyFrom: startingPoint to: endPoint.
		data := data copyFrom: endPoint + 1 to: data size.
		^ result ].
	startingPoint = 0
		ifTrue: [ "none were found"
			stream upTo: ${.
			result at: 1 put: ${.
			self getDatafromPosition: 2 fromSocket: stream in: result ]
		ifFalse: [ "only startingPoint is found"
			(data copyFrom: startingPoint to: data size) withIndexDo: [
				:each
				:index | result at: index put: each ].
			self
				getDatafromPosition: data size - startingPoint + 2
				fromSocket: stream
				in: result ].
	data := ''.
	^ result
]

{ #category : 'plp - answerLoop' }
TPLPCommon >> getDatafromPosition: startingPoint fromSocket: clientSocket in: existingData [
	clientSocket nextInto: existingData startingAt: startingPoint
]

{ #category : 'plp - send message' }
TPLPCommon >> getHeaderFor: answer into: aStream [

	aStream << 'Content-Length: ' << answer size asString << String crlf
	<< String crlf
]

{ #category : 'plp - answerLoop' }
TPLPCommon >> handleRequest: request toClient: outputStream [

	self explicitRequirement
]

{ #category : 'plp - answerLoop' }
TPLPCommon >> log: aString [

	aString record
]

{ #category : 'id' }
TPLPCommon >> nextId [

	^ currentId := currentId + 1
]

{ #category : 'plp - base protocol' }
TPLPCommon >> sendCancelRequest: id [

	self notifyMethod: '$/cancelRequest' arguments: (PLPCancelParams new
			 id: id;
			 yourself) asJRPCJSON
]

{ #category : 'plp - answerLoop' }
TPLPCommon >> startAnswerLoop [

	process := [
	           [ answerLoop ] whileTrue: [
		           | request |
		           request := self extractRequestFrom: clientInStream.
		           ('Request: ' , request) recordDebug.
		           self handleRequest: request toClient: clientOutStream ] ]
		           forkAt: self answerLoopPriority
		           named: 'JRPC TCP connection'
]

{ #category : 'plp - answerLoop' }
TPLPCommon >> stopAnswerLoop [

	answerLoop := false
]
