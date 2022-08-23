#!/bin/bash
cp -r /shared/Ancestral_reconstruction/mmpbsa_d/mmpbsa bests/
cp /shared/Ancestral_reconstruction/mmpbsa_d/mmpbsa_pipe.sh bests/
cp /shared/Ancestral_reconstruction/mmpbsa_d/mmpbsa_pipe_all.sh bests/
cd bests/
./mmpbsa_pipe_all.sh GAAA
