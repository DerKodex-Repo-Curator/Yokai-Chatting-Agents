extends Node
class_name AISystem

# LM Studio API settings
@export var api_url: String = "http://localhost:1234/v1/chat/completions"
@export var api_timeout: float = 10.0
@export var max_tokens: int = 50
@export var temperature: float = 0.8

# Request management
var http_request: HTTPRequest
var pending_requests: Dictionary = {}
var request_queue: Array = []
var max_concurrent_requests: int = 2
var active_requests: int = 0

# Shared conversation history - both NPCs can see what was said
var shared_conversation_history: Array = []
var max_history_length: int = 20  # Store last 20 messages total (from both NPCs)
var conversation_history: Dictionary = {}  # Keep for backwards compatibility with save system

# Backstory manager
var backstory_manager

func _ready():
	print("AISystem: Initializing AI conversation system")
	
	# Create HTTP request node
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	http_request.timeout = api_timeout
	
	# Initialize backstory manager
	backstory_manager = BackstoryManager.new()
	
	# Test LM Studio connection
	_test_connection()

func _test_connection():
	print("AISystem: Testing LM Studio connection...")
	
	var test_data = {
		"model": "gpt-3.5-turbo",  # This will use whatever model is loaded in LM Studio
		"messages": [
			{
				"role": "user",
				"content": "Hello, are you working?"
			}
		],
		"max_tokens": 10,
		"temperature": 0.7
	}
	
	_make_api_request("connection_test", test_data)

func generate_conversation(npc, context: Dictionary):
	if not npc or not npc.backstory:
		print("AISystem: Cannot generate conversation - missing NPC or backstory")
		return
	
	print("AISystem: Generating conversation for ", npc.npc_id, " - ", context.type)
	
	# Create conversation prompt
	var prompt = backstory_manager.get_conversation_prompt(npc.backstory, context)
	
	# Prepare API request
	var messages = []
	
	# Add system context
	messages.append({
		"role": "system",
		"content": prompt
	})
	
	# Add recent shared conversation history for context
	if shared_conversation_history.size() > 0:
		var recent_history = shared_conversation_history.slice(-6)  # Last 6 messages from both NPCs
		for entry in recent_history:
			# Add context about who said what
			var speaker_context = ""
			if entry.npc_id != npc.npc_id:
				speaker_context = "The other villager said: "
			else:
				speaker_context = "You previously said: "
			
			messages.append({
				"role": "user",
				"content": speaker_context + entry.message
			})
	
	# Add current request
	messages.append({
		"role": "user",
		"content": "Generate your response now."
	})
	
	var request_data = {
		"model": "gpt-3.5-turbo",
		"messages": messages,
		"max_tokens": max_tokens,
		"temperature": temperature,
		"stop": ["\n", ".", "!", "?"]
	}
	
	# Queue or make request
	var request_id = npc.npc_id + "_" + str(Time.get_unix_time_from_system())
	pending_requests[request_id] = {
		"npc": npc,
		"context": context,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	if active_requests < max_concurrent_requests:
		_make_api_request(request_id, request_data)
	else:
		request_queue.append({"id": request_id, "data": request_data})

func _make_api_request(request_id: String, data: Dictionary):
	print("AISystem: Making API request - ", request_id)
	
	var json_string = JSON.stringify(data)
	var headers = [
		"Content-Type: application/json",
		"Accept: application/json"
	]
	
	# Store request ID for response handling
	http_request.set_meta("current_request_id", request_id)
	
	var error = http_request.request(api_url, headers, HTTPClient.METHOD_POST, json_string)
	
	if error != OK:
		print("AISystem: Failed to make request - ", error)
		_handle_request_error(request_id, "Failed to send request")
	else:
		active_requests += 1

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	var request_id = http_request.get_meta("current_request_id", "")
	active_requests -= 1
	
	print("AISystem: Request completed - ", request_id, " Code: ", response_code)
	
	if response_code == 200:
		_handle_successful_response(request_id, body)
	else:
		_handle_request_error(request_id, "HTTP " + str(response_code))
	
	# Process next request in queue
	_process_next_request()

func _handle_successful_response(request_id: String, body: PackedByteArray):
	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	
	if parse_result != OK:
		print("AISystem: Failed to parse JSON response")
		_handle_request_error(request_id, "Invalid JSON response")
		return
	
	var response_data = json.data
	
	if request_id == "connection_test":
		print("AISystem: LM Studio connection successful!")
		return
	
	if not response_data.has("choices") or response_data.choices.is_empty():
		print("AISystem: No response choices in API response")
		_handle_request_error(request_id, "No response content")
		return
	
	var message_content = response_data.choices[0].message.content.strip_edges()
	
	if not pending_requests.has(request_id):
		print("AISystem: Request ID not found in pending requests")
		return
	
	var request_info = pending_requests[request_id]
	var npc = request_info.npc
	
	# Clean up the response
	message_content = _clean_response(message_content)
	
	# Store in conversation history
	_add_to_history(npc.npc_id, message_content, request_info.context)
	
	# Emit the conversation
	var game_manager = get_node("/root/Main")
	if game_manager:
		game_manager.npc_conversation.emit(npc.npc_name, message_content)
	
	# Clean up
	pending_requests.erase(request_id)
	
	print("AISystem: Generated response for ", npc.npc_id, ": ", message_content)

func _handle_request_error(request_id: String, error_message: String):
	print("AISystem: Request error - ", request_id, ": ", error_message)
	
	if request_id == "connection_test":
		print("AISystem: LM Studio connection failed - ", error_message)
		print("AISystem: Make sure LM Studio is running on localhost:1234")
		return
	
	if pending_requests.has(request_id):
		var request_info = pending_requests[request_id]
		var npc = request_info.npc
		
		# Generate fallback response
		var fallback_message = _generate_fallback_response(npc, request_info.context)
		
		# Store in conversation history
		_add_to_history(npc.npc_id, fallback_message, request_info.context)
		
		# Emit the conversation
		var game_manager = get_node("/root/Main")
		if game_manager:
			game_manager.npc_conversation.emit(npc.npc_name, fallback_message)
		
		pending_requests.erase(request_id)

func _process_next_request():
	if request_queue.size() > 0 and active_requests < max_concurrent_requests:
		var next_request = request_queue.pop_front()
		_make_api_request(next_request.id, next_request.data)

func _clean_response(response: String) -> String:
	# Remove common AI artifacts
	response = response.replace("*", "")
	response = response.replace("[", "")
	response = response.replace("]", "")
	response = response.strip_edges()
	
	# Ensure it ends with punctuation
	if not response.ends_with(".") and not response.ends_with("!") and not response.ends_with("?"):
		response += "."
	
	# Capitalize first letter
	if response.length() > 0:
		response = response[0].to_upper() + response.substr(1)
	
	return response

func _generate_fallback_response(npc, context: Dictionary) -> String:
	var fallback_responses = []
	
	match context.get("type", ""):
		"weather_comment":
			fallback_responses = [
				"The weather feels different today.",
				"I should pay attention to the sky.",
				"Weather like this makes me thoughtful."
			]
		"environment_comment":
			fallback_responses = [
				"This place holds many memories.",
				"I notice something different here.",
				"The village is always changing."
			]
		"npc_conversation":
			fallback_responses = [
				"It's good to see you today.",
				"How have you been lately?",
				"There's something I've been thinking about."
			]
		"observation":
			fallback_responses = [
				"Life in the village is peaceful.",
				"I enjoy watching the world go by.",
				"There's beauty in simple moments."
			]
		"self_talk":
			fallback_responses = [
				"I wonder what tomorrow will bring.",
				"Some thoughts are hard to shake.",
				"Time moves differently here."
			]
		_:
			fallback_responses = [
				"Another day in the village.",
				"I have much to think about.",
				"Life continues its gentle rhythm."
			]
	
	return fallback_responses[randi() % fallback_responses.size()]

func _add_to_history(npc_id: String, message: String, context: Dictionary):
	# Add to shared conversation history
	var entry = {
		"npc_id": npc_id,
		"message": message,
		"context": context,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	shared_conversation_history.append(entry)
	
	# Limit shared history length to last 20 messages total
	if shared_conversation_history.size() > max_history_length:
		shared_conversation_history = shared_conversation_history.slice(-max_history_length)
	
	# Also maintain per-NPC history for backwards compatibility with save system
	if not conversation_history.has(npc_id):
		conversation_history[npc_id] = []
	
	conversation_history[npc_id].append(entry)
	
	# Limit per-NPC history length
	if conversation_history[npc_id].size() > max_history_length:
		conversation_history[npc_id] = conversation_history[npc_id].slice(-max_history_length)

func get_conversation_history(npc_id: String) -> Array:
	return conversation_history.get(npc_id, [])

func clear_conversation_history(npc_id: String = ""):
	if npc_id.is_empty():
		conversation_history.clear()
		shared_conversation_history.clear()
	else:
		conversation_history.erase(npc_id)
		# Remove entries from shared history for this NPC
		shared_conversation_history = shared_conversation_history.filter(func(entry): return entry.npc_id != npc_id)
	print("AISystem: Cleared conversation history for ", npc_id if not npc_id.is_empty() else "all NPCs")
