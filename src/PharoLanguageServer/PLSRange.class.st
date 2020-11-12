"
A range in a text document expressed as (zero-based) start and end positions. A range is comparable to a selection in an editor. Therefore the end position is exclusive. If you want to specify a range that contains a line including the line ending character(s) then use an end position denoting the start of the next line. For example:

```
{
    start: { line: 5, character: 23 },
    end : { line: 6, character: 0 }
}
```
"
Class {
	#name : #PLSRange,
	#superclass : #Object,
	#instVars : [
		'start',
		'end'
	],
	#category : #'PharoLanguageServer-Structure'
}

{ #category : #converting }
PLSRange >> asJRPCJSON [
	^ {(#start -> self start asJRPCJSON).
	(#end -> self end asJRPCJSON)} asDictionary 
]

{ #category : #accessing }
PLSRange >> end [
	"The range's end position."
	^ end
]

{ #category : #accessing }
PLSRange >> end: anObject [
	end := anObject
]

{ #category : #accessing }
PLSRange >> start [
	"The range's start position."
	^ start
]

{ #category : #accessing }
PLSRange >> start: anObject [
	start := anObject
]
