#!/usr/bin/env Rscript

library(ragnar)
library(here)
library(stringr)
library(dotty)
library(purrr)
library(dplyr)

# Gather quarto docs source from quarto-web repo
if (!dir.exists("./github/quarto-dev/quarto-web")) {
  message("Cloning quarto-web repo")
  fs::dir_create("./github/quarto-dev")
  withr::with_dir("./github/quarto-dev", {
    result <- system("git clone https://github.com/quarto-dev/quarto-web --depth 1") # nolint: line_length_linter.
    if (result != 0) {
      stop("Failed to clone quarto-web repo")
    }
  })
}

message("Rendering quarto-web site")
withr::with_dir("./github/quarto-dev/quarto-web", {
  result <- system("git pull")
  if(result != 0) {
    stop("Failed to pull latest changes from quarto-web repo")
  }
  result <- system("quarto render")
  if(result != 0) {
    stop("Failed to render quarto-web site")
  }
})


message("Start converting docs to RAG store")

site_map_path <- "http://quarto.org/sitemap.xml"

message(sprintf("Using sitemap: %s", site_map_path))

#It must be a pure http[s]:// URL, otherwise it fails with open connection error
urls <- ragnar_find_links(site_map_path)

message(sprintf("Found %d URLs", length(urls)))

local_paths <- str_replace(
  urls,
  "^https://quarto.org",
  here("github", "quarto-dev", "quarto-web", "_site")
)

message(sprintf("Mapped to %d local paths", length(local_paths)))

sitemap <- tibble(urls, local_paths) |> rename_with(\(nms) sub("s$", "", nms))

message(sprintf("Of which %d exist", sum(file.exists(sitemap$local_path))))


# sanity check
stopifnot(file.exists(sitemap$local_path))

store_location <- "quarto-web.ragnar.store"

message("Creating RAG store")
store <- ragnar_store_create(
  store_location,
  name = "quarto_docs",
  title = "Search Quarto Docs",
  embed = \(x) {
    ragnar::embed_lm_studio(x,
      base_url = "http://localhost:1234/v1",
      api_key = "lm-studio",
      model = "text-embedding-nomic-embed-text-v2-moe"
    )
    # use this if you use OpenAI cloud model
    # embed = \(x) ragnar::embed_openai(x, model = "text-embedding-3-small") # nolint
  },
  overwrite = TRUE
)

message(sprintf("Ingesting %d documents", nrow(sitemap)))
for (r in seq_len(nrow(sitemap))) {
  .[local_path = local_path, url = url, ..] <- sitemap[r, ]
  message(sprintf("[% 3i/%i] ingesting: %s", r, nrow(sitemap), url))

  doc <- read_as_markdown(local_path, origin = url)
  chunks <- markdown_chunk(doc)

  ragnar_store_insert(store, chunks)
}

message("Building index")
ragnar_store_build_index(store)

DBI::dbDisconnect(store@con)

message(sprintf("RAG store created/updated at: %s", store_location))