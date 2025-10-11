#!/usr/bin/env Rscript

library(ragnar)
library(ellmer)

rag_db_path <- "quarto-web.ragnar.store"

message("Open RAG store db")
rag_store <- ragnar::ragnar_store_connect(rag_db_path, read_only = TRUE)

message("Setting up LLM chat client")
if (exists("rag_chat")) {
  message("Removing existing rag_chat object")
  rm(rag_chat)
}
rag_chat <- ellmer::chat_openai(
  model = "openai/gpt-oss-20b",
  base_url = "http://localhost:1234/v1",
  api_key = "lm-studio",
  params = ellmer::params(
    reasoning_effort = "medium", verbosity = "low"
  ),
  echo = FALSE
)
# use this if you use OpenAI cloud model
# rag_chat <- ellmer::chat_openai(model = "gpt-5", model = "gpt-5",
#   params = ellmer::params(
#     reasoning_effort = "low", verbosity = "low"
#   ),
#   echo = FALSE
# )

message("Configuring chat client system prompt")

# nolint start
rag_chat$set_system_prompt(c(rag_chat$get_system_prompt(),
glue::trim(
"
Response with the language user used in their last request, don't include useless greeting words.
You are an expert in Quarto documentation.
Perform searches on quarto_docs for user request before craft response,
but DO NOT Excessive Calls Tools too many times per user request.
Response always includes links to related official Quarto documentation links.
If the request is ambiguous, search first, then ask a clarifying question.
If quarto_docs are unavailable, or if search fails, or if it does not contain an answer to the question,
Inform the user and do NOT answer the question.
Give concise answers but include minimal self-contained Quarto document examples,
Prefer using more valid Quarto markdown syntax (.qmd) , Less HTML, CSS those pure web technology syntax as possible.
And when it needs to display Quarto code blocks, use oversized markdown fences, like follows:

````` markdown
PROSE HERE

```{r}
CODE HERE
```

```{python}
CODE HERE
```

`````
"
)))
# nolint end

message("Combine RAG store with chat client")
ragnar::ragnar_register_tool_retrieve(rag_chat, rag_store,
  store_description = "quarto_docs"
)

message("RAG chat initialized.\n
You can now use the command:\n
live_console(rag_chat)\n
to interact with.")
