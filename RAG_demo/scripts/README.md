To run the R script to test a local LM Studio model, be sure to install R and the `renv` package. Then run the `renv::restore()` command to install the required packages. After that, you can run the script using the command `Rscript test-local-lmstudio.R`, or install the [rig cli tool](https://github.com/r-lib/rig) and run `rig run test-local-lmstudio.R`.

Script files in this folder:

- `clear-rag-chat-history.R`: R script to clear the chat history of the RAG chat object, but if you use the `gpt-oss-20b` model locally via [LM Studio](https://lmstudio.ai/), it still needs to [increase max context length manually in LM Studio configuration](https://yamahide.biz/archives/625).
- `demo-quarto-web-rag.R`: R script to demonstrate a RAG chatbot for Quarto documentation, using a local LM Studio model and a vector database built from Quarto docs.
- `init-quarto-web-rag-db.R`: R script to initialize the vector database for Quarto documentation, it downloads the Quarto docs website, extracts the text content, and creates a vector database file `quarto-web.ragnar.store`.
- `test-local-lmstudio.R`: R script to test a local LM Studio model with the `ellmer` package.

