#!/bin/bash
path_for_parsed_chains=$PWD"/parsed_pdbs.jsonl"
python3 $PMPNN/helper_scripts/parse_multiple_chains.py --input_path=$PWD --output_path=$path_for_parsed_chains
python3 $PMPNN/protein_mpnn_run.py \
        --jsonl_path $path_for_parsed_chains \
        --out_folder $PWD \
        --num_seq_per_target $2 \
        --sampling_temp "0.1" \
        --batch_size 1
rm $path_for_parsed_chains
file=${1%.*}
mkdir $PWD/models
colabfold_batch --amber --templates --num-recycle 3 --use-gpu-relax $PWD/$file".fa" $PWD"/models"