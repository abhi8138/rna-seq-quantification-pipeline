#!/bin/bash
#SBATCH --account=[account_id]
#SBATCH --job-name=salmon_quant
#SBATCH --array=1-200%16
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=64G
#SBATCH --time=02:00:00
#SBATCH --output=logs/salmon_%a.out
#SBATCH --error=logs/salmon_%a.err
#
# SLURM array wrapper around ../scripts/run_salmon_local.sh. This is the
# production version used on UBC's Sockeye cluster to process a long-COVID
# biobank cohort (1,000+ samples in batches of 200 via --array).
#
# FASTQs were staged into DATA_DIR ahead of time via a Globus transfer from
# the sequencing facility; that transfer step is institution-specific and
# is not part of this repo.
#
# CONFIGURE THESE FOR YOUR ENVIRONMENT:
SAMPLE_LIST="sample_list.txt"     # one sample name per line
DATA_DIR="/path/to/raw_fastqs"
SALMON_INDEX="human_index"
CONDA_ENV="rna_seq_env"

cd "$SLURM_SUBMIT_DIR"

module load miniconda3
source activate "$CONDA_ENV"

SAMPLE_NAME=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLE_LIST")
echo "=== Task $SLURM_ARRAY_TASK_ID: $SAMPLE_NAME ==="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/../scripts/run_salmon_local.sh" \
    "$SAMPLE_NAME" "$DATA_DIR" "$SALMON_INDEX" "$SLURM_CPUS_PER_TASK"
