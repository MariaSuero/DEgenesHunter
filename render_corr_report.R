#! /usr/bin/env Rscript
#############################################
############## FUNCTIONAL HUNTER ###########
#############################################

# this is wrapped in a tryCatch. The first expression works when source executes, the
# second expression works when R CMD does it.
full.fpath <- tryCatch(normalizePath(parent.frame(2)$ofile),  # works when using source
               error=function(e) # works when using R CMD
              normalizePath(unlist(strsplit(commandArgs()[grep('^--file=', commandArgs())], '='))[2]))
main_path_script <- dirname(full.fpath)


#Loading libraries  
suppressPackageStartupMessages(require(optparse))
suppressPackageStartupMessages(require(knitr))


#############################################
### MAIN 
#############################################

# Parse command line
#------------------------------------------------

option_list <- list(
  make_option(c("-i", "--input_hunter_folder"), type="character",
    help="DEgenes Hunter's differential expression analysis output folder"), 
  make_option(c("-o", "--output_files"), type="character", default="results",
    help="Output path. Default=%default")
)
opt <- parse_args(OptionParser(option_list=option_list))


############ CREATE FOLDERS #########3
paths <- list()
dir.create(opt$output_files)
paths$root <-opt$output_files

source(file.path(main_path_script, 'lib', 'functional_analysis_library.R'))
source(file.path(main_path_script, 'lib', 'plotting_functions.R'))

#############################################
### LOAD AND PARSE 
#############################################

DEGH_results <- read.table(file.path(opt$input_hunter_folder, "Common_results", "hunter_results_table.txt"), header=TRUE, row.names=1, sep="\t", stringsAsFactors = FALSE)
aux <- which(DEGH_results$genes_tag == "FILTERED_OUT") 
if(length(aux) > 0){
	DEGH_results <- DEGH_results[-aux,]
}


#############################################
### PREPARE AND TRANSFORM DATA
#############################################

####
# LOAD NORMALIZED COUNTS
####
	# LOAD NORMALIZED COUNTS
	norm_counts <- as.matrix(read.table(file.path(opt$input_hunter_folder, "Results_DESeq2", "Normalized_counts_DESeq2.txt"), header=TRUE, row.names=1, sep="\t", stringsAsFactors = FALSE))
	scaled_counts <- scale_data_matrix(data_matrix = norm_counts, transpose = TRUE)
	scaled_counts_table <- as.data.frame(as.table(scaled_counts))
	colnames(scaled_counts_table) <- c("Gene","Sample","Count")
		
	####
	# LOAD WGCNA clusters representative profiles with samples
	cl_eigvalues <- as.matrix(read.table(file.path(opt$input_hunter_folder, "Results_WGCNA", "eigen_values_per_samples.txt"), header=TRUE, row.names=1, sep="\t", stringsAsFactors = FALSE))
	cl_eigvalues <- as.data.frame(as.table(cl_eigvalues),stringsAsFactors = FALSE)
	colnames(cl_eigvalues) <- c("Sample","Cluster_ID","Count") 
	cl_eigvalues_gnorm <- cl_eigvalues
	cl_eigvalues_gnorm$Count <- (cl_eigvalues_gnorm$Count + 1) / 2 
	
	####
	# LOAD WGCNA - PVal (Cluster - Trait)
	wgcna_pval_cl_trait <- as.matrix(read.table(file.path(opt$input_hunter_folder, "Results_WGCNA", "module_trait_p_val.txt"), header=TRUE, row.names=1, sep="\t", stringsAsFactors = FALSE))
	wgcna_corr_cl_trait <- as.matrix(read.table(file.path(opt$input_hunter_folder, "Results_WGCNA", "module_trait.txt"), header=TRUE, row.names=1, sep="\t", stringsAsFactors = FALSE))
	
	####
	# LOAD WGCNA - Correlation (Sample - Trait)
	wgcna_count_sample_trait <- as.matrix(read.table(file.path(opt$input_hunter_folder, "Results_WGCNA", "sample_trait.txt"), header=TRUE, row.names=1, sep="\t", stringsAsFactors = FALSE))
	wgcna_count_sample_trait <- scale_data_matrix(wgcna_count_sample_trait)


# Obtain clusters
cls <- unique(DEGH_results$Cluster_ID)
if(any(c(0,"grey") %in% cls)){
	cls <- cls[!cls %in% c(0,"grey")]
}else{
	warning("Cluster Zero/Grey not found")
}
clgenes <- lapply(cls,function(cl){unique(rownames(DEGH_results[which(DEGH_results$Cluster_ID == cl),]))}) # Find
names(clgenes) <- cls


############################################################
##                    GENERATE REPORT                     ##
############################################################
results_path <- normalizePath(paths$root)

invisible(lapply(cls,function(cl){
	# Take output name
	aux <- paste0("cl_func_",cl,".html")
	outf_cls_i <- file.path(results_path, aux)
	# Generate report
	rmarkdown::render(file.path(main_path_script, 'templates', 'corrprofiles_report.Rmd'), output_file = outf_cls_i, intermediates_dir = results_path)
}))
