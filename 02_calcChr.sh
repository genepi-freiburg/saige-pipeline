PHENO=/06_UKBB/Exome_50k/02_Pheno/pheno/ckdgen-pheno-master/ckdgen-pheno-prep/out-UKBB500k/ckdgen-pheno-UKBB500k-201906251650.out.csv

PREFIX=/06_UKBB/Exome_50k/04_SAIGE/SAIGE/SAIGE_20190730_eGFR_WES

CHRS=`seq 1 22`
if [ "$1" != "" ]
then
	CHRS=$1
	echo "Got chromosome from command line: $CHRS"
fi

for CHR in $CHRS
do

	echo "Process chromosome: $CHR"

	BGEN=/06_UKBB/Exome_50k/03_Merge_GWAS_WES/wes/wes_bgen/ukb_wes_efe-chr${CHR}.bgen

	cat ../../../03_Merge_GWAS_WES/imputed/ukb_subset_chr22.sample | \
		grep -v '#' | \
		tail -n+2 > my_sample_file.sample

	docker run -v /data/studies/06_UKBB:/06_UKBB \
		wzhou88/saige:0.35.8.2 \
		step2_SPAtests.R \
	        --chrom=${CHR} \
	        --bgenFile=${BGEN} \
	        --bgenFileIndex=${BGEN}.bgi \
		--sampleFile=${PREFIX}/my_sample_file.sample \
	        --minMAF=0.0001 \
	        --minMAC=1 \
	        --GMMATmodelFile=${PREFIX}/egfr_nullGlmm.rda \
	        --varianceRatioFile=${PREFIX}/egfr_nullGlmm.varianceRatio.txt \
	        --SAIGEOutputFile=${PREFIX}/egfr_saige_glmm_output_chr${CHR}.txt \
	        --numLinesOutput=2 \
	        --IsOutputAFinCaseCtrl=FALSE \
		--IsDropMissingDosages=TRUE \
		2>&1 > 02_calcChr_chr${CHR}.log
done

