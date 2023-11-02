Class {
	#name : 'ScopeoInstrumenter',
	#superclass : 'Object',
	#instVars : [
		'sendLink',
		'assignmentLink',
		'sendNodes',
		'assignmentNodes',
		'pc',
		'packages',
		'traces',
		'errors'
	],
	#category : 'Scopeo-Instrumenter',
	#package : 'Scopeo-Instrumenter'
}

{ #category : 'environments' }
ScopeoInstrumenter class >> forPackages: aSet [

	^ self new packages: aSet
]

{ #category : 'metalinks' }
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

{ #category : 'model' }
ScopeoInstrumenter >> increasePC [
	 pc := pc + 1
]

{ #category : 'initialization' }
ScopeoInstrumenter >> initialize [

	sendNodes := OrderedCollection new.
	assignmentNodes := OrderedCollection new.
	errors :=  OrderedCollection new.
	pc := 0
]

{ #category : 'instrumentation' }
ScopeoInstrumenter >> instrumentAssignments [

	assignmentNodes do: [ :n | n link: self assignmentLink ]
]

{ #category : 'instrumentation' }
ScopeoInstrumenter >> instrumentPackages [

	| methods |
	methods := self methodsToInstrument.
	sendNodes := methods flatCollect: [ :m | m ast sendNodes ].
	assignmentNodes := methods flatCollect: [ :m | m ast instanceVariableWriteNodes ].

	self instrumentSends.
	self instrumentAssignments.
	methods do: [ :m |
		m invalidate.
		m reflectiveMethod ifNotNil: [ :r |
			[ r compileAndInstallCompiledMethod ]
				on: Error
				do: [ :err | errors add: err copy ] ] ]
]

{ #category : 'instrumentation' }
ScopeoInstrumenter >> instrumentSends [

	(sendNodes select: [ :n |
		 n arguments size = 0 or: [
			 n arguments noneSatisfy: [ :a | a isBlock ] ] ]) do: [ :n |
		n link: self sendLink ]
]

{ #category : 'instrumentation' }
ScopeoInstrumenter >> methodsToInstrument [

	| classes |
	classes := packages flatCollect: [ :p | p classes ].

	^ (classes flatCollect: #methods) select: [ :m |
		  (packages includes: m methodClass package) or: [
			  packages anySatisfy: [ :p | m protocol name match: p name ] ] ]
]

{ #category : 'accessing' }
ScopeoInstrumenter >> packages: anObject [

	packages := anObject
]

{ #category : 'metalinks' }
ScopeoInstrumenter >> sendLink [

	^ sendLink ifNil: [
		  sendLink := MetaLink new.
		  sendLink control: #before.
		  sendLink arguments: #( context ).
		  sendLink optionCompileOnLinkInstallation: true.
		  sendLink metaObject: self.
		  sendLink selector: #traceSend:.
		  ^ sendLink ]
]

{ #category : 'tracing' }
ScopeoInstrumenter >> traceAssignment: anArray [
	
	"data is exposed here:
		- receiver
		- variable name
		- variable value
	Store it in your model."
	
]

{ #category : 'tracing' }
ScopeoInstrumenter >> traceSend: ctx [
	"The following data is exposed here.
	Store it in your model."
	ctx receiver.
	ctx selector.
	ctx sender receiver.
	ctx arguments.
	ctx sender selector
]

{ #category : 'accessing' }
ScopeoInstrumenter >> traces [
	^traces ifNil: [ traces := OrderedCollection new ]
]

{ #category : 'instrumentation' }
ScopeoInstrumenter >> uninstall [

	sendLink uninstall.
	assignmentLink uninstall.
	self methodsToInstrument do: #recompile.
]
