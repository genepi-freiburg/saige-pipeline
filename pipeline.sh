if [ ! -f "$1" ]
then
	echo "Parameters file not found: $1"
	exit
fi
echo "Source parameters file: $1"
. $1

echo -n "Check parameters: "

if [ ! -d "${BASE_DIRECTORY}" ]
then
	echo "Base directory '${BASE_DIRECTORY}' not found."
	exit
fi

if [ ! -f "${BASE_DIRECTORY}/${PHENO_FILE}" ]
then
	echo "Phenotype file '${BASE_DIRECTORY}/$PHENO_FILE' not found."
	exit
fi

# TODO check SAMPLE_ID_COL
# TODO check PHENOTYPE parameters

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

echo "Prepare directories and write sample file"

JOB_DIR="${BASE_DIRECTORY}/${OUTPUT_DIR}/jobs"
LOGS_DIR="${BASE_DIRECTORY}/${OUTPUT_DIR}/logs"
NULL_DIR="${BASE_DIRECTORY}/${OUTPUT_DIR}/nullModel"
QC_DIR="${BASE_DIRECTORY}/${OUTPUT_DIR}/qc"

mkdir -p ${JOB_DIR} ${QC_DIR} ${NULL_DIR} ${LOGS_DIR}

cat ${BASE_DIRECTORY}/${SAMPLE_FILE} | \
        grep -v '#' | \
        tail -n+2 > ${BASE_DIRECTORY}/${OUTPUT_DIR}/my_sample_file.sample

ALL_JOBS_FN="${JOB_DIR}/000-ALL_JOBS.sh"
echo "#/bin/bash" > ${ALL_JOBS_FN}
chmod 0755 ${ALL_JOBS_FN}

echo "Write job files"
JOB_INDEX="0"
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
	echo "    --nThreads=${NTHREADS} \\" >> ${JOB_FN}
	echo "    --LOCO=${LOCO} \\" >> ${JOB_FN}
	echo "    --invNormalize=${INV_NORMALIZE} \\" >> ${JOB_FN}
	echo "    ${STEP1_ADDITIONAL_OPTIONS} \\" >> ${JOB_FN}
	echo "    2>&1 | tee ${LOG_FN}" >> ${JOB_FN}

	for CHR in `seq 1 22`
	do
	        BGEN_FN=`echo "${BGEN_FILE}" | sed s/%CHR%/$CHR/`

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
	        echo "    --minMAF=0.0001 \\" >> ${JOB_FN}
	        echo "    --minMAC=1 \\" >> ${JOB_FN}
	        echo "    --GMMATmodelFile=${PREFIX}/${OUTPUT_DIR}/nullModel/${PHENOTYPE}.rda \\" >> ${JOB_FN}
	        echo "    --varianceRatioFile=${PREFIX}/${OUTPUT_DIR}/nullModel/${PHENOTYPE}.varianceRatio.txt \\" >> ${JOB_FN}
	        echo "    --numLinesOutput=${NUM_LINES_OF_OUTPUT} \\" >> ${JOB_FN}
	        echo "    --IsOutputAFinCaseCtrl=FALSE \\" >> ${JOB_FN}
	        echo "    --IsDropMissingDosages=TRUE \\" >> ${JOB_FN}
	        echo "    --SAIGEOutputFile=${PREFIX}/${OUTPUT_DIR}/results/${PHENOTYPE}/${OUTPUT_PREFIX}${PHENOTYPE}-chr${CHR}.txt \\" >> ${JOB_FN}
	        echo "    ${STEP2_ADDITIONAL_OPTIONS} \\" >> ${JOB_FN}
		echo "    2>&1 | tee ${LOG_FN}" >> ${JOB_FN}
	done

	# write plotting driver script
	JOB_INDEX=$((JOB_INDEX+1))
	printf -v JOB_INDEX_PADDED "%03d" ${JOB_INDEX}
	JOB_FN="${JOB_DIR}/${JOB_INDEX_PADDED}-Plotting-${PHENOTYPE}.sh"
	LOG_FN="${LOGS_DIR}/${JOB_INDEX_PADDED}-Plotting-${PHENOTYPE}.log"
        echo "${JOB_FN}" >> ${ALL_JOBS_FN}

        echo "#/bin/bash" > ${JOB_FN}
        chmod 0755 ${JOB_FN}

	echo "xvfb-run echo 'library(saigeutils)" >> ${JOB_FN}
	echo "perform_qc_plots(\"${BASE_DIRECTORY}/${OUTPUT_DIR}/results/${PHENOTYPE}/${OUTPUT_PREFIX}${PHENOTYPE}-chr%CHR%.txt\"," >> ${JOB_FN}
	echo "   \"${BASE_DIRECTORY}/${OUTPUT_DIR}/qc/${PHENOTYPE}_qc\")' \\" >> ${JOB_FN}
	echo " | R --vanilla 2>&1 | tee ${LOG_FN}" >> ${JOB_FN}

done

echo "Done"

