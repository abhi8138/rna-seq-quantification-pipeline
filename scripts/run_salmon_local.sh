#!/bin/bash
#
# run_salmon_local.sh
#
# QC-filters paired-end RNA-seq FASTQs and quantifies transcript abundance
# with Salmon. This is the per-sample processing core of a pipeline
# originally run as a SLURM array job (see ../slurm/run_salmon_array.sh) on
# UBC's Sockeye HPC cluster, against 1,000+ samples from a long-COVID
# biobank cohort. This standalone version drops the SLURM scheduling so a
# single sample (or a small test set) can be run locally.
#
# --------------------------------------------------------------------------
# USAGE
#   ./run_salmon_local.sh <sample_name> <data_dir> <salmon_index_dir> [threads]
#
#   Expects paired FASTQs at:
#     <data_dir>/<sample_name>.R1.fastq.gz
#     <data_dir>/<sample_name>.R2.fastq.gz
#
# REQUIRES
#   seqkit, fastp, salmon on PATH (see ../environment.yml)
#   A pre-built Salmon index at <salmon_index_dir>. Build one from a
#   transcriptome FASTA (e.g. GENCODE) with:
#     salmon index -t transcripts.fa.gz -i <salmon_index_dir> -k 31
# --------------------------------------------------------------------------

set -euo pipefail

SAMPLE_NAME="${1:?Usage: $0 <sample_name> <data_dir> <salmon_index_dir> [threads]}"
DATA_DIR="${2:?Usage: $0 <sample_name> <data_dir> <salmon_index_dir> [threads]}"
SALMON_INDEX="${3:?Usage: $0 <sample_name> <data_dir> <salmon_index_dir> [threads]}"
THREADS="${4:-4}"

mkdir -p fastqs_repaired fastqs_filtered quants logs

REPAIRED_R1="fastqs_repaired/${SAMPLE_NAME}.R1.fastq.gz"
REPAIRED_R2="fastqs_repaired/${SAMPLE_NAME}.R2.fastq.gz"
CLEAN_R1="fastqs_filtered/${SAMPLE_NAME}.R1.clean.fastq.gz"
CLEAN_R2="fastqs_filtered/${SAMPLE_NAME}.R2.clean.fastq.gz"

echo "=== Processing $SAMPLE_NAME ==="

echo "--> Step 1: Resynchronizing FASTQ pairs with seqkit..."
seqkit pair \
    -1 "${DATA_DIR}/${SAMPLE_NAME}.R1.fastq.gz" \
    -2 "${DATA_DIR}/${SAMPLE_NAME}.R2.fastq.gz" \
    -O fastqs_repaired \
    -j "$THREADS"

echo "--> Step 2: Running fastp adapter trimming..."
fastp -i "$REPAIRED_R1" -I "$REPAIRED_R2" \
    -o "$CLEAN_R1" -O "$CLEAN_R2" \
    -j "fastqs_filtered/${SAMPLE_NAME}.json" \
    -h "fastqs_filtered/${SAMPLE_NAME}.html" \
    --thread "$THREADS"

echo "--> Step 3: Quantifying transcript abundances with Salmon..."
salmon quant -i "$SALMON_INDEX" -l A \
    -1 "$CLEAN_R1" -2 "$CLEAN_R2" \
    -p "$THREADS" \
    --validateMappings --gcBias --seqBias \
    -o "quants/${SAMPLE_NAME}"

echo "--> Step 4: Cleaning up intermediate files..."
rm -f "$REPAIRED_R1" "$REPAIRED_R2" "$CLEAN_R1" "$CLEAN_R2"

echo "=== Done: $SAMPLE_NAME ==="
