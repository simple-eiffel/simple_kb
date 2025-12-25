note
	description: "[
		KB_AI_CONFIG - AI Provider Configuration Manager

		Manages AI provider credentials and configuration for simple_kb.
		Detects available providers from environment variables and
		local services (Ollama).

		Supported Providers:
		- ollama: Local inference (auto-detected at localhost:11434)
		- claude: Anthropic API (ANTHROPIC_API_KEY)
		- openai: OpenAI API (OPENAI_API_KEY)
		- gemini: Google AI (GOOGLE_AI_KEY)
		- grok: xAI API (XAI_API_KEY)

		Usage:
			config: KB_AI_CONFIG
			create config.make
			if config.has_ai_configured then
				config.set_provider ("claude")
			end
	]"
	author: "Simple Eiffel"
	date: "$Date$"
	revision: "$Revision$"

class
	KB_AI_CONFIG

inherit
	SHARED_EXECUTION_ENVIRONMENT

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize configuration and detect available providers
		do
			create available_providers.make (5)
			create provider_keys.make (5)
			ai_enabled := True
			detect_providers
			auto_select_provider
		end

feature -- Access

	available_providers: ARRAYED_LIST [STRING_32]
			-- List of providers with valid credentials

	active_provider: detachable STRING_32
			-- Currently selected provider (Void if none)

	ai_enabled: BOOLEAN
			-- Is AI mode enabled by user preference?

feature -- Status

	has_ai_configured: BOOLEAN
			-- Is any AI provider available?
		do
			Result := not available_providers.is_empty
		end

	is_ready: BOOLEAN
			-- Is AI ready to use (configured AND enabled)?
		do
			Result := has_ai_configured and ai_enabled and active_provider /= Void
		end

	is_ollama_available: BOOLEAN
			-- Is local Ollama running?
		do
			Result := available_providers.has ("ollama")
		end

	has_provider (a_name: READABLE_STRING_GENERAL): BOOLEAN
			-- Is provider `a_name` available?
		do
			Result := across available_providers as p some p.same_string_general (a_name) end
		end

	provider_api_key (a_provider: READABLE_STRING_GENERAL): detachable STRING_32
			-- Get API key for provider
		do
			if provider_keys.has (a_provider.to_string_32) then
				Result := provider_keys.item (a_provider.to_string_32)
			end
		end

feature -- Settings

	set_provider (a_name: READABLE_STRING_GENERAL)
			-- Select active provider
		require
			provider_available: has_provider (a_name)
		do
			active_provider := a_name.to_string_32
		ensure
			provider_set: attached active_provider as p implies p.same_string_general (a_name)
		end

	enable_ai
			-- Enable AI-assisted mode
		do
			ai_enabled := True
		ensure
			enabled: ai_enabled
		end

	disable_ai
			-- Disable AI (use direct FTS5 only)
		do
			ai_enabled := False
		ensure
			disabled: not ai_enabled
		end

	toggle_ai
			-- Toggle AI mode
		do
			ai_enabled := not ai_enabled
		end

feature -- Display

	status_report: STRING_32
			-- Human-readable status report
		local
			i: INTEGER
		do
			create Result.make (500)
			Result.append ("AI CONFIGURATION STATUS%N")
			Result.append ("========================%N%N")

			if has_ai_configured then
				Result.append ("Available Providers:%N")
				from i := 1 until i > available_providers.count loop
					Result.append ("  - " + available_providers [i])
					if attached active_provider as ap and then ap.same_string (available_providers [i]) then
						Result.append (" [ACTIVE]")
					end
					Result.append ("%N")
					i := i + 1
				end
				Result.append ("%NAI Mode: ")
				if ai_enabled then
					Result.append ("ENABLED%N")
				else
					Result.append ("DISABLED (using FTS5 only)%N")
				end
			else
				Result.append ("No AI providers configured.%N%N")
				Result.append ("Run 'kb ai setup' for instructions.%N")
			end
		end

feature -- Provider Detection

	detect_providers
			-- Scan for available AI providers
		do
			available_providers.wipe_out
			provider_keys.wipe_out

			-- Check environment variables for API keys
			detect_claude
			detect_openai
			detect_gemini
			detect_grok

			-- Check local Ollama (always last, as fallback)
			detect_ollama
		end

	refresh
			-- Re-detect providers (e.g., after setting env vars)
		do
			detect_providers
			if attached active_provider as ap and then not has_provider (ap) then
				auto_select_provider
			end
		end

feature {NONE} -- Provider Detection Implementation

	detect_claude
			-- Check for Anthropic Claude API key
		local
			l_key: detachable STRING_32
		do
			l_key := env_var ("ANTHROPIC_API_KEY")
			if attached l_key and then not l_key.is_empty then
				available_providers.extend ("claude")
				provider_keys.force (l_key, "claude")
			end
		end

	detect_openai
			-- Check for OpenAI API key
		local
			l_key: detachable STRING_32
		do
			l_key := env_var ("OPENAI_API_KEY")
			if attached l_key and then not l_key.is_empty then
				available_providers.extend ("openai")
				provider_keys.force (l_key, "openai")
			end
		end

	detect_gemini
			-- Check for Google Gemini API key
		local
			l_key: detachable STRING_32
		do
			l_key := env_var ("GOOGLE_AI_KEY")
			if attached l_key and then not l_key.is_empty then
				available_providers.extend ("gemini")
				provider_keys.force (l_key, "gemini")
			end
		end

	detect_grok
			-- Check for xAI Grok API key
			-- Accepts either XAI_API_KEY or GROK_API_KEY
		local
			l_key: detachable STRING_32
		do
			l_key := env_var ("XAI_API_KEY")
			if not attached l_key or else l_key.is_empty then
				-- Try alternative name
				l_key := env_var ("GROK_API_KEY")
			end
			if attached l_key and then not l_key.is_empty then
				available_providers.extend ("grok")
				provider_keys.force (l_key, "grok")
			end
		end

	detect_ollama
			-- Check if local Ollama is running
		local
			l_process: SIMPLE_PROCESS
		do
			-- Quick check: try to reach Ollama API
			create l_process.make
			l_process.execute ("curl -s -o /dev/null -w %%{http_code} http://localhost:11434/api/tags")
			if l_process.was_successful and then attached l_process.last_output as l_output and then l_output.has_substring ("200") then
				available_providers.extend ("ollama")
				-- Ollama doesn't need API key
			end
		end

	auto_select_provider
			-- Automatically select best available provider
			-- Priority: claude > openai > gemini > grok > ollama
		do
			active_provider := Void
			if has_provider ("claude") then
				active_provider := "claude"
			elseif has_provider ("openai") then
				active_provider := "openai"
			elseif has_provider ("gemini") then
				active_provider := "gemini"
			elseif has_provider ("grok") then
				active_provider := "grok"
			elseif has_provider ("ollama") then
				active_provider := "ollama"
			end
		end

	env_var (a_name: READABLE_STRING_GENERAL): detachable STRING_32
			-- Get environment variable value
		do
			if attached execution_environment.item (a_name.out) as val then
				Result := val.to_string_32
			end
		end

feature {NONE} -- Implementation

	provider_keys: HASH_TABLE [STRING_32, STRING_32]
			-- API keys by provider name

invariant
	providers_not_void: available_providers /= Void
	keys_not_void: provider_keys /= Void
	active_provider_valid: attached active_provider as p implies has_provider (p)

end
