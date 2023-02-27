################################################################################
# Setup
# 
# TODO: Uncomment relevant code to setup Python and install paperfetcher
################################################################################

# Install reticulate if not already installed
if(!require("reticulate")){
  install.packages("reticulate")
  library(reticulate)
}

# Install Python if not already installed, and create a new virtualenv for paperfetcher
# (Uncomment the lines below to run code)
#install_python("3.7:latest")
#virtualenv_create("paperfetcher", version="3.7:latest")
#use_virtualenv("paperfetcher")

# Install paperfetcher
# (Uncomment the lines below to run code)
#py_install("paperfetcher", envname="paperfetcher")

# Import the paperfetcher package
paperfetcher <- import("paperfetcher")

################################################################################
# Handsearching parameters
# 
# TODO: Modify these parameters according to your search
################################################################################

# List of ISSNs
issn_list <- list("1573-6601", "1759-2887")

# Date range to search within
from_date <- "2023-01-01"
until_date <- "2023-02-01"

# Keywords
filter_keywords <- FALSE  # if true, filter keywords
keyword_list <- list("")  # if true, keywords to filter articles by

################################################################################
# Handsearching
################################################################################

ds <- NULL

# Loop over ISSNs
for (issn in issn_list) {
  # Search
  if (filter_keywords){
    search <- paperfetcher$handsearch$CrossrefSearch(ISSN=issn, from_date=from_date, until_date=until_date, keyword_list=keyword_list)
  }
  else{
    search <- paperfetcher$handsearch$CrossrefSearch(ISSN=issn, from_date=from_date, until_date=until_date)
  }
  
  search(select=TRUE, select_fields=list('DOI', 'URL', 'title', 'author', 'issued', 'abstract'))
  
  # Construct a DataFrame of entries
  parsers <- import("paperfetcher.parsers", convert=FALSE)
  cur_ds <- search$get_CitationsDataset(field_list=list('DOI', 'URL', 'title', 'author', 'issued'),
                                    field_parsers_list=list(NULL, NULL, parsers$crossref_title_parser,
                                                            parsers$crossref_authors_parser, 
                                                            parsers$crossref_date_parser))
  if (is.null(ds)) {
    ds <- cur_ds
  }
  else{
    ds$extend(cur_ds$`_items`)
  }
  
  # Convert to RIS
  ris_ds <- search$get_RISDataset()
  
  # Save RIS
  ris_ds$save_ris(sprintf("out/handsearching_%s.ris", issn))
}

df <- ds$to_df()
