package it.unimi.di.se.mdp.generator

import it.unimi.di.se.mdp.mdpDsl.ObservableMap
import it.unimi.di.se.mdp.generator.BeforeCompiler
import it.unimi.di.se.mdp.mdpDsl.Arg

class MonitorObserveCompiler {
	
	var beforeCompiler = new BeforeCompiler
	var afterCompiler = new AfterCompiler
	
	def parse(ObservableMap map) {
		if(map.when == ObservableActionCompiler.AFTER)
			afterCompiler.addEvent(map)
		else if(map.when == ObservableActionCompiler.BEFORE)
			beforeCompiler.addEvent(map)
		
		if(map.arguments !== null)
			for(Arg a: map.arguments) {
				beforeCompiler.addParameter(a.name, a.type)
				afterCompiler.addParameter(a.name, a.type)
			}
		
		if(map.precondition !== null)
			beforeCompiler.addPrecondition(map.arc.src.name, map)
		if(map.postcondition !== null)
			afterCompiler.addPostcondition(map.arc.src.name, map)
	}
	
	def compileAdvices(String signature) '''
		«beforeCompiler.compileAdvice(signature)»
		«afterCompiler.compileAdvice(signature)»
	'''
	
}
