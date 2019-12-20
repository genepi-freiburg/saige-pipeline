#!/bin/bash
RESULTS_DIR=$1
PIPELINE_DIR=$2

if [ ! -d "${RESULTS_DIR}" ]
then
	echo "Result directory not found: $RESULTS_DIR - pass as first argument."
	exit 3
fi

if [ ! -d "${PIPELINE_DIR}" ]
then
        echo "Pipeline directory not found: $PIPELINE_DIR - pass as first argument."
        exit 4
fi

if [ `ls ${RESULTS_DIR}/*chr*.txt | wc -l` -le 0 ]
then
	echo "Results not found in results dir: ${RESULTS_DIR}/*chr*.txt"
	exit 5
fi

RESULTS_FN="${RESULTS_DIR}/gene_pvals.txt"

echo "Filtering data to: $RESULTS_DIR/gene_pvals.txt"

cat ${RESULTS_DIR}/*chr*.txt | \
	head -n 1 | \
        cut -d" " -f1-10,13,14 \
	> ${RESULTS_FN}

cat ${RESULTS_DIR}/*chr*.txt | \
	cut -d" " -f1-10,13,14 | \
	grep -v Gene \
	>> ${RESULTS_FN}

Rscript ${PIPELINE_DIR}/merge_gene.R \
	"${RESULTS_FN}" \
	"${PIPELINE_DIR}/aux/NCBI38.gene.loc" \
	"${RESULTS_DIR}/gene_pvals_annotate.txt"


