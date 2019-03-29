# bicseq2\_pipeline

This pipeline enables you to run bicseq2-norm and bicseq2-seg automatically.

# prerequirements

Prepare following files before you run bicseq2\_pipeline.
+ Prepare chromosome file. For detail, see the example directory.
+ Prepare reference files splitted by each chromosome and put them in a directory.
+ Prepare mappability files for each chromosome and put them in a directory.

Mappability files should be tab-deliminated and have two columns (start and end position). Raw mappability data is available from [here](https://bismap.hoffmanlab.org/). Determine optimal threshold and fix the file to the required format written before.

# Installation

Clone this repository to your favorite directory.
```
git clone https://github.com/dermasugita/bicseq2_pipeline.git

```

# Usage
```
Usage: /pathToTheClonedDirectory/bicseq2_pipeline.sh [option] <chromosome> <path/to/the/reference> <path/to/the/mappability> <BWA|Bowtie> <output_directory> <path/to/the/case/bam> [path/to/the/control/bam]


Options:
	-h | --help: show this message

	for bicseq2-norm:

        -l=<int>: read length
        -s=<int>: fragment size
        -p=<float>: a subsample percentage: default 0.0002.
        -b=<int>: bin the expected and observed as <int> bp bins; Default 100.
        --gc_bin: if specified, report the GC-content in the bins
        --NoMapBin: if specified, do NOT bin the reads according to the mappability
        --bin_only: only bin the reads without normalization
        --fig_norm=<string>: plot the read count VS GC figure in the specified file (in pdf format)
        --title_norm_norm=<string>: title of the figure
        --tmp_norm=<string>: the tmp directory for bicseq2-norm;

	for bicseq2-seg:

        --lambda=<float>: the (positive) penalty used for BICseq2
        --tmp=<string>: the tmp directory
        --help: pring this message
        --fig_seg=<string>: plot the CNV profile in a png file
        --title_seg=<string>: the title of the figure
        --nrm: do not remove likely germline CNVs (with a matched normal) or segments with bad mappability (without a matched normal)
        --bootstrap: perform bootstrap test to assign confidence (only for one sample case)
        --noscale: do not automatically adjust the lambda parameter according to the noise level in the data
        --strict: if specified, use a more stringent method to ajust the lambda parameter
        --control: the data has a control genome
        --detail: if specified, print the detailed segmentation result (for multiSample only)


Note:
	 If you have a control, you must specify to "--control" let BICseq2 know that the data is a case/control study.
	 Specify aligner you used for mapping as the fourth argument. BWA and Bowtie are supported.
```
