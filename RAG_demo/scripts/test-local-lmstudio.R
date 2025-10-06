#!/usr/bin/env Rscript

#install.packages("ellmer") # if not installed # nolint: commented_code_linter.

library(ellmer)

client <- chat_openai(
  base_url = "http://localhost:1234/v1",
  model = "openai/gpt-oss-20b",
  api_key = "lm-studio",
  system_prompt = "你要強調你是跑在本地的LM Studio模型，並且你不會將任何資料上傳到網路上。你要用中文回答問題，並且回答要簡短有力。"
)

client$chat("你是谁？")