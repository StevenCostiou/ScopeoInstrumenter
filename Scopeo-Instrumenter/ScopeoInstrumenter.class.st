Class {
	#name : #ScopeoInstrumenter,
	#superclass : #Object,
	#instVars : [
		'sendLink',
		'assignmentLink',
		'sendNodes',
		'assignmentNodes',
		'pc',
		'packages',
		'traces'
	],
	#category : #'Scopeo-Instrumenter'
}

{ #category : #environments }
ScopeoInstrumenter class >> forPackages: aSet [

	^ self new packages: aSet
]

{ #category : #metalinks }
ScopeoInstrumenter >> assignmentLink [

	^ assignmentLink ifNil: [
		  assignmentLink := MetaLink new.
		  assignmentLink control: #after.
		  assignmentLink arguments: #( object name value ).
		  assignmentLink optionArgsAsArray: true.
		  assignmentLink metaObject: self.
		  assignmentLink selector: #traceAssignment:.
		  assignmentLink ]
]

{ #category : #model }
ScopeoInstrumenter >> increasePC [
	 pc := pc + 1
]

{ #category : #initialization }
ScopeoInstrumenter >> initialize [
	sendNodes := OrderedCollection new.	
	assignmentNodes := OrderedCollection new.	
	pc := 0
]

{ #category : #instrumentation }
ScopeoInstrumenter >> instrumentAssignments [

	assignmentNodes do: [ :n | n link: self assignmentLink ]
]

{ #category : #instrumentation }
ScopeoInstrumenter >> instrumentPackages [

	| methods |
	methods := self methodsToInstrument.
	sendNodes := methods flatCollect: [ :m | m ast sendNodes ].
	assignmentNodes := methods flatCollect: [ :m | m ast assignmentNodes ].

	self instrumentSends.
	self instrumentAssignments.
	methods do: [ :m| m invalidate. m reflectiveMethod ifNotNil:[:r|r compileAndInstallCompiledMethod] ]
]

{ #category : #instrumentation }
ScopeoInstrumenter >> instrumentSends [

	sendNodes do: [ :n | n link: self sendLink ]
]

{ #category : #instrumentation }
ScopeoInstrumenter >> methodsToInstrument [

	| classes |
	classes := packages flatCollect: [ :p | p classes ].

	^ (classes flatCollect: #methods) select: [ :m |
		  (packages includes: m methodClass package) or: [
			  packages anySatisfy: [ :p | m protocol match: p name ] ] ]
]

{ #category : #accessing }
ScopeoInstrumenter >> packages: anObject [

	packages := anObject
]

{ #category : #metalinks }
ScopeoInstrumenter >> sendLink [

	^ sendLink ifNil: [
		  sendLink := MetaLink new.
		  sendLink control: #after.
		  sendLink arguments: #( receiver arguments selector object method).
		"  sendLink optionArgsAsArray: true."
		  sendLink metaObject: self.
		  sendLink selector: #traceSendIn:args:selector:sender:method:.
		  sendLink ]
]

{ #category : #tracing }
ScopeoInstrumenter >> traceAssignment: anArray [
	"self increasePC."
	self traces add: anArray 
]

{ #category : #tracing }
ScopeoInstrumenter >> traceSend: aContext [
	"|trace sender|
	trace := OrderedCollection new."
"	self increasePC."
"	sender := aContext sender.
	trace add: sender receiver.
	trace add: sender selector.
	trace add: aContext selector.
	trace add: aContext receiver.
	trace add: aContext arguments."
	self traces add: aContext
]

{ #category : #tracing }
ScopeoInstrumenter >> traceSendIn: receiver args: args selector: selector sender: sender method: caller [
	"|trace sender|
	trace := OrderedCollection new."
"	self increasePC."
"	sender := aContext sender.
	trace add: sender receiver.
	trace add: sender selector.
	trace add: aContext selector.
	trace add: aContext receiver.
	trace add: aContext arguments."
	self traces add: { receiver. args. selector. sender. caller }
]

{ #category : #accessing }
ScopeoInstrumenter >> traces [
	^traces ifNil: [ traces := OrderedCollection new ]
]

{ #category : #instrumentation }
ScopeoInstrumenter >> uninstall [

	sendLink uninstall.
	assignmentLink uninstall.
	self methodsToInstrument do: #recompile.
]
