#! /usr/bin/env Rscript
full.fpath <- tryCatch(normalizePath(parent.frame(2)$ofile),  # works when using source
               error=function(e) # works when using R CMD
              normalizePath(unlist(strsplit(commandArgs()[grep('^--file=', commandArgs())], '='))[2]))
main_path_script <- dirname(full.fpath)

suppressPackageStartupMessages(library(biomaRt))

source(file.path(main_path_script, 'lib', 'general_functions.R'))
source(file.path(main_path_script, 'lib', 'functional_analysis_library.R'))
all_organisms_info <- read.table(file.path(main_path_script, "lib/organism_table.txt"), header=T, row.names=1, sep="\t")
reference_table <- read.table(file.path(main_path_script, 'samples', 'annot_file'), header=F, row.names=NULL, sep="\t")

current_organism_info <- get_specific_dataframe_names(all_organisms_info, rownames(all_organisms_info), model_organism)
model_organism <- 'Zebrafish'
biomaRt_filter <- 'ensembl_gene_id'
#biomaRt_filter <- 'refseq_peptide'
organism_mart <- as.character(current_organism_info[,"Mart"])
organism_dataset <- as.character(current_organism_info[,"Dataset"])
organism_host <- as.character(current_organism_info[,"biomaRt_Host"])
attr <- c(
  biomaRt_filter,
  as.character(current_organism_info[,"Attribute_GOs"]),
  as.character(current_organism_info[,"Attribute_entrez"])
)

query <- obtain_info_from_biomaRt(as.character(reference_table[,1]),biomaRt_filter, organism_mart, organism_dataset, organism_host, attr)

print(query)

