#!/bin/bash

if [ ! -f "$1" ]
then
	echo "Parameters file not found: $1"
	exit
fi
echo "Source parameters file: $1"
. $1

#####################################################################################

echo -n "Check parameters: "

if [ ! -d "${BASE_DIRECTORY}" ]
then
	echo "Base directory '${BASE_DIRECTORY}' not found."
	exit
fi

if [[ "${BASE_DIRECTORY}" == */ ]]
then
	echo "Base directory '${BASE_DIRECTORY}' must not end with '/'."
	exit
fi

if [ ! -d "${INSTALLATION_PATH}" ]
then
	echo "Installation path '${INSTALLATION_PATH}' not found."
	exit
fi

if [[ "${INSTALLATION_PATH}" == */ ]]
then
	echo "Installation path '${INSTALLATION_PATH}' must not end with '/'."
	exit
fi

if [ ! -f "${BASE_DIRECTORY}/${PHENO_FILE}" ]
then
	echo "Phenotype file '${BASE_DIRECTORY}/$PHENO_FILE' not found."
	exit
fi

if [ ! -f ${BASE_DIRECTORY}/${PLINK_FILE}.bed ]
then
	echo "PLINK .bed file '${BASE_DIRECTORY}/${PLINK_FILE}.bed' not found."
	exit
fi

for CHR in `seq 1 22`
do
	FN=`echo "${BASE_DIRECTORY}/${BGEN_FILE}" | sed s/%CHR%/$CHR/`
	if [ ! -f "${FN}" ]
	then
	        echo "BGEN file '${FN}' not found."
	        exit
	fi

	if [ ! -f "${FN}.bgi" ]
	then
		echo "BGI file '${FN}.bgi' not found."
		exit
	fi
done

if [ ! -f ${BASE_DIRECTORY}/${SAMPLE_FILE} ]
then
	echo "Sample file '${BASE_DIRECTORY}/${SAMPLE_FILE}' not found."
	exit
fi

echo "OK."

#####################################################################################

for PHENOTYPE_INDEX in `seq 1 100`
do
        PHENOTYPE_VAR="PHENOTYPE_${PHENOTYPE_INDEX}"
        TRAITTYPE_VAR="TRAITTYPE_${PHENOTYPE_INDEX}"
        COVARCOLS_VAR="COVARCOLS_${PHENOTYPE_INDEX}"

        PHENOTYPE=${!PHENOTYPE_VAR}
        TRAITTYPE=${!TRAITTYPE_VAR}
        COVARCOLS=${!COVARCOLS_VAR}

        if [ "${PHENOTYPE}" != "" ]
        then
                echo "Detected phenotype #${PHENOTYPE_INDEX}: ${PHENOTYPE}"
                PHENOTYPE_COUNT=${PHENOTYPE_INDEX}
        else
                echo "No more phenotypes (got ${PHENOTYPE_COUNT})."
                break
        fi

        if [ "${TRAITTYPE}" == "" ]
        then
                echo "Trait type ${TRAITTYPE_VAR} not given!"
                exit
        fi

        if [ "${COVARCOLS}" == "" ]
        then
                echo "Covariables ${COVARCOLS_VAR} not given!"
                exit
        fi
done

#####################################################################################

echo "Prepare directories and write sample file"

JOB_DIR="${BASE_DIRECTORY}/${OUTPUT_DIR}/jobs"
LOGS_DIR="${BASE_DIRECTORY}/${OUTPUT_DIR}/logs"
NULL_DIR="${BASE_DIRECTORY}/${OUTPUT_DIR}/nullModel"
SPARSE_DIR="${BASE_DIRECTORY}/${OUTPUT_DIR}/sparseGRM"
QC_DIR="${BASE_DIRECTORY}/${OUTPUT_DIR}/qc"

if [ "${MODE}" == "GENE" ]
then
	mkdir -p ${SPARSE_DIR}
fi

mkdir -p ${JOB_DIR} ${QC_DIR} ${NULL_DIR} ${LOGS_DIR}

cat ${BASE_DIRECTORY}/${SAMPLE_FILE} | \
        grep -v '#' \
	> ${BASE_DIRECTORY}/${OUTPUT_DIR}/my_sample_file.sample

#####################################################################################

ALL_JOBS_FN="${JOB_DIR}/000-ALL_JOBS.sh"
echo "#/bin/bash" > ${ALL_JOBS_FN}
chmod 0755 ${ALL_JOBS_FN}

echo "Write job files"
JOB_INDEX="0"

if [ "${MODE}" == "GENE" ]
then
	echo "Writing SparseGRM job (gene-based tests)"

        JOB_INDEX=$((JOB_INDEX+1))
        printf -v JOB_INDEX_PADDED "%03d" ${JOB_INDEX}
        JOB_FN="${JOB_DIR}/${JOB_INDEX_PADDED}-SparseGrm.sh"
        LOG_FN="${LOGS_DIR}/${JOB_INDEX_PADDED}-SparseGrm.log"
        echo "${JOB_FN}" >> ${ALL_JOBS_FN}

        if [ "${USE_DOCKER}" == "Y" ]
        then
                PREFIX="/data"
                echo "docker run -v ${BASE_DIRECTORY}:/data \\" > ${JOB_FN}
                echo "    ${SAIGE_VERSION} \\" >> ${JOB_FN}
                echo "    createSparseGRM.R \\" >> ${JOB_FN}
        else
                PREFIX=${BASE_DIRECTORY}
                echo "${SAIGE_STEP0_PATH} \\" > ${JOB_FN}
        fi

        echo "    --plinkFile=${PREFIX}/${PLINK_FILE} \\" >> ${JOB_FN}
        echo "    --outputPrefix=${PREFIX}/${OUTPUT_DIR}/sparseGRM/${OUTPUT_PREFIX} \\" >> ${JOB_FN}
        echo "    --nThreads=${NTHREADS} \\" >> ${JOB_FN}
	echo "    --numRandomMarkerforSparseKin=2000 \\" >> ${JOB_FN}
	echo "    --relatednessCutoff=0.125 \\" >> ${JOB_FN}
        echo "    ${STEP0_ADDITIONAL_OPTIONS} \\" >> ${JOB_FN}
        echo "    2>&1 | tee ${LOG_FN}" >> ${JOB_FN}
fi

#####################################################################################

for PHENOTYPE_INDEX in `seq 1 ${PHENOTYPE_COUNT}`
do
	PHENOTYPE_VAR="PHENOTYPE_${PHENOTYPE_INDEX}"
	TRAITTYPE_VAR="TRAITTYPE_${PHENOTYPE_INDEX}"
	COVARCOLS_VAR="COVARCOLS_${PHENOTYPE_INDEX}"
	PHENOTYPE=${!PHENOTYPE_VAR}
	TRAITTYPE=${!TRAITTYPE_VAR}
	COVARCOLS=${!COVARCOLS_VAR}

	echo "Prepare phenotype $PHENOTYPE_INDEX: $PHENOTYPE ($TRAITTYPE)"
	echo "Covariates: ${COVARCOLS}"
	RESULTS_DIR="${BASE_DIRECTORY}/${OUTPUT_DIR}/results/${PHENOTYPE}"
	mkdir -p ${RESULTS_DIR}

	JOB_INDEX=$((JOB_INDEX+1))
	printf -v JOB_INDEX_PADDED "%03d" ${JOB_INDEX}
	JOB_FN="${JOB_DIR}/${JOB_INDEX_PADDED}-NullGlm-${PHENOTYPE}.sh"
	LOG_FN="${LOGS_DIR}/${JOB_INDEX_PADDED}-NullGlm-${PHENOTYPE}.log"
	echo "${JOB_FN}" >> ${ALL_JOBS_FN}

	echo "#/bin/bash" > ${JOB_FN}
	chmod 0755 ${JOB_FN}

	if [ "${USE_DOCKER}" == "Y" ]
	then
		PREFIX="/data"
		echo "docker run -v ${BASE_DIRECTORY}:/data \\" >> ${JOB_FN}
		echo "    ${SAIGE_VERSION} \\" >> ${JOB_FN}
		echo "    step1_fitNULLGLMM.R \\" >> ${JOB_FN}
	else
		PREFIX=${BASE_DIRECTORY}
		echo "${SAIGE_STEP1_PATH} \\" >> ${JOB_FN}
	fi

	echo "    --plinkFile=${PREFIX}/${PLINK_FILE} \\" >> ${JOB_FN}
	echo "    --phenoFile=${PREFIX}/${PHENO_FILE} \\" >> ${JOB_FN}
        echo "    --phenoCol=${PHENOTYPE} \\" >> ${JOB_FN}
	echo "    --traitType=${TRAITTYPE} \\" >> ${JOB_FN}
	echo "    --covarColList=${COVARCOLS} \\" >> ${JOB_FN}
	echo "    --sampleIDColinphenoFile=${SAMPLE_ID_COL} \\" >> ${JOB_FN}
	echo "    --outputPrefix=${PREFIX}/${OUTPUT_DIR}/nullModel/${PHENOTYPE} \\" >> ${JOB_FN}

	if [ "${MODE}" == "GENE" ]
	then
		echo "Adding SparseGRM options to step 1 for gene-based tests."

		#echo "    --outputPrefix_varRatio=${PREFIX}/${OUTPUT_DIR}/nullModel/${PHENOTYPE}_varRatio \\" >> ${JOB_FN}
        	echo "    --sparseGRMFile=${PREFIX}/${OUTPUT_DIR}/sparseGRM/${OUTPUT_PREFIX}_relatednessCutoff_0.125_2000_randomMarkersUsed.sparseGRM.mtx \\" >> ${JOB_FN}
		echo "    --sparseGRMSampleIDFile=${PREFIX}/${OUTPUT_DIR}/sparseGRM/${OUTPUT_PREFIX}_relatednessCutoff_0.125_2000_randomMarkersUsed.sparseGRM.mtx.sampleIDs.txt \\" >> ${JOB_FN}

		if [ "${LOCO}" != "FALSE" ]
		then
			echo "WARNING: LOCO != FALSE is not recommended for gene-based tests."
		fi

	        echo "    --skipModelFitting=FALSE \\" >> ${JOB_FN}
	        echo "    --IsSparseKin=TRUE \\" >> ${JOB_FN}
	        echo "    --isCateVarianceRatio=TRUE \\" >> ${JOB_FN}
	fi

	echo "    --nThreads=${NTHREADS} \\" >> ${JOB_FN}
	echo "    --LOCO=${LOCO} \\" >> ${JOB_FN}
	echo "    --invNormalize=${INV_NORMALIZE} \\" >> ${JOB_FN}
	echo "    ${STEP1_ADDITIONAL_OPTIONS} \\" >> ${JOB_FN}
	echo "    2>&1 | tee ${LOG_FN}" >> ${JOB_FN}

#####################################################################################

	for CHR in `seq 1 22`
	do
	        BGEN_FN=`echo "${BGEN_FILE}" | sed s/%CHR%/$CHR/`
		GROUP_FN=`echo "${GROUP_FILE}" | sed s/%CHR%/$CHR/`

	        JOB_INDEX=$((JOB_INDEX+1))
        	printf -v JOB_INDEX_PADDED "%03d" ${JOB_INDEX}
	        JOB_FN="${JOB_DIR}/${JOB_INDEX_PADDED}-SPAtests-chr${CHR}-${PHENOTYPE}.sh"
	        LOG_FN="${LOGS_DIR}/${JOB_INDEX_PADDED}-SPAtests-chr${CHR}-${PHENOTYPE}.log"
		echo "${JOB_FN}" >> ${ALL_JOBS_FN}

		echo "#/bin/bash" > ${JOB_FN}
		chmod 0755 ${JOB_FN}

	        if [ "${USE_DOCKER}" == "Y" ]
        	then
	                echo "docker run -v ${BASE_DIRECTORY}:/data \\" >> ${JOB_FN}
	                echo "    ${SAIGE_VERSION} \\" >> ${JOB_FN}
	                echo "    step2_SPAtests.R \\" >> ${JOB_FN}
	        else
        	        echo "${SAIGE_STEP2_PATH} \\" >> ${JOB_FN}
	        fi

	        echo "    --chrom=${CHR} \\" >> ${JOB_FN}
	        echo "    --bgenFile=${PREFIX}/${BGEN_FN} \\" >> ${JOB_FN}
	        echo "    --bgenFileIndex=${PREFIX}/${BGEN_FN}.bgi \\" >> ${JOB_FN}
	        echo "    --sampleFile=${PREFIX}/${OUTPUT_DIR}/my_sample_file.sample \\" >> ${JOB_FN}
	        echo "    --minMAF=0.000001 \\" >> ${JOB_FN}
	        echo "    --minMAC=0.5 \\" >> ${JOB_FN}

	        if [ "${MODE}" == "GENE" ]
        	then
                	#echo "Adding options to step 2 for gene-based tests."
			echo "    --maxMAFforGroupTest=0.01 \\" >> ${JOB_FN}
			echo "    --IsSingleVarinGroupTest=TRUE \\" >> ${JOB_FN}
			echo "    --groupFile=${PREFIX}/${GROUP_FN} \\" >> ${JOB_FN}
		fi

	        echo "    --GMMATmodelFile=${PREFIX}/${OUTPUT_DIR}/nullModel/${PHENOTYPE}.rda \\" >> ${JOB_FN}
	        echo "    --varianceRatioFile=${PREFIX}/${OUTPUT_DIR}/nullModel/${PHENOTYPE}.varianceRatio.txt \\" >> ${JOB_FN}
	        echo "    --numLinesOutput=${NUM_LINES_OF_OUTPUT} \\" >> ${JOB_FN}
	        echo "    --IsOutputAFinCaseCtrl=FALSE \\" >> ${JOB_FN}
	        echo "    --IsDropMissingDosages=TRUE \\" >> ${JOB_FN}
	        echo "    --SAIGEOutputFile=${PREFIX}/${OUTPUT_DIR}/results/${PHENOTYPE}/${OUTPUT_PREFIX}${PHENOTYPE}-chr${CHR}.txt \\" >> ${JOB_FN}
	        echo "    ${STEP2_ADDITIONAL_OPTIONS} \\" >> ${JOB_FN}
		echo "    2>&1 | tee ${LOG_FN}" >> ${JOB_FN}
	done

#####################################################################################

	# write plotting driver script / gene formatting script
	JOB_INDEX=$((JOB_INDEX+1))
	printf -v JOB_INDEX_PADDED "%03d" ${JOB_INDEX}
	RESULT_PATH_PATTERN="${BASE_DIRECTORY}/${OUTPUT_DIR}/results/${PHENOTYPE}/${OUTPUT_PREFIX}${PHENOTYPE}-chr%CHR%.txt"
	if [ "${MODE}" == "GENE" ]
	then
                JOB_FN="${JOB_DIR}/${JOB_INDEX_PADDED}-Formatting-${PHENOTYPE}.sh"
                LOG_FN="${LOGS_DIR}/${JOB_INDEX_PADDED}-Formatting-${PHENOTYPE}.log"
                echo "${JOB_FN}" >> ${ALL_JOBS_FN}

                echo "#/bin/bash" > ${JOB_FN}
                chmod 0755 ${JOB_FN}
                echo "${INSTALLATION_PATH}/annotate_gene_results.sh ${BASE_DIRECTORY}/${OUTPUT_DIR}/results/${PHENOTYPE} ${INSTALLATION_PATH} 2>&1 | tee ${LOG_FN}" >> ${JOB_FN}
	else
		JOB_FN="${JOB_DIR}/${JOB_INDEX_PADDED}-Plotting-${PHENOTYPE}.sh"
		JOB_R_FN="${JOB_DIR}/${JOB_INDEX_PADDED}-Plotting-${PHENOTYPE}.R"
		LOG_FN="${LOGS_DIR}/${JOB_INDEX_PADDED}-Plotting-${PHENOTYPE}.log"
        	echo "${JOB_FN}" >> ${ALL_JOBS_FN}

        	echo "#/bin/bash" > ${JOB_FN}
        	chmod 0755 ${JOB_FN}
		echo "xvfb-run Rscript ${JOB_R_FN} 2>&1 | tee ${LOG_FN}" >> ${JOB_FN}

		echo "library(saigeutils)" >> ${JOB_R_FN}
		echo "perform_qc_plots(\"${RESULT_PATH_PATTERN}\"," >> ${JOB_R_FN}
		echo "   \"${BASE_DIRECTORY}/${OUTPUT_DIR}/qc/${PHENOTYPE}_qc\")" >> ${JOB_R_FN}
	fi

#####################################################################################

	# check positive control
	POSITIVE_CONTROL_VAR="POSITIVE_CONTROL_${PHENOTYPE_INDEX}"
	POSITIVE_CONTROL_DATA=${!POSITIVE_CONTROL_VAR}
	if [ "${POSITIVE_CONTROL_DATA}" != "" ]
	then
		JOB_INDEX=$((JOB_INDEX+1))
		printf -v JOB_INDEX_PADDED "%03d" ${JOB_INDEX}
		JOB_FN="${JOB_DIR}/${JOB_INDEX_PADDED}-CheckPositiveControl-${PHENOTYPE}.sh"
		LOG_FN="${LOGS_DIR}/${JOB_INDEX_PADDED}-CheckPositiveControl-${PHENOTYPE}.log"
		echo "${JOB_FN}" >> ${ALL_JOBS_FN}
		echo "#/bin/bash" > ${JOB_FN}
		echo "${INSTALLATION_PATH}/check_positive_control.sh ${RESULT_PATH_PATTERN} ${POSITIVE_CONTROL_DATA} ${MODE} 2>&1 | tee ${LOG_FN}" >> ${JOB_FN} 
	else
		echo "No positive control found for phenotype ${PHENOTYPE_INDEX} (${PHENOTYPE})"
	fi
done

echo "Done"

