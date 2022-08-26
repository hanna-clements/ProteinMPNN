#!/usr/bin/env python

"""
VERSION 2021.01


"""

import os, sys, numpy
import argparse

def main(argv):

    # Parse command line arguments
    parser = argparse.ArgumentParser()

    parser.add_argument( "-i", "--input_file", type=str, help="Input file name", required=False, action='store')
    parser.add_argument( "-l", "--input_list", type=str, help="File with list of input file names", required=False, action='store')
    parser.add_argument( "-o", "--output_file", type=str, help="Output file name", required=False, action='store')
    parser.add_argument( "-b", "--backbone", type=str, help="Binder backbone", required=False, action='store')
    parser.add_argument( "-m", "--mutations", type=str, help="Mutations", required=False, action='store')
    parser.add_argument( "-p", "--peptide", type=str, help="Peptide sequence(1-4)", required=False, action='store')
    parser.add_argument( "-v", "--verbose", action="store_true", help="Turn on output verbosity." )

    args = parser.parse_args()

    input_file = args.input_file
    input_list_file = args.input_list
    output_file = args.output_file
    backbone = args.backbone
    mutations = args.mutations
    peptide = args.peptide

    if not input_file and not input_list_file:
        sys.exit("Must specify either --input_file or --input_list to run. Neither found.")

    verbose = args.verbose
 
    all_input_files = []
    # Gather all inputs into one list:
    if input_file:
        all_input_files = [ input_file ]

    if input_list_file:
        with open(input_list_file) as ifile:
            list_items = [ x.strip() for x in ifile.readlines() ]

        all_input_files += list_items
    
    if verbose:
        print("All input files: {}".format(all_input_files))

    with open(output_file, 'a') as ofile:

        # Loop through each input file
        for dat in all_input_files:
        
            if verbose:
                print("\n\tInput file: {}".format( dat ))

            if verbose:
                print("\n\tOutput file: {}".format(output_file))

            # Get dat lines
            with open(dat) as dfile:
                dat_lines = dfile.readlines()

            # Iterate through lines, looking for chain B's OXT atom and writing atoms to output as we go
            rec_start = False
            receptor_energy = ''
            delta_total = ''

            for line in dat_lines:

                if line.startswith("Receptor:"):
                    rec_start = True

                if rec_start and line.startswith("TOTAL"):
                    receptor_energy = line.split()[1]
                    receptor_sterr = line.split()[3]
                    rec_start = False

                if line.startswith("DELTA TOTAL"):
                    delta_total = line.split()[2]
                    delta_sterr = line.split()[4]
                    delta = float(delta_total)
                    sterr = float(delta_sterr)
                    kd = numpy.exp(((delta-23.299)/4.885)/0.581862108)*1000000000
                    kdup = numpy.exp((((delta+sterr)-23.299)/4.885)/0.581862108)*1000000000
                    kddown = numpy.exp((((delta-sterr)-23.299)/4.885)/0.581862108)*1000000000
                    kderror = (kdup-kddown)/2
            ofile.write("{b},{m},{p},{d},{e},{r},{s},{k},{u}\n".format(b=backbone, m=mutations, p=peptide, d=delta_total, e=delta_sterr, r=receptor_energy, s=receptor_sterr, k=kd, u=kderror))

if __name__ == "__main__":
   main(sys.argv[1:])
