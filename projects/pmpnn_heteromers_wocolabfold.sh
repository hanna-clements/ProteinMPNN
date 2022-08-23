#!/bin/bash
file=${1%.*}
mkdir $file
cp $1 $file
cd $file
path_for_parsed_chains=$PWD"/parsed_pdbs.jsonl"
path_for_assigned_chains=$PWD"/assigned_pdbs.jsonl"
path_for_fixed_positions=$PWD"/fixed_pdbs.jsonl"
#path_for_tied_positions=$PWD"/tied_pdbs.jsonl"
path_for_bias=$PWD"/bias_pdbs.jsonl"
AA_list="D E"
bias_list="-1.39 -1.39"
chains_to_design="A B"
fixed_positions="59 62 73 78 79 86, 1 2 3 4"
#tied_positions="1 2 3 4 5 6 7 8, 1 2 3 4 5 6 7 8" #two list must match in length; residue 1 in chain A and C will be sampled togther;

python3 $PMPNN//helper_scripts/parse_multiple_chains.py --input_path=$PWD --output_path=$path_for_parsed_chains

python3 $PMPNN//helper_scripts/assign_fixed_chains.py --input_path=$path_for_parsed_chains --output_path=$path_for_assigned_chains --chain_list "$chains_to_design"

python3 $PMPNN//helper_scripts/make_fixed_positions_dict.py --input_path=$path_for_parsed_chains --output_path=$path_for_fixed_positions --chain_list "$chains_to_design" --position_list "$fixed_positions"

python $PMPNN//helper_scripts/make_bias_AA.py --output_path=$path_for_bias --AA_list="$AA_list" --bias_list="$bias_list"

#python3 $PMPNN//helper_scripts/make_tied_positions_dict.py --input_path=$path_for_parsed_chains --output_path=$path_for_tied_positions --chain_list "$chains_to_design" --position_list "$tied_positions"

python3 $PMPNN/protein_mpnn_run.py \
        --jsonl_path $path_for_parsed_chains \
        --chain_id_jsonl $path_for_assigned_chains \
        --fixed_positions_jsonl $path_for_fixed_positions \
        --out_folder $PWD \
        --num_seq_per_target $2 \
        --sampling_temp "0.2" \
        --bias_AA_jsonl $path_for_bias \
        --batch_size 1
        #--backbone_noise 0.05 \
rm $path_for_parsed_chains

#file=${1%.*}
python3 $PMPNN/helper_scripts/pmpnn_filter.py "${file}.fa" 0.3
python3 $PMPNN/helper_scripts/pmpnn_to_protmuator.py ../PS1165_GAKL.pdb "${file}_pmpnnfilter.fa"
mkdir models
mv *_Seq* models
cp -r /shared/Software/mmpbsa_d/mmpbsa models/
cd models
FILES=*.pdb
for f in $FILES
do
  ./mmpbsa/mmpbsa.sh $f 1 && wait
done
