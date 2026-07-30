# RNA-seq Quantification Pipeline

QC-filters and quantifies paired-end RNA-seq FASTQs, producing a
transcript-level count matrix. Built for and run on UBC's Sockeye HPC
cluster against 1,000+ samples from the Quebec biobank long-COVID cohort,
feeding a downstream differential expression and multi-omics
(transcriptomic + metabolomic) analysis; the pipeline itself is
data-agnostic and works on any paired-end RNA-seq sample set.

**Publication:** *Pilot longitudinal integrated transcriptomic-metabolomic
study reveals immune and metabolic signatures in non-hospitalized
healthcare workers with long COVID.* Frontiers in Cellular and Infection
Microbiology (2026, in press).
https://doi.org/10.3389/fcimb.2026.1808564

## Where this fits in the larger pipeline

Raw FASTQs were staged onto the cluster ahead of time via a Globus
transfer from the sequencing facility; that transfer is institution/data
-agreement specific and is not part of this repo. What's here starts once
FASTQs are on disk.

## Pipeline steps

1. **seqkit pair** resynchronizes R1/R2 FASTQ pairs
2. **fastp** trims adapters and low-quality bases, producing per-sample QC
   reports (`.json` / `.html`)
3. **Salmon** quantifies transcript abundance against a pre-built index
   (`--validateMappings --gcBias --seqBias` for selective-alignment mode
   with bias correction)

Per-sample `quant.sf` outputs are later merged (e.g. with `tximport` in R)
into a single count matrix for downstream differential expression /
multi-omics analysis.

## Two ways to run it

- **`scripts/run_salmon_local.sh`**: the per-sample logic, runnable
  directly against one sample. Use this for local testing or a small demo
  set.
- **`slurm/run_salmon_array.sh`**: the production wrapper that runs the
  same script as a SLURM array job across a full sample list on an HPC
  cluster.

## Usage

```bash
conda env create -f environment.yml
conda activate rna-seq-quant

# 1. Build a Salmon index once (example: GENCODE human transcriptome)
salmon index -t gencode.v44.transcripts.fa.gz -i human_index -k 31

# 2. Run a single sample
./scripts/run_salmon_local.sh SAMPLE01 /path/to/fastqs human_index 4
```

For the SLURM version, edit the `CONFIGURE THESE FOR YOUR ENVIRONMENT`
block at the top of `slurm/run_salmon_array.sh` (sample list, data
directory, index path, conda env name) and submit with `sbatch`.

## Testing without the original cohort

Any small public paired-end RNA-seq dataset works for a demo run, for
example a single accession pulled from SRA with `fasterq-dump`. Point
`DATA_DIR` at wherever the FASTQs land and follow the usage steps above.
