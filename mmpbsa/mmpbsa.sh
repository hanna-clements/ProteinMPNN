#!/bin/bash
# mmpbsa.sh <protein_mutation.pdb> <ligand_name> <GPU_ID>
f=$1
protein="$(cut -d'_' -f1 <<< $1)"
mutation="$(cut -d'_' -f2 <<< $1)"
ligand_name=$2
# Assume the PDB is ready to go (already cleaned and treated with ProPKA, pdb4amber)
# Define subdirectory names. This is what I want changed
protein_dir=./pdb_files
ligand_dir=./ligand_files
results_dir=./"${protein}_${mutation}_${ligand_name}_results"
mkdir -p $results_dir
# Check if ligand_name.pdb has a corresponding .frcmod file; make one if it doesn't
if [ ! -f $ligand_dir/$ligand_name.frcmod ]; then
  echo "Running antechamber on ligand"
  # Ask if the ligand has a non-zero charge
  read -p "Does the ligand have a non-zero charge? (yes/no): " charge_response
  if [ "$charge_response" == "yes" ]; then
    read -p "Enter the ligand charge value: " ligand_charge
    antechamber -i $ligand_dir/${ligand_name}.pdb -fi pdb -o $ligand_dir/${ligand_name}.mol2 -fo mol2 -c bcc -nc $ligand_charge
  else
    antechamber -i $ligand_dir/${ligand_name}.pdb -fi pdb -o $ligand_dir/${ligand_name}.mol2 -fo mol2 -c bcc -nc 0
  fi
  parmchk2 -i $ligand_dir/${ligand_name}.mol2 -f mol2 -o $ligand_dir/${ligand_name}.frcmod
fi
cd $results_dir
# copy the protein_mutation.pdb and ligand files to the results directory
cp $protein_dir/$1 .
cp $ligand_dir/${ligand_name}.pdb .
cp $ligand_dir/${ligand_name}.frcmod .
# define variables for leap
cat_site="cat_site"
rieske="rieske"
recname="${protein}_${mutation}.pdb"

comname=$1
complex=${1%.*}
receptor="${protein}_${mutation}"
ligand="${ligand_name}"
recname="${protein}_${mutation}.pdb"
ligname="${ligand_name}.pdb"
cat <<eof> leap.in
  source leaprc.protein.ff19SB
  loadamberprep ../${ligand_dir}/${cat_site}.prep
  loadamberparams ../${ligand_dir}/${cat_site}.frcmod
  loadamberprep ../${ligand_dir}/${rieske}.prep
  loadamberparams ../${ligand_dir}/${rieske}.frcmod
  addAtomTypes { { "ZN" "Zn" "sp3" } { "S3" "S" "sp3" } { "N2" "N" "sp3" } }
  set default PBradii mbondi2

  rec = loadpdb $recname
  bond rec.115.ZN rec.59.SG
  bond rec.115.ZN rec.62.SG
  bond rec.115.ZN rec.79.NE2
  bond rec.115.ZN rec.86.SG
  saveamberparm rec $receptor.prmtop $receptor.inpcrd

  lig = loadpdb $ligname
  saveamberparm lig $ligand.prmtop $ligand.inpcrd

  com = loadpdb $comname
  bond com.115.ZN com.59.SG
  bond com.115.ZN com.62.SG
  bond com.115.ZN com.79.NE2
  bond com.115.ZN com.86.SG
  saveamberparm com $complex.prmtop $complex.inpcrd

  quit
eof

tleap -f leap.in

if [ ! -f $complex.inpcrd ]
then
    echo "Warning: The file $complex.inpcrd does not exist. Cannot proceed."
pmemd.cuda -O -i ../mmpbsa/min.in -o $complex.min.out -p $complex.prmtop -c $complex.inpcrd -r $complex.min.rst -ref $complex.inpcrd
ambpdb -p $complex.prmtop -ext -c $complex.min.rst > $complex.min.pdb
pmemd.cuda -O -i ../mmpbsa/heat.in -o $complex.heat.out -p $complex.prmtop -c $complex.min.rst -r $complex.heat.rst -x $complex.heat.nc -ref $complex.min.rst
pmemd.cuda -O -i ../mmpbsa/equil.in -o $complex.equil.out -p $complex.prmtop -c $complex.heat.rst -r $complex.equil.rst -x $complex.equil.nc
pmemd.cuda -O -i ../mmpbsa/prod.in -o $complex.prod.out -p $complex.prmtop -c $complex.equil.rst -r $complex.prod.rst -x $complex.prod.nc
ambpdb -p $complex.prmtop -ext -c $complex.prod.rst > $complex.prod.pdb
#cp $complex.prod.pdb ../../../onedrive/mmpbsa/models
fi

mpirun -np 45 --use-hwthread-cpus MMPBSA.py.MPI -O -i ../mmpbsa/mmpbsa.in -o $complex.dat -cp $complex.prmtop -rp $receptor.prmtop -lp $ligand.prmtop -y $complex.prod.nc
#cp ../../results.csv .
python ../mmpbsa/getEnergies.py -i $complex.dat -o results.csv -b $protein -m $mutation -p $ligand_name
#cp $complex.dat ../../../onedrive/mmpbsa/energies
#mv results.csv ../../
