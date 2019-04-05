#!/bin/bash
script_root=$(cd $(dirname $0); pwd)


# show usage
command_name="$( basename $0 )"
function usage() {
	cat << EOS

Usage: $command_name [option] <chromosome> <path/to/the/reference> <path/to/the/mappability> <BWA|Bowtie> <output_directory> <path/to/the/case/bam> [path/to/the/control/bam]


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
EOS
	exit 1
}
# parse options
options_norm=""
options_seg=""
control_frag=1
whole_flag=0
single_flag=0
while getopts "hl:s:p:b:-:" opts
do
	case $opts in
		-)
			case "${OPTARG}" in
				control)
					options_seg+="--control "
					control_frag=0
					;;
				whole)
					whole_flag=1
					;;
				single)
					single_flag=1
					;;
				gc_bin)
					options_norm+="--gc_bin "
					;;
				NoMapBin)
					options_norm+="--NoMapBin "
					;;
				bin_only)
					options_norm+="--bin_only "
					;;
				fig_norm=*)
					options_norm+="--${OPTARG} "
					;;
				title_norm=*)
					options_norm+="--${OPTARG} "
					;;
				tmp_norm=*)
					options_norm+="--${OPTARG} "
					;;
				lambda=*)
					options_seg+="--${OPTARG} "
					;;
				tmp_seg=*)
					options_seg+="--${OPTARG} "
					;;
				fig_seg=*)
					options_seg+="--${OPTARG} "
					;;
				nrm)
					options_seg+="--nrm"
					;;
				bootstrap)
					options_seg+="--bootstrap"
					;;
				noscale)
					options_seg+="--noscale"
					;;
				strict)
					options_seg+="--strict "
					;;
				detail)
					options_seg+="--detail"
					;;
				help)
					usage
					;;
				*)
					echo incorrect option
					;;
			esac
			;;
		h)
			usage
			;;
		l)
			options_norm+="-l$OPTARG "
			;;
		s)
			options_norm+="-s$OPTARG "
			;;
		p)
			options_norm+="-p$OPTARG "
			;;
		b)
			options_norm+="-b$OPTARG "
			;;
	esac
done
# shift the indices of arguments
shift `expr ${OPTIND} - 1`
echo $options_norm
echo $options_seg
# arguments
chromosomes=$1
reference_dir=$2
mappability_dir=$3
BWAorBowtie=$4
output_dir=$5
path_to_the_case_bam=$6

if (( $control_frag == 0 )); then
	path_to_the_control_bam=$7
	echo you chose case-control analysis!
else
	echo you chose control-free analysis!
fi




function modified_bicseq2-norm() {
	working_dir=$1
	path_to_the_bam=$2
	# compile modified samtools
	if [ ! -d $working_dir/seq ]; then
		mkdir -p $working_dir/seq
		echo 'start compiling modified samtools.'
		$script_root/modified_samtools/samtools view -U $BWAorBowtie,$working_dir/seq/,N,N $path_to_the_bam 
	else
		echo 'seq directory exists. skip modified samtools step.'
	fi



	if [ -e $working_dir/config_norm ]; then
		rm $working_dir/config_norm
		echo remove config_norm
	fi
	if (( $whole_flag == 1 )); then
		# make config file for bicseq2-norm
		mkdir -p $working_dir/output_norm
		touch $working_dir/config_norm
		echo -e "chromName\tfaFile\tMapFile\treadPosFile\tbinFileNorm" >> $working_dir/config_norm
		while read -r line
		do
			echo -e "${line}\t$reference_dir/${line}.fa\t$mappability_dir/${line}.bedgraph\t$working_dir/seq/${line}.seq\t$working_dir/output_norm/${line}.norm.bin" >> $working_dir/config_norm
		done < $chromosomes
	fi
	if (( $single_flag == 1 )); then
		mkdir -p $working_dir/output_norm_single
		mkdir -p $working_dir/config_norm_single
		while read -r line
		do
			touch $working_dir/config_norm_single/config_norm_${line}
			echo -e "chromName\tfaFile\tMapFile\treadPosFile\tbinFileNorm" >> $working_dir/config_norm
			echo -e "${line}\t$reference_dir/${line}.fa\t$mappability_dir/${line}.bedgraph\t$working_dir/seq/${line}.seq\t$working_dir/output_norm_single/${line}.norm.bin" >> $working_dir/config_norm_${line}

		done < $chromosomes
	fi
	echo 'hello'
	touch $working_dir/output_file_norm
	NBICseq-norm.pl ${options_norm}$working_dir/config_norm $working_dir/output_file_norm

}

mkdir -p $output_dir/case_norm_dir
modified_bicseq2-norm $output_dir/case_norm_dir $path_to_the_case_bam

if (( $control_frag == 0 )); then
	mkdir -p $output_dir/case_norm_dir
	modified_bicseq2-norm $output_dir/control_norm_dir $path_to_the_control_bam
fi




# bicseq2-seg
if [ -e $output_dir/config_seg ]; then
	rm $output_dir/config_seg
fi

touch $output_dir/config_seg
echo -e "chromName\tbinFileNorm.Case\tbinFileNorm.Control" >> $output_dir/config_seg
while read -r line
do
	echo -e "${line}\t$output_dir/case_norm_dir/output_norm/${line}.norm.bin\t$output_dir/control_norm_dir/output_norm/${line}.norm.bin" >> $output_dir/config_seg
done < $chromosomes

touch $output_dir/output_seg
NBICseq-seg.pl ${options_seg}$output_dir/config_seg $output_dir/output_seg
