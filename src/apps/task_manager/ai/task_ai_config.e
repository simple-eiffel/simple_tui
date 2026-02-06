note
	description: "[
		TASK_AI_CONFIG - AI provider configuration for Task Manager.

		Manages AI provider selection and API l_keys:
		- Supports Claude, Grok, Ollama, and no-AI mode
		- Persists configuration to JSON l_file
		- Provides is_ready check for graceful degradation

		The app works fully without AI - this is optional enhancement.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TASK_AI_CONFIG

create
	make,
	make_from_file

feature {NONE} -- Initialization

	make
			-- Create with defaults (no AI).
		do
			active_provider := Provider_none
			create api_keys.make (3)
			create models.make (3)
			-- Set default models per provider
			models.force ("claude-sonnet-4-20250514", Provider_claude)
			models.force ("grok-3", Provider_grok)
			models.force ("llama3", Provider_ollama)
		ensure
			no_ai_by_default: not is_ai_enabled
		end

	make_from_file (a_path: READABLE_STRING_GENERAL)
			-- Load configuration from file.
		do
			make
			config_path := a_path.to_string_32
			load_from_file
		end

feature -- Access

	active_provider: STRING_8
			-- Currently active provider: "none", "claude", "grok", "ollama".

	config_path: detachable STRING_32
			-- Path to config file (if set).

feature -- Provider Constants

	Provider_none: STRING_8 = "none"
	Provider_claude: STRING_8 = "claude"
	Provider_grok: STRING_8 = "grok"
	Provider_ollama: STRING_8 = "ollama"

feature -- Status

	is_ready: BOOLEAN
			-- Is AI configured and available?
		do
			Result := is_ai_enabled and then has_required_credentials
		end

	is_ai_enabled: BOOLEAN
			-- Is an AI provider selected (not "none")?
		do
			Result := not active_provider.same_string (Provider_none)
		end

	has_required_credentials: BOOLEAN
			-- Does the active provider have required credentials?
		do
			if active_provider.same_string (Provider_ollama) then
				-- Ollama doesn't need API key (local)
				Result := True
			elseif active_provider.same_string (Provider_claude) then
				Result := attached api_keys.item (Provider_claude) as k and then not k.is_empty
			elseif active_provider.same_string (Provider_grok) then
				Result := attached api_keys.item (Provider_grok) as k and then not k.is_empty
			else
				Result := False
			end
		end

	status_message: STRING_32
			-- Human-readable status.
		do
			create Result.make (50)
			if not is_ai_enabled then
				Result.append ("AI disabled")
			elseif not has_required_credentials then
				Result.append ("AI: Missing API key for ")
				Result.append_string_general (active_provider)
			else
				Result.append ("AI: ")
				Result.append_string_general (active_provider)
				if attached current_model as al_m then
					Result.append (" (")
					Result.append_string_general (m)
					Result.append (")")
				end
			end
		end

feature -- API Keys

	api_keys: HASH_TABLE [STRING_8, STRING_8]
			-- API keys by provider name.

	provider_api_key (a_provider: READABLE_STRING_8): detachable STRING_8
			-- Get API key for a provider.
		do
			Result := api_keys.item (a_provider)
		end

	set_api_key (a_provider, a_key: READABLE_STRING_8)
			-- Set API key for a provider.
		require
			provider_not_empty: not a_provider.is_empty
		do
			api_keys.force (a_key.twin, a_provider.twin)
		ensure
			key_set: attached api_keys.item (a_provider) as k and then k.same_string (a_key)
		end

feature -- Models

	models: HASH_TABLE [STRING_8, STRING_8]
			-- Model names by provider.

	current_model: detachable STRING_8
			-- Get model for active provider.
		do
			Result := models.item (active_provider)
		end

	set_model (a_provider, a_model: READABLE_STRING_8)
			-- Set model for a provider.
		require
			provider_not_empty: not a_provider.is_empty
			model_not_empty: not a_model.is_empty
		do
			models.force (a_model.twin, a_provider.twin)
		end

feature -- Provider Selection

	use_none
			-- Disable AI.
		do
			active_provider := Provider_none
		ensure
			disabled: not is_ai_enabled
		end

	use_claude (a_api_key: READABLE_STRING_8)
			-- Enable Claude provider.
		require
			key_not_empty: not a_api_key.is_empty
		do
			set_api_key (Provider_claude, a_api_key)
			active_provider := Provider_claude
		ensure
			enabled: is_ai_enabled
			provider_claude: active_provider.same_string (Provider_claude)
		end

	use_grok (a_api_key: READABLE_STRING_8)
			-- Enable Grok provider.
		require
			key_not_empty: not a_api_key.is_empty
		do
			set_api_key (Provider_grok, a_api_key)
			active_provider := Provider_grok
		ensure
			enabled: is_ai_enabled
			provider_grok: active_provider.same_string (Provider_grok)
		end

	use_ollama
			-- Enable Ollama provider (local, no API key needed).
		do
			active_provider := Provider_ollama
		ensure
			enabled: is_ai_enabled
			provider_ollama: active_provider.same_string (Provider_ollama)
		end

	set_provider (a_provider: READABLE_STRING_8)
			-- Set provider by name.
		require
			valid_provider: is_valid_provider (a_provider)
		do
			active_provider := a_provider.twin
		ensure
			provider_set: active_provider.same_string (a_provider)
		end

feature -- Validation

	is_valid_provider (a_provider: READABLE_STRING_8): BOOLEAN
			-- Is this a valid provider name?
		do
			Result := a_provider.same_string (Provider_none) or else
				a_provider.same_string (Provider_claude) or else
				a_provider.same_string (Provider_grok) or else
				a_provider.same_string (Provider_ollama)
		end

	available_providers: ARRAYED_LIST [STRING_8]
			-- List of available provider names.
		do
			create Result.make (4)
			Result.extend (Provider_none)
			Result.extend (Provider_claude)
			Result.extend (Provider_grok)
			Result.extend (Provider_ollama)
		ensure
			has_items: Result.count = 4
		end

feature -- Persistence

	save_to_file
			-- Save configuration to file (if path set).
		local
			l_json: STRING_8
			l_file: PLAIN_TEXT_FILE
		do
			if attached config_path as al_p then
				l_json := to_json
				create l_file.make_create_read_write (p)
				l_file.put_string (l_json)
				l_file.close
			end
		end

	load_from_file
			-- Load configuration from file (if exists).
		local
			l_file: PLAIN_TEXT_FILE
			l_content: STRING_8
		do
			if attached config_path as al_p then
				create l_file.make_with_name (p)
				if l_file.exists and then l_file.is_readable then
					l_file.open_read
					l_file.read_stream (l_file.count)
					l_content := l_file.last_string
					l_file.close
					from_json (l_content)
				end
			end
		end

feature -- JSON Serialization

	to_json: STRING_8
			-- Serialize to JSON.
		local
			l_first: BOOLEAN
		do
			create Result.make (200)
			Result.append ("{%N")
			Result.append ("  %"provider%": %"")
			Result.append (active_provider)
			Result.append ("%",%N")
			-- API keys (simple - in production, encrypt these)
			Result.append ("  %"api_keys%": {%N")
			l_first := True
			across api_keys as k loop
				if not l_first then
					Result.append (",%N")
				end
				l_first := False
				Result.append ("    %"")
				Result.append (@k.key)
				Result.append ("%": %"")
				Result.append (k)
				Result.append ("%"")
			end
			Result.append ("%N  },%N")
			-- Models
			Result.append ("  %"models%": {%N")
			l_first := True
			across models as m loop
				if not l_first then
					Result.append (",%N")
				end
				l_first := False
				Result.append ("    %"")
				Result.append (@m.key)
				Result.append ("%": %"")
				Result.append (m)
				Result.append ("%"")
			end
			Result.append ("%N  }%N")
			Result.append ("}")
		end

	from_json (a_json: READABLE_STRING_8)
			-- Deserialize from JSON (simple parser).
		local
			l_parser: JSON_PARSER
			l_obj: detachable JSON_OBJECT
			l_keys, l_mods: detachable JSON_OBJECT
		do
			create l_parser.make_with_string (a_json)
			l_parser.parse_content
			if l_parser.is_valid and then attached {JSON_OBJECT} l_parser.parsed_json_object as al_jo then
				l_obj := jo
				if attached {JSON_STRING} l_obj.item ("provider") as al_p then
					if is_valid_provider (al_p.item) then
						active_provider := al_p.item
					end
				end
				if attached {JSON_OBJECT} l_obj.item ("api_keys") as al_keys then
					l_keys := l_keys
					across l_keys as k loop
						if attached {JSON_STRING} k as al_v then
							api_keys.force (v.item, @k.key.item)
						end
					end
				end
				if attached {JSON_OBJECT} l_obj.item ("models") as al_mods then
					l_mods := l_mods
					across l_mods as m loop
						if attached {JSON_STRING} m as al_v then
							models.force (v.item, @m.key.item)
						end
					end
				end
			end
		end

invariant
	active_provider_valid: is_valid_provider (active_provider)
	api_keys_attached: api_keys /= Void
	models_attached: models /= Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
