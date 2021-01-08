Class {
	#name : #DAPServer,
	#superclass : #Object,
	#instVars : [
		'port',
		'tcpServer',
		'serverLoop',
		'process',
		'data',
		'serverContext',
		'messagesProcesses'
	],
	#category : #PharoDAP
}

{ #category : #context }
DAPServer >> context [
	^ serverContext
]

{ #category : #starting }
DAPServer >> extractLengthOf: aData [
	(aData beginsWith: 'Content-Length: ')
		ifTrue:
			[ ^ (aData copyFrom: 16 to: (aData indexOf: Character cr)) asInteger ]
		ifFalse: [ ^ -1 ]
]

{ #category : #starting }
DAPServer >> extractRequestFrom: clientSocket [
	| length startingPoint endPoint result |
	"data is the current buffer state"
	data ifEmpty: [ data := clientSocket receiveData ].
	length := self extractLengthOf: data.
	startingPoint := data indexOf: ${.
	endPoint := data findCloseBracesFor: startingPoint.
	result := String new: length.
	"three options"
	"startingPoint and endPoint are found"
	(startingPoint ~= 0 and: [ endPoint ~= 0 ])
		ifTrue: [ result := data copyFrom: startingPoint to: endPoint.
			data := data copyFrom: endPoint + 1 to: data size.
			^ result ].
	startingPoint = 0
		ifTrue:
			[ "none were found" self getDatafromPosition: 1 fromSocket: clientSocket in: result ]
		ifFalse: [ "only startingPoint is found"
			(data copyFrom: startingPoint to: data size)
				withIndexDo: [ :each :index | result at: index put: each ].
			self
				getDatafromPosition: data size - startingPoint + 2
				fromSocket: clientSocket
				in: result ].
	data := ''.
	^ result
]

{ #category : #starting }
DAPServer >> getDatafromPosition: startingPoint fromSocket: clientSocket in: existingData [
	clientSocket receiveDataInto: existingData startingAt: startingPoint
]

{ #category : #starting }
DAPServer >> getHeaderFor: answer into: aStream [
	aStream << 'Content-Length: ' << answer size asString << String crlf
		<< String crlf
]

{ #category : #starting }
DAPServer >> handleJSON: aJSON [
	1h
]

{ #category : #starting }
DAPServer >> handleRequest: request toClient: clientSocket [
	| jrpcMessage |
	jrpcMessage := [ self parseJSON: request ]
		on: Error
		do: [ :err | err return: err asJRPCResponse ].
	^ self messageProcess: jrpcMessage id
		put:
			([ self
				sendData: (self handleJSON: jrpcMessage)
				toClient: clientSocket.
			self removeMessageProcess: jrpcMessage id ]
				forkAt: Processor lowIOPriority
				named: jrpcMessage method)
]

{ #category : #initialize }
DAPServer >> initialize [
	serverContext := PLSContext new.
	data := ''.
	messagesProcesses := Dictionary new.
]

{ #category : #context }
DAPServer >> messageProcess: anId	put: aProcess [
	self context messageProcessesAt: anId put: aProcess
]

{ #category : #starting }
DAPServer >> parseJSON: aJSONString [
	1h
]

{ #category : #accessing }
DAPServer >> port [
	^ port
]

{ #category : #accessing }
DAPServer >> port: anObject [
	port := anObject
]

{ #category : #context }
DAPServer >> removeMessageProcess: anId [
	self context removeMessageProcess: anId
]

{ #category : #context }
DAPServer >> resetContext [
	serverContext := PLSContext new
]

{ #category : #starting }
DAPServer >> sendData: answer toClient: clientSocket [
	answer
		ifNotEmpty: [ clientSocket
				sendData:
					(String
						streamContents: [ :contentStream | 
							self getHeaderFor: answer into: contentStream.
							contentStream << answer ]) ]
]

{ #category : #starting }
DAPServer >> start [
	tcpServer := Socket newTCP.
	tcpServer listenOn: self port backlogSize: 10.
	serverLoop := true.
	(tcpServer waitForAcceptFor: 60)
		ifNotNil: [ :clientSocket | 
			process := [ [ serverLoop ]
				whileTrue: [ | request |
					request := self extractRequestFrom: clientSocket.
					self handleRequest: request toClient: clientSocket ] ]
				forkAt: Processor lowIOPriority
				named: 'JRPC TCP connection' ]
]

{ #category : #stopping }
DAPServer >> stop [
	serverLoop := false.
	tcpServer closeAndDestroy.
	
	"Ensure process finishes."
	process isTerminated
		ifTrue: [ ^ self ].
	process terminate
]
