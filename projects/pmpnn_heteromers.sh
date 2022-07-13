#!/bin/bash
path_for_parsed_chains=$PWD"/parsed_pdbs.jsonl"
path_for_assigned_chains=$PWD"/assigned_pdbs.jsonl"
path_for_fixed_positions=$PWD"/fixed_pdbs.jsonl"
#path_for_tied_positions=$PWD"/tied_pdbs.jsonl"
chains_to_design="A"
fixed_positions="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 42 43 44 45 48 49 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 70 71 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 112 113 114 115 116 117 118 119, 1 2 3 4"
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
#colabfold_batch --amber --templates --num-recycle 3 --use-gpu-relax $PWD/$file".fa" $PWD"/models"        
