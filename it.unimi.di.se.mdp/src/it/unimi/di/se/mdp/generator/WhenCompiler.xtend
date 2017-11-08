package it.unimi.di.se.mdp.generator

import java.util.ArrayList
import java.util.HashMap
import it.unimi.di.se.mdp.mdpDsl.Map

abstract class WhenCompiler {
	
	public final static String BEFORE = 'before'
	public final static String AFTER = 'after'
	
	var protected eventStates = new ArrayList<String>
	
	def addEvent(Map map){
		var state = map.arc.src.name
		if(!eventStates.contains(state))
			eventStates.add(state)
	}
	
	def methodName(String signature){
		var method = signature.qualifiedMethodName
		return method.substring(method.lastIndexOf(".")+1)
	}
	
	def qualifiedMethodName(String signature){
		return signature.substring(0, signature.indexOf("("));
	}
	
	def compileEvent(String signature) '''
		«IF !eventStates.empty»
		if(«FOR i: 0..< eventStates.size»«IF i>0» || «ENDIF»monitor.currentState.getName().equals("«eventStates.get(i)»")«ENDFOR»)
			monitor.addEvent(new Event("«signature»", System.currentTimeMillis()));
		«ENDIF»
	'''
	
	def compileConditions(HashMap<String, String> conditions, String message) '''
		«IF !conditions.empty»
			
			boolean condition = true;
			«FOR state: conditions.keySet»
				if(monitor.currentState.getName().equals("«state»"))
					condition &= «conditions.get(state)»;
			«ENDFOR»
			if(!condition)
				log.severe("«message»");
		«ENDIF»
	'''
	
	def abstract String compileAdvice(String signature)
}
