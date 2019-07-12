package it.unimi.di.se.mdp.generator

import java.util.ArrayList
import java.util.HashMap
import it.unimi.di.se.mdp.mdpDsl.ObservableMap

abstract class ObservableActionCompiler {

	public final static String BEFORE = 'before'
	public final static String AFTER = 'after'
	protected static final String ARG_SEPARATOR = '#'

	// events grouped by src state: srcState -> {argsCondition, arc, preCondition, postCondition}
	var protected events = new HashMap<String, ArrayList<ObservableMap>>
	// arg type and name are paired by position: {<parametersType[0], parametersName[0]>, ..., <parametersType[n], parametersName[n]>}
	var protected parametersName = new ArrayList<String>
	var protected parametersType = new ArrayList<String>

	def addEvent(ObservableMap map){
		var state = map.arc.src.name
		if(!events.containsKey(state)) {
			var mapList = new ArrayList<ObservableMap>
			mapList.add(map)
			events.put(state, mapList)
		}
		else {
			var mapList = events.get(state)
			mapList.add(map)
		}
	}

	def addParameter(String name, String type){
		if(!parametersName.contains(name) && !parametersType.contains(type)){
			parametersName.add(name)
			parametersType.add(type)
		}
	}

	def methodName(String signature){
		var method = signature.qualifiedMethodName
		return method.substring(method.lastIndexOf(".")+1)
	}

	def qualifiedMethodName(String signature){
		return signature.substring(0, signature.indexOf("("));
	}

	def compileEdgeMap(String signature) '''
	private static final Map<String, String> EDGE_MAP = new HashMap<>();
	«var i = 0»
	«var methodCounter = 0»
	«var closed = false»
	«var instructionsPerMethod = 500»
    	«FOR String state: events.keySet»
    	«FOR ObservableMap m: events.get(state)»
    	«IF i % instructionsPerMethod == 0»
    	private static void edgeMapInit«methodCounter»() {«{methodCounter++; closed = false; ""}»
    	«ENDIF»
    	«var currState = state»
    	«var currAction = m.argsCondition.split('\"').get(3)»
    	«var targetState = m.postcondition.expression.split('\"').get(1)»
    		EDGE_MAP.put("«currState + currState + currAction + targetState»", "«m.arc.name»");
	«IF i++ % instructionsPerMethod == (instructionsPerMethod - 1)»
	}
	«{closed = true; ""}»«ENDIF»
    	«ENDFOR»
    	«IF !closed»
    	}
    	«{i = 0; ""}»
    	«ENDIF»
    	«ENDFOR»

	static {
		«FOR j: 0..< methodCounter»
		edgeMapInit«j»();
		«ENDFOR»
	}
	'''

	def compileEvents(String signature) '''
		«IF !events.empty»
		String eventLabel = EDGE_MAP.get(currentMonitorState + state.label() + action + result.label());
		if (eventLabel != null)
			monitor.addEvent(new Event(eventLabel, timeStamp));
		«ENDIF»
	'''

	def compileSignature(String signature)
	'''«IF !parametersType.empty»«signature.qualifiedMethodName»(«FOR i: 0..< parametersType.size»«IF i>0», «ENDIF»«parametersType.get(i)»«ENDFOR»)«ENDIF»'''

	def compileArgs()
	'''«IF !parametersName.empty» && args(«FOR i: 0..< parametersName.size»«IF i>0», «ENDIF»«parametersName.get(i)»«ENDFOR»)«ENDIF»'''

	def adviceParameters()
	'''«IF !parametersName.empty && !parametersType.empty»«FOR i: 0..< parametersName.size»«IF i>0», «ENDIF»«parametersType.get(i)» «parametersName.get(i)»«ENDFOR»«ENDIF»'''


	def extractArgName(String argEntry) {
		return argEntry.split(ARG_SEPARATOR).get(1)
	}

	def extractArgType(String argEntry) {
		return argEntry.split(ARG_SEPARATOR).get(0)
	}

	def createArgEntry(String argType, String argName) {
		return argType + ARG_SEPARATOR + argName
	}

	def abstract String compileAdvice(String signature)
}
