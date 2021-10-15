Class {
	#name : #PLSApplication,
	#superclass : #SpApplication,
	#classVars : [
		'Current'
	],
	#category : #'PharoLanguageServer-Gtk'
}

{ #category : #accessing }
PLSApplication class >> current [
	^ Current ifNil: [ Current := self new ].
]

{ #category : #accessing }
PLSApplication class >> defaultBackendName [

	^ #Gtk
]
