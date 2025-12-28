# Task Manager Redesign Plan
## AI-RAG Enhanced Task Management System

### Overview

Transform the basic task manager into an AI-powered productivity system with:
- Rich task data model (descriptions, due dates, subtasks, dependencies)
- Multiple AI provider support (Claude, Grok, Gemini, Ollama)
- RAG-based intelligent features (smart search, task decomposition, NL input)
- **Works WITHOUT AI as default baseline** (AI is optional enhancement)
- **CPM-style dependency management** with AI-assisted block resolution

### Existing Libraries to Leverage

| Library | Purpose |
|---------|---------|
| `simple_ai_client` | AI_CLIENT, CLAUDE_CLIENT, GROK_CLIENT, OLLAMA_CLIENT, AI_EMBEDDING_STORE |
| `simple_kb` | RAG patterns (KB_AI_ROUTER, KB_AI_CONFIG) |
| `simple_sql` | SQLite persistence (TODO_ITEM, TODO_REPOSITORY) |
| `simple_tui` | TUI framework (TUI_QUICK, widgets) |

---

## Phase 1: Data Model Enhancement (simple_sql)

### 1.1 Extend TODO_ITEM

Add fields to existing TODO_ITEM class:

| Field | Type | Purpose |
|-------|------|---------|
| description | STRING | Detailed task notes |
| due_date | INTEGER | Unix timestamp |
| parent_id | INTEGER | Self-reference for subtasks |
| estimated_minutes | INTEGER | Time estimate |
| actual_minutes | INTEGER | Time tracked |
| context | STRING | "office", "home", "phone", "errands" |
| energy_level | INTEGER | 1=low, 2=medium, 3=high focus |
| status | STRING | "pending", "in_progress", "waiting", "completed", "archived" |

### 1.2 New Table: TASK_DEPENDENCY

```sql
CREATE TABLE task_dependency (
    id INTEGER PRIMARY KEY,
    predecessor_id INTEGER NOT NULL,
    successor_id INTEGER NOT NULL,
    dependency_type TEXT DEFAULT 'finish_to_start',
    FOREIGN KEY (predecessor_id) REFERENCES todo_item(id),
    FOREIGN KEY (successor_id) REFERENCES todo_item(id)
);
```

### 1.3 New Table: TASK_TAG

```sql
CREATE TABLE task_tag (
    task_id INTEGER NOT NULL,
    tag TEXT NOT NULL,
    PRIMARY KEY (task_id, tag),
    FOREIGN KEY (task_id) REFERENCES todo_item(id)
);
```

### 1.4 Update TODO_REPOSITORY

- Add CRUD for new fields
- Add dependency management
- Add tag management
- Add subtask queries (find_children, find_by_parent)
- Add filtered queries (by context, energy, status, due_date)

---

## Phase 2: AI Provider Abstraction (simple_llm)

### 2.1 Core Interface: LLM_PROVIDER

```eiffel
deferred class LLM_PROVIDER

feature -- Completion
    complete (a_prompt: STRING): STRING
        deferred
        end

    complete_with_system (a_system, a_prompt: STRING): STRING
        deferred
        end

feature -- Chat
    chat (a_messages: LIST [LLM_MESSAGE]): STRING
        deferred
        end

feature -- Embeddings
    embed (a_text: STRING): ARRAY [REAL_64]
        deferred
        end

    embed_batch (a_texts: LIST [STRING]): LIST [ARRAY [REAL_64]]
        deferred
        end

feature -- Configuration
    set_model (a_model: STRING)
        deferred
        end

    set_temperature (a_temp: REAL_64)
        deferred
        end

    set_max_tokens (a_tokens: INTEGER)
        deferred
        end

feature -- Status
    last_error: detachable STRING
    is_available: BOOLEAN
        deferred
        end
end
```

### 2.2 Provider Implementations

| Class | Provider | API Base |
|-------|----------|----------|
| CLAUDE_PROVIDER | Anthropic Claude | api.anthropic.com |
| GROK_PROVIDER | xAI Grok | api.x.ai |
| GEMINI_PROVIDER | Google Gemini | generativelanguage.googleapis.com |
| OLLAMA_PROVIDER | Local Ollama | localhost:11434 |

### 2.3 Provider Factory

```eiffel
class LLM_FACTORY

feature -- Creation
    create_provider (a_type: STRING; a_api_key: STRING): LLM_PROVIDER
        -- Create provider by type: "claude", "grok", "gemini", "ollama"

    available_providers: ARRAYED_LIST [STRING]
        -- List of supported provider types
end
```

### 2.4 Configuration Management

```eiffel
class LLM_CONFIG

feature -- Settings
    provider_type: STRING
    api_key: STRING
    model_name: STRING
    endpoint_url: detachable STRING  -- For custom endpoints
    temperature: REAL_64
    max_tokens: INTEGER

feature -- Persistence
    save_to_file (a_path: STRING)
    load_from_file (a_path: STRING)
end
```

---

## Phase 3: Vector Store (simple_vector_store)

### 3.1 Core Interface

```eiffel
class VECTOR_STORE

feature -- Storage
    add (a_id: STRING; a_vector: ARRAY [REAL_64]; a_metadata: STRING)
    update (a_id: STRING; a_vector: ARRAY [REAL_64])
    delete (a_id: STRING)

feature -- Search
    find_similar (a_vector: ARRAY [REAL_64]; a_limit: INTEGER): LIST [VECTOR_RESULT]
    find_similar_with_threshold (a_vector: ARRAY [REAL_64]; a_threshold: REAL_64): LIST [VECTOR_RESULT]

feature -- Utilities
    cosine_similarity (a, b: ARRAY [REAL_64]): REAL_64
end
```

### 3.2 SQLite Storage

Store vectors as JSON arrays in SQLite (simple approach, works for moderate scale):

```sql
CREATE TABLE vectors (
    id TEXT PRIMARY KEY,
    vector TEXT NOT NULL,  -- JSON array of floats
    metadata TEXT,
    created_at INTEGER
);
```

### 3.3 VECTOR_RESULT

```eiffel
class VECTOR_RESULT
feature
    id: STRING
    score: REAL_64
    metadata: STRING
end
```

---

## Phase 4: RAG Engine (simple_rag)

### 4.1 Task Embedder

```eiffel
class TASK_EMBEDDER

feature -- Embedding
    embed_task (a_task: TODO_ITEM): ARRAY [REAL_64]
        -- Embed title + description

    embed_tasks (a_tasks: LIST [TODO_ITEM])
        -- Bulk embed and store

    sync_embeddings
        -- Update embeddings for changed tasks
end
```

### 4.2 Task Intelligence

```eiffel
class TASK_INTELLIGENCE

feature -- Natural Language
    parse_natural_input (a_input: STRING): TODO_ITEM
        -- "call bob tomorrow about contract" -> structured task

feature -- Decomposition
    suggest_subtasks (a_task: TODO_ITEM): LIST [TODO_ITEM]
        -- Based on similar past tasks

feature -- Search
    semantic_search (a_query: STRING; a_limit: INTEGER): LIST [TODO_ITEM]
        -- Find tasks by meaning, not just keywords

feature -- Recommendations
    find_similar_tasks (a_task: TODO_ITEM): LIST [TODO_ITEM]
        -- "You've done similar tasks before..."

    suggest_estimate (a_task: TODO_ITEM): INTEGER
        -- Based on similar completed tasks

    daily_priorities (a_date: DATE): LIST [TODO_ITEM]
        -- AI-suggested task order for the day
end
```

### 4.3 Prompt Templates

```eiffel
class RAG_PROMPTS

feature -- Templates
    task_parse_prompt (a_input: STRING): STRING
        -- System + user prompt for NL parsing

    decomposition_prompt (a_task: TODO_ITEM; a_similar: LIST [TODO_ITEM]): STRING
        -- Context + request for subtask suggestions

    prioritization_prompt (a_tasks: LIST [TODO_ITEM]; a_context: STRING): STRING
        -- Request for priority ordering
end
```

---

## Phase 5: TUI Enhancements (simple_tui)

### 5.1 Input Dialog Widget

```eiffel
class TUI_INPUT_DIALOG

feature -- Fields
    add_text_field (a_label: STRING; a_name: STRING)
    add_text_area (a_label: STRING; a_name: STRING; a_lines: INTEGER)
    add_selector (a_label: STRING; a_name: STRING; a_options: LIST [STRING])
    add_date_picker (a_label: STRING; a_name: STRING)

feature -- Actions
    set_on_submit (a_action: PROCEDURE [HASH_TABLE [STRING, STRING]])
    set_on_cancel (a_action: PROCEDURE)

feature -- Display
    show_modal
end
```

### 5.2 Task Creation Dialog

Fields:
- Title (text field, required)
- Description (text area, 3 lines)
- Priority (selector: 1-5)
- Due date (date picker)
- Context (selector: office/home/phone/errands)
- Energy level (selector: low/medium/high)
- Parent task (selector from existing tasks)

### 5.3 AI Integration in UI

- "AI Suggest" button on task creation -> suggests subtasks
- Natural language input field with AI parsing
- "Similar tasks" panel when creating
- AI-suggested daily view

---

## Phase 6: Integration

### 6.1 Enhanced TASK_MANAGER_APP

```eiffel
class TASK_MANAGER_APP

feature -- AI
    llm: LLM_PROVIDER
    vector_store: VECTOR_STORE
    task_ai: TASK_INTELLIGENCE

feature -- AI Actions
    on_ai_create_task
        -- Open NL input, parse with AI

    on_ai_suggest_subtasks
        -- Get suggestions for selected task

    on_ai_search
        -- Semantic search dialog

    on_configure_ai
        -- Provider selection and API key config
end
```

### 6.2 Settings Persistence

Store in `~/.task_manager/config.json`:
- AI provider selection
- API keys (encrypted)
- Default contexts
- UI preferences

---

## Implementation Order

| Step | Component | Deliverable |
|------|-----------|-------------|
| 1 | simple_sql TODO_ITEM | Extended data model |
| 2 | simple_sql repositories | New tables + queries |
| 3 | simple_llm LLM_PROVIDER | Abstract interface |
| 4 | simple_llm CLAUDE_PROVIDER | First working provider |
| 5 | simple_llm other providers | Grok, Gemini, Ollama |
| 6 | simple_vector_store | Embedding storage |
| 7 | simple_rag TASK_EMBEDDER | Task vectorization |
| 8 | simple_rag TASK_INTELLIGENCE | Core AI features |
| 9 | simple_tui TUI_INPUT_DIALOG | Input dialogs |
| 10 | Task Manager integration | Wire everything |

---

## File Structure

```
/d/prod/
├── simple_sql/
│   └── src/
│       └── todo_app/
│           ├── todo_item.e          (EXTENDED)
│           ├── todo_repository.e    (EXTENDED)
│           ├── task_dependency.e    (NEW)
│           └── task_tag.e           (NEW)
│
├── simple_llm/                       (NEW LIBRARY)
│   ├── simple_llm.ecf
│   └── src/
│       ├── llm_provider.e
│       ├── llm_message.e
│       ├── llm_config.e
│       ├── llm_factory.e
│       └── providers/
│           ├── claude_provider.e
│           ├── grok_provider.e
│           ├── gemini_provider.e
│           └── ollama_provider.e
│
├── simple_vector_store/              (NEW LIBRARY)
│   ├── simple_vector_store.ecf
│   └── src/
│       ├── vector_store.e
│       └── vector_result.e
│
├── simple_rag/                       (NEW LIBRARY)
│   ├── simple_rag.ecf
│   └── src/
│       ├── task_embedder.e
│       ├── task_intelligence.e
│       └── rag_prompts.e
│
└── simple_tui/
    └── src/
        ├── widgets/
        │   └── tui_input_dialog.e   (NEW)
        └── apps/
            └── task_manager/
                └── task_manager_app.e (ENHANCED)
```

---

## Dependencies

```
simple_rag
    └── simple_llm
    └── simple_vector_store
    └── simple_sql

simple_tui (task_manager target)
    └── simple_rag
    └── simple_sql
```
