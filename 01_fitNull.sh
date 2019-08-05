PREFIX=/06_UKBB/Exome_50k/04_SAIGE/SAIGE/SAIGE_20190722_eGFR_chr22
PHENO=$PREFIX/ckdgen-UKBB_500k_phenoGWAS-EA.txt

docker run -v /data/studies/06_UKBB:/06_UKBB \
	wzhou88/saige:0.35.8.2 \
	step1_fitNULLGLMM.R \
	--plinkFile=/06_UKBB/Exome_50k/03_Merge_GWAS_WES/chip_single_file/ukb_cal_49796 \
	--phenoFile=$PHENO \
	--phenoCol=egfr_ckdepi_creat \
	--traitType=quantitative \
	--covarColList=age_crea_serum,sex_male,PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10,PC11,PC12,PC13,PC14,PC15 \
	--sampleIDColinphenoFile=IID \
	--outputPrefix=$PREFIX/egfr_nullGlmm \
        --nThreads=4 \
        --LOCO=FALSE \
	--invNormalize=FALSE \
		2>&1 | tee 01_fitNull.log


