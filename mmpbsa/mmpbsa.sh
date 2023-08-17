#!/bin/bash
#python ../mmpbsa/convert_OXT_to_NME.py -i $1 -o $1
f=$1
protein="$(cut -d'_' -f1 <<< $1)"
mutation="$(cut -d'_' -f2 <<< $1)"
peptide="$(cut -d'_' -f3 <<< $1)"
#mutation="$(cut -d'_' -f7 <<< $1)"
#peptide="$(cut -d'_' -f8 <<< $1)"
peptide=${peptide%.*}
pwd
mkdir $mutation
cp $1 $mutation
cd $mutation
echo "Current working directory:"
pwd
#comname="${1}_${2}_${3}.pdb"
#complex="${1}_${2}_${3}"
#receptor="${1}_${2}"
#ligand="${3}"
#recname="${1}_${2}.pdb"
#ligname="${3}.pdb"
echo $protein
echo $mutation
echo $peptide
comname=$1
complex=${1%.*}
receptor="${protein}_${mutation}"
ligand="${peptide}"
recname="${protein}_${mutation}.pdb"
ligname="${peptide}.pdb"
if [ ! -f $complex.prod.nc ]
then
python ../mmpbsa/splitpep.py $comname
#python ../mmpbsa/convert_OXT_to_NME.py -i $comname -o $comname -rod
mv 1.pdb $recname
mv 2.pdb $ligname
export CUDA_VISIBLE_DEVICES=$2
fi

if [ $protein == "id1" ]
then
cat <<eof> leap.in
  source leaprc.protein.ff19SB
  loadamberprep ZAFF.prep
  loadamberparams ZAFF.frcmod
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
elif [ $protein == "id2" ] || [ $protein == "id3" ]
then
cat <<eof> leap.in
  source leaprc.protein.ff19SB
  loadamberprep ZAFF.prep
  loadamberparams ZAFF.frcmod
  addAtomTypes { { "ZN" "Zn" "sp3" } { "S3" "S" "sp3" } { "N2" "N" "sp3" } }
  set default PBradii mbondi2

  rec = loadpdb $recname
  bond rec.84.ZN rec.40.SG
  bond rec.84.ZN rec.66.SG
  bond rec.84.ZN rec.78.SG
  bond rec.84.ZN rec.7.NE2

  bond rec.85.ZN rec.40.SG
  bond rec.85.ZN rec.37.SG
  bond rec.85.ZN rec.64.SG
  bond rec.85.ZN rec.12.SG

  bond rec.86.ZN rec.25.SG
  bond rec.86.ZN rec.28.SG
  bond rec.86.ZN rec.46.ND1
  bond rec.86.ZN rec.49.ND1
  saveamberparm rec $receptor.prmtop $receptor.inpcrd

  lig = loadpdb $ligname
  saveamberparm lig $ligand.prmtop $ligand.inpcrd

  com = loadpdb $comname
  bond com.84.ZN com.40.SG
  bond com.84.ZN com.66.SG
  bond com.84.ZN com.78.SG
  bond com.84.ZN com.7.NE2

  bond com.85.ZN com.40.SG
  bond com.85.ZN com.37.SG
  bond com.85.ZN com.64.SG
  bond com.85.ZN com.12.SG

  bond com.86.ZN com.25.SG
  bond com.86.ZN com.28.SG
  bond com.86.ZN com.46.ND1
  bond com.86.ZN com.49.ND1
  saveamberparm com $complex.prmtop $complex.inpcrd

  quit
eof
else
cat <<eof> leap.in
  source leaprc.protein.ff19SB
  set default PBradii mbondi2

  rec = loadpdb $recname
  saveamberparm rec $receptor.prmtop $receptor.inpcrd

  lig = loadpdb $ligname
  saveamberparm lig $ligand.prmtop $ligand.inpcrd

  com = loadpdb $comname
  saveamberparm com $complex.prmtop $complex.inpcrd

  quit
eof
fi
tleap -f leap.in

if [ ! -f $complex.prod.nc ]
then
# generate complex trajectory
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
python ../mmpbsa/getEnergies.py -i $complex.dat -o results.csv -b $protein -m $mutation -p $peptide
#cp $complex.dat ../../../onedrive/mmpbsa/energies
#mv results.csv ../../
