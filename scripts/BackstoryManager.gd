extends RefCounted
class_name BackstoryManager

# Trait pools for generating backstories
var personality_traits = [
	"Cautious - Always checks surroundings before acting",
	"Optimistic - Sees the bright side of everything",
	"Curious - Constantly asking questions about the world",
	"Melancholic - Often lost in sad thoughts",
	"Energetic - Full of enthusiasm and vigor",
	"Wise - Speaks with knowledge from experience",
	"Anxious - Worries about everything that could go wrong",
	"Cheerful - Brings joy to every conversation",
	"Mysterious - Keeps thoughts and feelings hidden",
	"Practical - Focuses on useful, everyday matters"
]

var secrets_history = [
	"Lost their family heirloom near the well years ago",
	"Knows where the village's treasure is buried",
	"Once saved someone's life but never told anyone",
	"Has a secret garden hidden in the forest",
	"Used to be from a different village far away",
	"Witnessed something strange happen at midnight",
	"Keeps a diary with all the village gossip",
	"Has been having prophetic dreams lately",
	"Found something valuable but hasn't told anyone",
	"Remembers when the village was very different"
]

var relationship_dynamics = [
	"Childhood friends who share many memories",
	"Former rivals who now respect each other",
	"Distant relatives who recently reconnected",
	"Neighbors who help each other daily",
	"Strangers who are slowly becoming friends",
	"Old friends who had a falling out years ago",
	"Mentor and student from long ago",
	"Two people with opposite personalities who balance each other",
	"Former business partners who still trust each other",
	"Two souls who understand each other without words"
]

var names_pool = [
	"Akira", "Yuki", "Hana", "Kenji", "Saki", "Hiroshi",
	"Mei", "Taro", "Rin", "Koji", "Emi", "Daichi",
	"Nao", "Shin", "Kiko", "Ryu", "Mika", "Jun"
]

func generate_backstory(npc_id: String) -> Dictionary:
	print("BackstoryManager: Generating backstory for ", npc_id)
	
	var backstory = {}
	backstory.name = names_pool[randi() % names_pool.size()]
	backstory.personality = personality_traits[randi() % personality_traits.size()]
	backstory.secret = secrets_history[randi() % secrets_history.size()]
	backstory.relationship = relationship_dynamics[randi() % relationship_dynamics.size()]
	backstory.summary = _create_backstory_summary(backstory)
	backstory.conversation_style = _determine_conversation_style(backstory.personality)
	backstory.weather_preference = _generate_weather_preference()
	backstory.favorite_location = _generate_favorite_location()
	
	print("Generated backstory for ", backstory.name, " (", npc_id, ")")
	return backstory

func _create_backstory_summary(traits: Dictionary) -> String:
	var parts = traits.personality.split(" - ")
	var personality_desc = "has a unique personality"
	if parts.size() > 1:
		personality_desc = parts[1].to_lower()
	
	var summary = traits.name + " is a villager who " + personality_desc + ". "
	summary += "They carry the burden of a secret: " + traits.secret.to_lower() + ". "
	summary += "Their relationship with others is defined by being " + traits.relationship.to_lower() + "."
	return summary

func _determine_conversation_style(personality: String) -> String:
	var parts = personality.split(" - ")
	if parts.size() == 0:
		return "speaks in a balanced, measured way"
	
	var trait_name = parts[0].to_lower()
	
	# Use simple if statements to avoid any parsing issues
	if trait_name == "cautious":
		return "speaks carefully and thinks before talking"
	if trait_name == "optimistic":
		return "always tries to find something positive to say"
	if trait_name == "curious":
		return "asks lots of questions and shows interest in everything"
	if trait_name == "melancholic":
		return "speaks softly with a hint of sadness"
	if trait_name == "energetic":
		return "talks with enthusiasm and excitement"
	if trait_name == "wise":
		return "speaks thoughtfully with meaningful pauses"
	if trait_name == "anxious":
		return "worries aloud and seeks reassurance"
	if trait_name == "cheerful":
		return "laughs often and uses upbeat language"
	if trait_name == "mysterious":
		return "speaks in riddles and keeps things vague"
	if trait_name == "practical":
		return "focuses on concrete facts and useful information"
	
	return "speaks in a balanced, measured way"

func _generate_weather_preference() -> String:
	var preferences = [
		"loves sunny days and warm weather",
		"enjoys the sound of rain and cloudy skies",
		"feels energized by windy weather",
		"prefers mild, overcast days",
		"dislikes extreme weather of any kind",
		"finds beauty in all types of weather"
	]
	return preferences[randi() % preferences.size()]

func _generate_favorite_location() -> String:
	var locations = [
		"the peaceful area near the well",
		"the quiet bench where they can think",
		"the bustling area around the shop",
		"the shade under the old trees",
		"the comfort of their own home",
		"anywhere they can watch the village life"
	]
	return locations[randi() % locations.size()]

func generate_conversation_context(npc_backstory: Dictionary, situation: Dictionary) -> String:
	# Safety checks for backstory properties
	var personality = npc_backstory.get("personality", "Mysterious - Keeps thoughts and feelings hidden")
	var name = npc_backstory.get("name", "Villager")
	var secret = npc_backstory.get("secret", "has many untold stories")
	var conversation_style = npc_backstory.get("conversation_style", "speak thoughtfully")
	
	var parts = personality.split(" - ")
	var personality_desc = "has a unique personality"
	if parts.size() > 1:
		personality_desc = parts[1].to_lower()
	
	var context = "You are " + name + ", a villager who " + personality_desc + ". "
	context += "Your secret is that you " + secret.to_lower() + ". "
	context += "You " + conversation_style + ". "
	
	# Add situational context
	if situation.has("type"):
		var situation_type = situation.get("type", "")
		if situation_type == "weather_comment":
			context += "You're currently experiencing " + situation.get("weather", "unknown") + " weather. "
			context += "You " + npc_backstory.get("weather_preference", "enjoy all types of weather") + ". "
		if situation_type == "environment_comment":
			context += "You're near some village objects. "
			context += "Your favorite place is " + npc_backstory.get("favorite_location", "the village center") + ". "
		if situation_type == "npc_conversation":
			context += "You're talking to another villager. "
			context += "Your relationship with others is " + npc_backstory.get("relationship", "friendly and welcoming").to_lower() + ". "
		if situation_type == "observation":
			context += "You're taking a moment to observe your surroundings. "
		if situation_type == "self_talk":
			context += "You're having a quiet moment to yourself. "
	
	return context

func get_conversation_prompt(npc_backstory: Dictionary, situation: Dictionary) -> String:
	var context = generate_conversation_context(npc_backstory, situation)
	var prompt = ""
	
	var situation_type = situation.get("type", "")
	if situation_type == "weather_comment":
		prompt = "Make a brief comment about the current " + situation.get("weather", "unknown") + " weather. "
	if situation_type == "environment_comment":
		prompt = "Comment on something you notice in your surroundings. "
	if situation_type == "npc_conversation":
		prompt = "Start a conversation with the other villager about something on your mind. "
	if situation_type == "observation":
		prompt = "Share a thoughtful observation about village life. "
	if situation_type == "self_talk":
		prompt = "Express a brief thought or feeling you're having. "
	if situation_type == "weather_reaction":
		prompt = "React to the sudden change in weather to " + situation.get("weather", "unknown") + ". "
	if prompt == "":
		prompt = "Say something that reflects your personality and current situation. "
	
	prompt += "Keep your response to 1-2 sentences and stay in character. "
	prompt += "Don't reveal your secret directly, but let it influence your mood and perspective."
	
	return context + prompt