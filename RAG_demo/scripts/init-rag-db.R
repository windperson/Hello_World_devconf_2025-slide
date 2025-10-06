#!/usr/bin/env Rscript

# python_path <- Sys.getenv("RETICULATE_PYTHON")

library(ragnar)
library(here)
library(stringr)
library(dotty)
library(purrr)
library(dplyr)

if (!dir.exists("./github/quarto-dev/quarto-web")) {
  print("Cloning quarto-web repo")
  fs::dir_create("./github/quarto-dev")
  withr::with_dir("./github/quarto-dev", {
    system("git clone https://github.com/quarto-dev/quarto-web --depth 1")
  })
}

if (!dir.exists("./github/quarto-dev/quarto-web/_site/")) {
  print("Rendering quarto-web site")
  withr::with_dir("./github/quarto-dev/quarto-web", {
    system("git pull")
    system("quarto render")
  })
}

# Must Set back this env varible with the python installation that had install "numpy" pip package # nolint: line_length_linter.
# Sys.setenv(RETICULATE_PYTHON = python_path)

print("Start converting docs to RAG store")

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

# ragnar package loads its custom marktitdown failed on Windows,
# so we explicitly load it from the custom path
#custom_markitdown_path <- file.path(Sys.getenv("R_LIBS_USER"), "ragnar/python/")
#message(sprintf("Using custom markitdown path:\n%s", custom_markitdown_path))

# reticulate::import_from_path(
#   "_ragnartools.markitdown",
#   custom_markitdown_path,
# )

store_location <- "quarto-web.ragnar.store"

print("Creating RAG store")
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
  },
  overwrite = TRUE
)


for (r in seq_len(nrow(sitemap))) {
  .[local_path = local_path, url = url, ..] <- sitemap[r, ]
  message(sprintf("[% 3i/%i] ingesting: %s", r, nrow(sitemap), url))

  doc <- read_as_markdown(local_path, origin = url)
  chunks <- markdown_chunk(doc)

  ragnar_store_insert(store, chunks)
}

DBI::dbDisconnect(store@con)

message(sprintf("RAG store created/updated at: %s", store_location))