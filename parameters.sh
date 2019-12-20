## parameters for SAIGE runs

# single-variant (SV) or gene-based run
#MODE="SV"
MODE="GENE"

# Base directory, no trailing slash
BASE_DIRECTORY=/data/studies/06_UKBB

# Installation path (where the pipeline scripts are), no trailing slash
INSTALLATION_PATH=/data/studies/06_UKBB/Exome_50k/04_SAIGE/SAIGE/Pipeline

# Path to phenotype file, relative to BASE_DIRECTORY, don't use '..' (for docker)
PHENO_FILE=Exome_50k/04_SAIGE/SAIGE/SAIGE_20190722_eGFR/ckdgen-UKBB_500k_phenoGWAS-EA.txt

# Path to group file, relative to BASE_DIRECTORY, don't use '..' (for docker)
# Should use %CHR% placeholder
GROUP_FILE=Exome_50k/04_SAIGE/SAIGE_Gene/MarkerList/saige_per_chr/EXOME_FE_b38.saige.chr%CHR%.txt

# name of the sample ID column in the phenotype file
SAMPLE_ID_COL=IID

# first phenotype: column name, trait type (quantitative/binary), covariates
PHENOTYPE_1=egfr_ckdepi_creat
TRAITTYPE_1=quantitative
COVARCOLS_1=batch,age_crea_serum,sex_male,PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10,PC11,PC12,PC13,PC14,PC15
POSITIVE_CONTROL_1=16:20348509:UMOD

# second phenotype
PHENOTYPE_2=egfr_ckdepi_creacys
TRAITTYPE_2=quantitative
COVARCOLS_2=batch,age_crea_serum,sex_male,PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10,PC11,PC12,PC13,PC14,PC15
POSITIVE_CONTROL_2=20:23637790:CST3

# output directory, no trailing slash
OUTPUT_DIR=Exome_50k/04_SAIGE/SAIGE/20190730_eGFR_pipeline

# prefix for output files
OUTPUT_PREFIX=ukb_

# number of threads
NTHREADS=4

# leave-one-chromosome-out mode (FALSE/TRUE)
LOCO=FALSE

# inverse normalize phenotype (FALSE/TRUE)
INV_NORMALIZE=FALSE

# SAIGE version (Docker container name)
USE_DOCKER=Y

# if using Docker, container version
SAIGE_VERSION=wzhou88/saige:0.36.2
#SAIGE_VERSION=wzhou88/saige:0.35.8.2

# if not using Docker, paths to step* R scripts (incl. RScript)
# Step 0: createSparseGRM.R, step 1: step1_fitNULLGLMM.R, step 2: step2_SPAtests.R
# Step 0 is only required for gene-based tests.
# this may require absolute paths
SAIGE_STEP0_PATH="Rscript createSparseGRM.R"
SAIGE_STEP1_PATH="Rscript step1_fitNULLGLMM.R"
SAIGE_STEP2_PATH="Rscript step2_SPAtests.R"

# PLINK file with chip genotypes (used for null model),
# relative to base directory
PLINK_FILE=Exome_50k/03_Merge_GWAS_WES/chip_single_file/ukb_cal_49796

# BGEN file with imputed dosages or WES genotypes,
# relative to base directory
BGEN_FILE=Exome_50k/03_Merge_GWAS_WES/wes/wes_bgen/ukb_wes_efe-chr%CHR%.bgen

# SAMPLE file 
# relative to base directory
SAMPLE_FILE=Exome_50k/03_Merge_GWAS_WES/imputed/ukb_subset_chr22.sample 

# output data for every i-th SNP (2 = every second)
NUM_LINES_OF_OUTPUT=1

# additional options to pass to step 0, step 1 and/or 2
STEP0_ADDITIONAL_OPTIONS=""
STEP1_ADDITIONAL_OPTIONS=""
STEP2_ADDITIONAL_OPTIONS=""

