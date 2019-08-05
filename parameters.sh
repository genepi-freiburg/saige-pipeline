## parameters for SAIGE runs

# Base directory
BASE_DIRECTORY=/data/studies/06_UKBB

# Path to phenotype file, relative to BASE_DIRECTORY, don't use '..'
PHENO_FILE=Exome_50k/04_SAIGE/SAIGE/SAIGE_20190722_eGFR/ckdgen-UKBB_500k_phenoGWAS-EA.txt

# name of the sample ID column in the phenotype file
SAMPLE_ID_COL=IID

# number of phenotypes to analyse (next block for each of them)
PHENOTYPE_COUNT=2

# first phenotype: column name, trait type (quantitative/binary), covariates
PHENOTYPE_1=egfr_ckdepi_creat
TRAITTYPE_1=quantitative
COVARCOLS_1=batch,age_crea_serum,sex_male,PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10,PC11,PC12,PC13,PC14,PC15

# second phenotype
PHENOTYPE_2=egfr_ckdepi_creacys
TRAITTYPE_2=quantitative
COVARCOLS_2=batch,age_crea_serum,sex_male,PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10,PC11,PC12,PC13,PC14,PC15

# output directory
OUTPUT_DIR=Exome_50k/04_SAIGE/SAIGE/20190730_eGFR

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

# if using Docker, contianer version
SAIGE_VERSION=wzhou88/saige:0.35.8.2

# if not using Docker, paths to step* R scripts
SAIGE_STEP1_PATH=""
SAIGE_STEP2_PATH=""

# PLINK file with chip genotypes (used for null model),
# relative to base directory
PLINK_FILE=Exome_50k/03_Merge_GWAS_WES/chip_single_file/ukb_cal_49796

# BGEN file with imputed dosages or WES genotypes,
# relative to base directory
BGEN_FILE=Exome_50k/03_Merge_GWAS_WES/wes/wes_bgen/ukb_wes_efe-chr%CHR%.bgen

# SAMPLE file 
# absolute path
SAMPLE_FILE=/data/studies/06_UKBB/Exome_50k/03_Merge_GWAS_WES/imputed/ukb_subset_chr22.sample 

# output data for every i-th SNP (2 = every second)
NUM_LINES_OF_OUTPUT=2

# additional options to pass to step 1 and/or 2
STEP1_ADDITIONAL_OPTIONS=""
STEP2_ADDITIONAL_OPTIONS=""

