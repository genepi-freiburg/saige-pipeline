# saige-pipeline
SAIGE pipeline for single variant and gene-based tests

* Copy the parameters.sh script to a analysis-specific directory
* Adjust file to fit paths, outcomes etc.
* Run the pipeline.sh script passing the parameters file as the single parameter
* This generates a folder structure and scripts which can be used to run the associations.
** Uses one job per chromosome and phenotype.
** Has jobs for calculating the null model.

To be done
* Jobs for combining / plotting the output, QC
