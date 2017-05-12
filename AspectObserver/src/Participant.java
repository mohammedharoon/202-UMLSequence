public class Participant{
	
	String participantName;
	boolean isParticipantActive;
	
	public Participant() {
		this.isParticipantActive = false;
	}
	
	public Participant(String name) {
		this.participantName = name;
		this.isParticipantActive = false;
	}
	
	public Participant(boolean active, String name) {
		this.isParticipantActive = active;
		this.participantName = name;
	}

	public boolean isActive() {
		return this.isParticipantActive;
	}

	public void setActive(boolean active) {
		this.isParticipantActive = active;
	}

	public String getParticipantName() {
		return participantName;
	}

	public void setParticipantName(String name) {
		this.participantName = name;
	}
}