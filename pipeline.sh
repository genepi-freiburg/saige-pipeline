echo "Source parameters file: $1"
if [ ! -f "$1" ]
then
	echo "Parameters file not found: $1"
	exit
fi
. $1


echo -n "Check parameters: "

if [ ! -d $BASE_DIRECTORY ]
then
	echo "Base directory '$BASE_DIRECTORY' not found."
	exit
fi

if [ ! -f $BASE_DIRECTORY/$PHENO_FILE ]
then
	echo "Phenotype file '$BASE_DIRECTORY/$PHENO_FILE' not found."
	exit
fi

# TODO check SAMPLE_ID_COL
# TODO check PHENOTYPE parameters

if [ ! -f $BASE_DIRECTORY/$PLINK_FILE.bed ]
then
	echo "PLINK .bed file '$BASE_DIRECTORY/$PLINK_FILE.bed' not found."
	exit
fi

for CHR in `seq 1 22`
do
	FN=`echo "$BASE_DIRECTORY/$BGEN_FILE.bgi" | sed s/%CHR%/$CHR/`
	if [ ! -f $FN ]
	then
	        echo "BGEN and/or BGEN.BGI file '${FN}' not found."
	        exit
	fi
done

if [ ! -f $BASE_DIRECTORY/$SAMPLE_FILE ]
then
	echo "Sample file '$BASE_DIRECTORY/$SAMPLE_FILE' not found."
	exit
fi

echo "OK."

echo "Prepare directories and write job files"

JOB_INDEX="1"

for $PHENOTYPE_INDEX in `seq 1 $PHENOTYPE_COUNT`
do
	PHENOTYPE=`eval PHENOTYPE_$PHENOTYPE_INDEX`
	TRAITTYPE=`eval TRAITTYPE_$PHENOTYPE_INDEX`
	COVARCOLS=`eval COVARCOLS_$PHENOTYPE_INDEX`

	echo "Prepare phenotype $PHENOTYPE_INDEX: $PHENOTYPE ($TRAITTYPE)"
	echo "Covariates: $COVARCOLS"
	JOB_DIR="${BASE_DIRECTORY}/${OUTPUT_DIR}/jobs"
	LOGS_DIR="${BASE_DIRECTORY}/${OUTPUT_DIR}/logs"
	NULL_DIR="${BASE_DIRECTORY}/${OUTPUT_DIR}/nullModel"
	RESULTS_DIR="{BASE_DIRECTORY}/${OUTPUT_DIR}/results/$PHENOTYPE"

	mkdir -p $JOB_DIR $RESULTS_DIR $NULL_DIR $LOGS_DIR

	JOB_INDEX=$((JOB_INDEX+1))
	printf -v JOB_INDEX_PADDED "%03d" $JOB_INDEX
	JOB_FN="$JOB_DIR/${JOB_INDEX_PADDED}-NullGlm-${PHENOTYPE}"
	LOG_FN="$LOGS_DIR/${JOB_INDEX_PADDED}-NullGlm-${PHENOTYPE}.log"

	echo "#/bin/bash" > $JOB_FN
	echo "docker run -v $BASE_DIRECTORY:/data \\" >> $JOB_FN
	echo "    $SAIGE_VERSION \\" >> $JOB_FN
	echo "    step1_fitNULLGLMM.R \\" >> $JOB_FN
	echo "    --plinkFile=/data/$PLINK_FILE \\" >> $JOB_FN
	echo "    --phenoFile=/data/$PHENO_FILE \\" >> $JOB_FN
        echo "    --phenoCol=$PHENOTYPE \\" >> $JOB_FN
	echo "    --traitType=$TRAITTYPE \\" >> $JOB_FN
	echo "    --covarColList=$COVARCOLS \\" >> $JOB_FN
	echo "    --sampleIDColinphenoFile=$SAMPLE_ID_COL \\" >> $JOB_FN
	echo "    --outputPrefix=/data/${OUTPUT_DIR}/nullModel/$PHENOTYPE \\" >> $JOB_FN
	echo "    --nThreads=$NTHREADS \\" >> $JOB_FN
	echo "    --LOCO=$LOCO \\" >> $JOB_FN
	echo "    --invNormalize=$INV_NORMALIZE \\" >> $JOB_FN
	echo "    $STEP1_ADDITIONAL_OPTIONS \\" >> $JOB_FN
	echo "    2>&1 | tee $LOG_FN" >> $JOB_FN

	for CHR in `seq 1 22`
	do

#        BGEN=/06_UKBB/Exome_50k/03_Merge_GWAS_WES/wes/wes_bgen/ukb_wes_efe-chr${CHR}.bgen

#        cat ../../../03_Merge_GWAS_WES/imputed/ukb_subset_chr22.sample | \
 #               grep -v '#' | \
#                tail -n+2 > my_sample_file.sample

#        docker run -v /data/studies/06_UKBB:/06_UKBB \
 #               wzhou88/saige:0.35.8.2 \
  #              step2_SPAtests.R \
   #             --chrom=${CHR} \
    #            --bgenFile=${BGEN} \
     #           --bgenFileIndex=${BGEN}.bgi \
      #          --sampleFile=${PREFIX}/my_sample_file.sample \
       #         --minMAF=0.0001 \
        #        --minMAC=1 \
         #       --GMMATmodelFile=${PREFIX}/egfr_nullGlmm.rda \
          #      --varianceRatioFile=${PREFIX}/egfr_nullGlmm.varianceRatio.txt \
           #     --SAIGEOutputFile=${PREFIX}/egfr_saige_glmm_output_chr${CHR}.txt \
            #    --numLinesOutput=2 \
             #   --IsOutputAFinCaseCtrl=FALSE \
              #  --IsDropMissingDosages=TRUE \
             #   2>&1 > 02_calcChr_chr${CHR}.log
	done

done

echo "Done"









## parameters for SAIGE runs

# Base directory
BASE_DIRECTORY=/data/studies/06_UKBB

# Path to phenotype file, relative to BASE_DIRECTORY, don't use '..'
PHENO_FILE=/06_UKBB/Exome_50k/04_SAIGE/SAIGE/SAIGE_20190722_eGFR_chr22/ckdgen-UKBB_500k_phenoGWAS-EA.txt

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
OUTPUT_DIR=/06_UKBB/Exome_50k/04_SAIGE/SAIGE/20190730_eGFR

# prefix for output files
OUTPUT_PREFIX=ukb_

# number of threads
NTHREADS=4

# leave-one-chromosome-out mode (FALSE/TRUE)
LOCO=FALSE

# inverse normalize phenotype (FALSE/TRUE)
INV_NORMALIZE=FALSE

# SAIGE version (Docker container name)
SAIGE_VERSION=wzhou88/saige:0.35.8.2

# PLINK file with chip genotypes (used for null model)
PLINK_FILE=/06_UKBB/Exome_50k/03_Merge_GWAS_WES/chip_single_file/ukb_cal_49796

# BGEN file with imputed dosages or WES genotypes
BGEN_FILE=/06_UKBB/Exome_50k/03_Merge_GWAS_WES/wes/wes_bgen/ukb_wes_efe-chr%CHR%.bgen

# SAMPLE file
SAMPLE_FILE=../../../03_Merge_GWAS_WES/imputed/ukb_subset_chr22.sample

# output data for every second SNP
NUM_LINES_OF_OUTPUT=2

# additional options to pass to step 1 and/or 2
STEP1_ADDITIONAL_OPTIONS=""
STEP2_ADDITIONAL_OPTIONS=""

