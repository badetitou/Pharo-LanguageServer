Class {
	#name : 'PLSToploApplication',
	#superclass : 'SpApplication',
	#classVars : [
		'Current'
	],
	#category : 'PharoLanguageServer-Toplo',
	#package : 'PharoLanguageServer-Toplo'
}

{ #category : 'accessing' }
PLSToploApplication class >> initialize [

	MiApplication current useBackend: #Toplo
]

{ #category : 'accessing' }
PLSToploApplication class >> reset [
	<script>
	MiApplication current useBackend: #Morphic
]
