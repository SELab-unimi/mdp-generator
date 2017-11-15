package it.unimi.di.se.mdp.generator

import it.unimi.di.se.mdp.generator.WhenCompiler
import java.util.ArrayList
import java.util.HashMap

class BeforeCompiler extends WhenCompiler {
	
	var parametersName = new ArrayList<String>
	var parametersType = new ArrayList<String>
	var preconditions = new HashMap<String, String> // source state -> expression
	
	private final static String PRECONDITION_MSG = "*** PRECONDITION VIOLATION ***"
	
	def addParameter(String name, String type){
		if(!parametersName.contains(name) && !parametersType.contains(type)){
			parametersName.add(name)
			parametersType.add(type)	
		}
	}
	
	def addPrecondition(String state, String expression){
		preconditions.put(state, expression)
	}
	
	override compileAdvice(String signature) '''
		«IF !eventStates.empty || !preconditions.empty»
			
			@Before(value="execution(«signature.compileSignature»)«compileArgs»")
			public void «signature.methodName»BeforeAdvice(«adviceParameters») {
				«signature.compileEvent»
				«preconditions.compileConditions(PRECONDITION_MSG)»
			}
		«ENDIF»
	'''
	
	def compileSignature(String signature) 
	'''«IF !parametersType.empty»«signature.qualifiedMethodName»(«FOR i: 0..< parametersType.size»«IF i>0», «ENDIF»«parametersType.get(i)»«ENDFOR»)«ENDIF»'''
	
	def compileArgs()
	'''«IF !parametersName.empty» && args(«FOR i: 0..< parametersName.size»«IF i>0», «ENDIF»«parametersName.get(i)»«ENDFOR»)«ENDIF»'''
	
	def adviceParameters()
	'''«IF !parametersName.empty && !parametersType.empty»«FOR i: 0..< parametersName.size»«IF i>0», «ENDIF»«parametersType.get(i)» «parametersName.get(i)»«ENDFOR»«ENDIF»'''
	
}
