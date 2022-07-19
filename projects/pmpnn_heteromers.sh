#!/bin/bash
path_for_parsed_chains=$PWD"/parsed_pdbs.jsonl"
path_for_assigned_chains=$PWD"/assigned_pdbs.jsonl"
path_for_fixed_positions=$PWD"/fixed_pdbs.jsonl"
#path_for_tied_positions=$PWD"/tied_pdbs.jsonl"
chains_to_design="A B"
fixed_positions="11 12 13 14 15 16 17 20 39 42 43 81, 1 2 3 4"
#tied_positions="1 2 3 4 5 6 7 8, 1 2 3 4 5 6 7 8" #two list must match in length; residue 1 in chain A and C will be sampled togther;

python3 $PMPNN//helper_scripts/parse_multiple_chains.py --input_path=$PWD --output_path=$path_for_parsed_chains

python3 $PMPNN//helper_scripts/assign_fixed_chains.py --input_path=$path_for_parsed_chains --output_path=$path_for_assigned_chains --chain_list "$chains_to_design"

python3 $PMPNN//helper_scripts/make_fixed_positions_dict.py --input_path=$path_for_parsed_chains --output_path=$path_for_fixed_positions --chain_list "$chains_to_design" --position_list "$fixed_positions"

#python3 $PMPNN//helper_scripts/make_tied_positions_dict.py --input_path=$path_for_parsed_chains --output_path=$path_for_tied_positions --chain_list "$chains_to_design" --position_list "$tied_positions"

python3 $PMPNN/protein_mpnn_run.py \
        --jsonl_path $path_for_parsed_chains \
        --chain_id_jsonl $path_for_assigned_chains \
        --fixed_positions_jsonl $path_for_fixed_positions \
        --out_folder $PWD \
        --num_seq_per_target $2 \
        --sampling_temp "0.1" \
        --batch_size 1
rm $path_for_parsed_chains

file=${1%.*}
mkdir $PWD/models
colabfold_batch --templates --num-recycle 3 $PWD/$file".fa" $PWD"/models"
cd $PWD"/models"
mkdir bests
cp *_rank_1_*.pdb bests/
cp -r ../../mmpsba bests/
cp ../../mmpbsa_pipe.sh bests/
cp ../../mmpbsa_pipe_all.sh bests/
cd bests/
./mmpbsa_pipe_all.sh
