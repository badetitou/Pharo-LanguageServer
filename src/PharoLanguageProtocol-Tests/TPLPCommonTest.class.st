"
A TPLPCommonTest is a test class for testing the behavior of TPLPCommon
"
Class {
	#name : 'TPLPCommonTest',
	#superclass : 'TestCase',
	#instVars : [
		'client'
	],
	#category : 'PharoLanguageProtocol-Tests',
	#package : 'PharoLanguageProtocol-Tests'
}

{ #category : 'tests' }
TPLPCommonTest >> setUp [

	super setUp.

	client := PLPDummyClient new
]

{ #category : 'tests' }
TPLPCommonTest >> testExtractLengthOf [

	| request |
	request := 'Content-Length: 31
'.
	self assert: (client extractLengthOf: request) equals: 31
]

{ #category : 'tests' }
TPLPCommonTest >> testExtractRequestFrom [
	"client extractRequestFrom: "

	| request stream result |
	client answerLoop: true.

	request := 'Content-Length: 31

{
	"jsonrpc": "2.0",
	"id": 1
}'.

	stream := ReadWriteStream with: request.
	stream position: 0.

	result := client extractRequestFrom: stream.
	self assert: result equals: '{
	"jsonrpc": "2.0",
	"id": 1
}'
]
