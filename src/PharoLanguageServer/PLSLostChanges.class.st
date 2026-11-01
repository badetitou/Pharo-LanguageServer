"
I keep the code changes of the last session of the image that it did not save, as Epicea logged them, so that the client can replay them (pls-env:lostChanges).

Pharo detects them at startup, before Ombu opens the log of the new session, but EpLostChangesDetector skips a headless image such as the one of the language server. So I detect them myself: I register as a tool of the session manager, after EpLostChangesDetector and before OmSessionStore, and remember the changes until the image quits.

A change is named by its ref, its position among the changes, oldest first. Once replayed or dismissed, it is handled and no longer pending.
"
Class {
	#name : 'PLSLostChanges',
	#superclass : 'Object',
	#instVars : [
		'entries',
		'handled'
	],
	#classVars : [
		'Current'
	],
	#category : 'PharoLanguageServer',
	#package : 'PharoLanguageServer'
}

{ #category : 'accessing' }
PLSLostChanges class >> current [

	^ Current ifNil: [ Current := self new ]
]

{ #category : 'accessing' }
PLSLostChanges class >> current: aLostChanges [

	Current := aLostChanges
]

{ #category : 'class initialization' }
PLSLostChanges class >> initialize [

	SessionManager default registerToolClassNamed: self name
]

{ #category : 'system startup' }
PLSLostChanges class >> startUp: isImageStarting [
	"Detect the lost changes before OmSessionStore opens the log of the new session"

	isImageStarting ifFalse: [ ^ self ].
	Current := self new.
	(EpMonitor hasCurrent and: [ EpMonitor current isEnabled ]) ifFalse: [
		^ self ].
	Current := [ self withEntries: EpLostChangesDetector new lostChanges ]
		           on: Error
		           do: [ :error | self new ]
]

{ #category : 'instance creation' }
PLSLostChanges class >> withEntries: aCollection [

	^ self new
		  setEntries: aCollection;
		  yourself
]

{ #category : 'accessing' }
PLSLostChanges >> handle: ref [
	"The change ref was replayed or dismissed"

	handled add: ref
]

{ #category : 'initialization' }
PLSLostChanges >> initialize [

	super initialize.
	entries := #(  ).
	handled := Set new
]

{ #category : 'accessing' }
PLSLostChanges >> pending [
	"Answer the changes not handled yet, oldest first, as associations from their ref to their Ombu entry"

	^ (1 to: entries size)
		  reject: [ :index | handled includes: index printString ]
		  thenCollect: [ :index | index printString -> (entries at: index) ]
]

{ #category : 'accessing' }
PLSLostChanges >> pendingAmong: refs [
	"Answer the pending changes named by refs, in the order of the log, which is the one to replay them in"

	^ self pending select: [ :each | refs includes: each key ]
]

{ #category : 'initialization' }
PLSLostChanges >> setEntries: aCollection [
	"aCollection holds the Ombu entries of the lost changes, oldest first. Only code changes can be replayed"

	entries := (aCollection select: [ :entry | entry content isCodeChange ]) asArray
]
