import java.io.FileOutputStream;
import java.io.IOException;
import java.util.HashMap;
import java.util.Stack;
import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.reflect.MethodSignature;
import net.sourceforge.plantuml.SourceStringReader;

public aspect SequenceGeneratorAspect {
	
	private static StringBuilder plantUmlString = new StringBuilder();
	private int functionCallDepth;
	pointcut constructorExecutionPointCut(): 
		!within(Main.generateSequenceDiagram*) && !within(SequenceGeneratorAspect) && !within(Participant)  && execution(*.new(..));
	pointcut methodExecution() : 
		!within(Main.generateSequenceDiagram*) && !within(SequenceGeneratorAspect) && !within(Participant)  && (execution(* *.*(..)) && !call(*.new(..)));

	private boolean constructorExecution = false;
	private HashMap<Integer, Participant> participantObjects = new HashMap<>();
	private Stack<Integer> participantsStack = new Stack<Integer>();

	public boolean isConstructorExecution() {
		return constructorExecution;
	}
	
	public void setConstructorExecution(boolean isConstructorExecution) {
		this.constructorExecution = isConstructorExecution;
	}
	
	before(): constructorExecutionPointCut() 
	{
		setConstructorExecution(true);
	}

	after(): constructorExecutionPointCut() 
	{
		setConstructorExecution(false);
	}

	before() : methodExecution() 
	{
		joinPointParseMethod(thisJoinPoint);
		functionCallDepth++;
	}

	after() : methodExecution() 
	{
		functionCallDepth--;
		if(functionCallDepth == 0) 
		{
			plantUmlString.append("@enduml\n");
			generateSequenceDiagram();
		}
	}

	private static void generateSequenceDiagram() 
	{
		String outputFileName = "sequenceDiagram";
		String intermediateGrammar = plantUmlString.toString();
		System.out.println("ga:"+intermediateGrammar);
		try 
		{
			FileOutputStream png = new FileOutputStream(outputFileName + ".png");
			SourceStringReader reader = new SourceStringReader(intermediateGrammar);
			reader.outputImage(png);
			System.out.println("Sequence diagram generated with the name' " 
			+ outputFileName + ".png' in base directory");
		}
		catch (IOException exception) 
		{
			System.err.println(exception.getMessage());
		}
	}
	
	@SuppressWarnings("unused")
	private void joinPointParseMethod(JoinPoint joinPoint) 
	{
		System.out.println(joinPoint.getSignature());
		if (!isConstructorExecution()) 
		{
			MethodSignature signature = (MethodSignature) joinPoint.getSignature();
			String messageString = "";
			String methodName = signature.getName();
			String[] paramNames = signature.getParameterNames();
			Class[] paramType = signature.getParameterTypes();
			messageString += methodName + "(";
			for (int paramValue = 0; paramValue < paramNames.length; paramValue++) {
				messageString += paramNames[paramValue] + " : " + paramType[paramValue].getSimpleName();
				if (paramValue != paramNames.length - 1) {
					messageString += ", ";
				}
			}
			messageString += ") : " + signature.getReturnType().getSimpleName() + "()";
			
			if (functionCallDepth == 0) 
			{
				System.out.println(functionCallDepth + "  " + joinPoint.getSignature().getDeclaringTypeName());
				
				participantObjects.put(functionCallDepth, new Participant(joinPoint.getSignature().getDeclaringTypeName()));
				plantUmlString.append("@startuml\nautonumber\nhide footbox\n");
				participantsStack.add(functionCallDepth);
				System.out.println(participantsStack);
			} 
			else 
			{
				
				if(functionCallDepth > participantsStack.peek())
				{
					participantObjects.put(functionCallDepth, new Participant(joinPoint.getThis().getClass().getSimpleName()));
					Participant parentParticipant = participantObjects.get(participantsStack.peek());
					Participant childParticipant = participantObjects.get(functionCallDepth);
					plantUmlString.append(parentParticipant.getParticipantName() + "->" + childParticipant.getParticipantName() + ":" + messageString + "\n");
					if(!parentParticipant.isActive())
					{
						plantUmlString.append("activate " + parentParticipant.getParticipantName() + "\n");
						parentParticipant.setActive(true);
					}
					if(!childParticipant.isActive())
					{
						plantUmlString.append("activate " + childParticipant.getParticipantName() + "\n");
						childParticipant.setActive(true);
					}
					participantsStack.push(functionCallDepth);
				}
				
				if(functionCallDepth <= participantsStack.peek())
				{
					while(!participantsStack.isEmpty() && functionCallDepth <= participantsStack.peek())
					{
						int objectId = participantsStack.pop();
						plantUmlString.append("deactivate " + participantObjects.get(objectId).getParticipantName() + "\n");
						participantObjects.get(objectId).setActive(false);
					}
					if(functionCallDepth == 1)
					{
						plantUmlString.append("deactivate " + participantObjects.get(participantsStack.peek()).getParticipantName() + "\n");
						participantObjects.get(participantsStack.peek()).setActive(false);
					}
				}
			}
		}
	}
}