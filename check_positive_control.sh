#!/bin/bash
FILE=$1
PATTERN=$2
MODE=$3

if [ "$FILE" == "" ]
then
	echo "Need results file pattern as first input parameter."
	exit 1
fi

if [ "$PATTERN" == "" ]
then
	echo "Need positive control pattern (CHR:POS:GENE) as second parameter."
	exit 2
fi

if [ "$MODE" == "" ]
then
	echo "No mode - assume 'SV' for single variant tests."
	MODE="SV"
fi

echo "Got positive control: $PATTERN"
echo "Got file pattern: $FILE"

CHR=$(echo $PATTERN | cut -d':' -f1)
POS=$(echo $PATTERN | cut -d':' -f2)
GENE=$(echo $PATTERN | cut -d':' -f3)

if [ "$MODE" == "SV" ]
then
	FILE_QUAL=$(echo $FILE | sed s/%CHR%/$CHR/)
	echo "Searching for chr $CHR and position $POS in file $FILE_QUAL"

	OUT=$(grep ${CHR}:${POS} $FILE_QUAL)

	if [ "$OUT" == "" ]
	then
		echo "Position not found: $PATTERN"
		exit 3
	fi
	echo "Found: $OUT"

	PVAL=$(echo "$OUT" | cut -d" " -f14)
	echo "Got p-value: $PVAL"
else
	RESULTS_DIR=${FILE%/*}
	echo "Results directory: ${RESULTS_DIR}"

	OUT=$(grep ${GENE} ${RESULTS_DIR}/gene_pvals_annotate.txt)

        if [ "$OUT" == "" ]
        then
                echo "Gene not found: $GENE"
                exit 3
        fi
        echo "Found: $OUT"

        PVAL=$(echo "$OUT" | cut -d"	" -f2)
        echo "Got p-value: $PVAL"
fi

PVAL_NORM=$(echo $PVAL | sed 's/e/*10^/g')
echo "P-value in 'bc' format: $PVAL_NORM"

OK=$(echo "$PVAL_NORM < 0.05" | bc)
if [ "$OK" == "1" ]
then
	echo "OK: Positive control is associated."
else
	echo "NOT OK: Positive control not associated!"
fi

