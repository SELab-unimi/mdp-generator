package it.unimi.di.se.mdp.generator

import java.util.ArrayList
import java.util.HashMap
import it.unimi.di.se.mdp.mdpDsl.Map
import it.unimi.di.se.mdp.mdpDsl.Arg

abstract class WhenCompiler {
	
	public final static String BEFORE = 'before'
	public final static String AFTER = 'after'
	
	var protected events = new HashMap<String, ArrayList<Map>> // src-state -> {args-condition, arc}
	var protected args = new HashMap<String, String> // arg-name -> arg-type
	
	def addEvent(Map map){
		var state = map.arc.src.name
		if(!events.containsKey(state)) {
			var mapList = new ArrayList<Map>()
			mapList.add(map)
			events.put(state, mapList)
		}
		else {
			var mapList = events.get(state)
			mapList.add(map)
		}
		if(map.arguments !== null)
			for(Arg arg: map.arguments)
				if(!args.containsKey(arg.name))
					args.put(arg.name, arg.type)
	}
	
	def methodName(String signature){
		var method = signature.qualifiedMethodName
		return method.substring(method.lastIndexOf(".")+1)
	}
	
	def qualifiedMethodName(String signature){
		return signature.substring(0, signature.indexOf("("));
	}
	
	def compileEvent(String signature) '''
		«IF !events.empty»
			«var i = 0»
			«FOR String state: events.keySet»
				«FOR Map m: events.get(state)»
					«IF i++ > 0»else «ENDIF»if(monitor.currentState.getName().equals("«state»") && «m.argsCondition»)
						monitor.addEvent(new Event("«m.arc.name»", System.currentTimeMillis()));
				«ENDFOR»
			«ENDFOR»
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
