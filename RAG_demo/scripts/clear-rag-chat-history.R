#!/usr/bin/env Rscript

library(ellmer)

if (exists("rag_chat")) {
  message("Clear rag_chat object chat context")
  rag_chat <- rag_chat$clone()$set_turns(list())
} else {
  message("No existing rag_chat object, nothing to clear")
}