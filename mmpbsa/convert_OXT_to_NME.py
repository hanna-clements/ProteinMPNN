#!/usr/bin/env python
"""
VERSION 2021.02
Converts the last OXT atom in the pdb to an NME atom and moves it to the end.

quick usage:    convert_OXT_to_NME.py -i <input_file>
    or          convert_OXT_to_NME.py -l <file_with_list_of_inputs>
                OUTPUTS will be named <input_file>_NME.pdb and will be put in the directory where the script was called.

full usage: convert_OXT_to_NME.py [-h] [-i INPUT_FILE] [-l INPUT_LIST] [-o OUTPUT_FILE] [-op OUTPUT_PREFIX] [-os OUTPUT_SUFFIX] [-od OUTPUT_DIRECTORY] [-rod] [-v]

optional arguments:
  -h, --help            show this help message and exit
  -i INPUT_FILE, --input_file INPUT_FILE
                        Input file name
  -l INPUT_LIST, --input_list INPUT_LIST
                        File with list of input file names
  -o OUTPUT_FILE, --output_file OUTPUT_FILE
                        Output file name (for use with -i)
  -op OUTPUT_PREFIX, --output_prefix OUTPUT_PREFIX
                        Prefix for output files (for use with -l)
  -os OUTPUT_SUFFIX, --output_suffix OUTPUT_SUFFIX
                        Suffix for output files (for use with -l; .pdb already assumed)
  -od OUTPUT_DIRECTORY, --output_directory OUTPUT_DIRECTORY
                        Output folder
  -rod, --use_relative_output_directory
                        Use basedir of PDB to determine output folder
  -v, --verbose         Turn on output verbosity.

User must specify -i or -l, where the input is single pdb file (-i) or file that lists all pdb files to be converted (-l).

The output is a pdb file where the last chain's OXT atom is moved to the end and converted to NME.
The output file name can be:
    -o : explicitly stated (use only for -i, or else all files will get the same name)

    or will have the input file's name flanked by a prefix and/or a suffix:
        -op : give output files a prefix ( example: coolprefix_ )
        -os : give the output files a suffix ( example: _coolsuffix )

    By default, the output files will be named <input_file>_NME.pdb

The output file directory can be controlled using
    -od : specific directory where output files will go
    -rod : uses the base directory of the input file as the output directory (so input file /home/me/test/input.pdb will have its output sent to /home/me/test/)

"""

import os, sys
import argparse



def main(argv):

    # Parse command line arguments
    parser = argparse.ArgumentParser()

    parser.add_argument( "-i", "--input_file", type=str, help="Input file name", required=False, action='store')
    parser.add_argument( "-l", "--input_list", type=str, help="File with list of input file names", required=False, action='store')
    parser.add_argument( "-o", "--output_file", type=str, help="Output file name (for use with -i)", required=False, action='store')
    parser.add_argument( "-op", "--output_prefix", type=str, help="Prefix for output files (for use with -l)", default="", required=False, action='store')
    parser.add_argument( "-os", "--output_suffix", type=str, help="Suffix for output files (for use with -l; .pdb already assumed)", default="", required=False, action='store')
    parser.add_argument( "-od", "--output_directory", type=str, help="Output folder", default="", required=False, action='store')
    parser.add_argument( "-rod", "--use_relative_output_directory", help="Use basedir of PDB to determine output folder", required=False, action='store_true')
    parser.add_argument( "-v", "--verbose", action="store_true", help="Turn on output verbosity." )

    args = parser.parse_args()

    input_file = args.input_file
    input_list_file = args.input_list
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

    # Loop through each input file
    for pdb in all_input_files:
    
        if verbose:
            print("\n\tInput file: {}".format( pdb ))

        # Generate output file name
        if args.output_directory:
            out_dir = args.output_directory

        elif args.use_relative_output_directory:
            out_dir = os.path.dirname(pdb) 

        else:
            out_dir = args.output_directory

        if args.output_prefix or args.output_suffix:
            output_file_name = os.path.join( out_dir, 
                                             "{pre}{pbase}{suff}.pdb".format( pre = args.output_prefix,
                                                                                pbase = os.path.basename(pdb).replace('.pdb',''),
                                                                                suff = args.output_suffix
                                                                              )
                                           )
        elif args.output_file:
            output_file_name = os.path.join( out_dir, args.output_file )

        else:
            output_file_name = os.path.join( out_dir, "{pbase}_NME.pdb".format( pbase = os.path.basename(pdb).replace('.pdb','')))

        if verbose:
            print("\n\tOutput file: {}".format(output_file_name))

        
        # Get PDB lines
        with open(pdb) as pfile:
            pdb_lines = pfile.readlines()

	# What number is the last OXT?
        oxt_count = sum('OXT' in line for line in pdb_lines)
        _store={}
        _nmeline={}
        for line in pdb_lines:
            if line.startswith('ATOM'):
                curr_chain= line.split()[4]
                if line.split()[2]=="OXT":
                    chainkey='Chain-OXT_'+curr_chain
                    if not chainkey in _store.keys():
                        _store[chainkey]=1
                    else:
                        _store[chainkey]+=1

        # Iterate through lines, looking for the last OXT atom and writing atoms to output as we go
        atom_num = 0
        current_oxt_count = 0
        prev_line=''
        ter_seen=0
        nmeline=''
        with open(output_file_name, 'w') as ofile:
            for line in pdb_lines:
                if line.startswith('ATOM'):
                    if atom_num==0:
                        cur_chain = line.split()[4]
                    if line.split()[2]=="OXT":
                        current_oxt_count += 1
                        
                        # If this is the last OXT, skip it and save the line for later.
                        for key,value in _store.items():
                            if cur_chain==key[key.index('_')+1:] and current_oxt_count == value:
                           #     atom_num += 1
                           #     atom_serial_number = str(atom_num).rjust(5) #6-10
                           #     atom_name = "N".ljust(4) #12-15
                           #     residue_name = "NME" #16-19
                            #    print (key, value, line)
                           #     ofile.write(line[0:6] + atom_serial_number + "  " + atom_name + residue_name + line[20:76])
                                nmeline=line
                                current_oxt_count=0
                                continue
         #                       break
                       # if curr_chain==current_oxt_count == oxt_count:
                       #         NME_line_A = line
                       #         continue
                       # if current_oxt_count == oxt_count:
                       #     NME_line = line
                       #     continue
                    else:
                        atom_num += 1
                        atom_serial_number =  str(atom_num).rjust(5)
                        if atom_num>1 and cur_chain==line.split()[4]:
                            ofile.write(prev_line)
                        #    ofile.write( line[0:6] + atom_serial_number + line[11:] )
                        elif atom_num>1 and not cur_chain==line.split()[4]:
                         #   last_line=line[0:6]+atom_serial_number+line[11:]
                            ofile.write(prev_line)
                           # atom_num += 1
                           # atom_serial_number = str(atom_num).rjust(5) #6-10
                            atom_name = "N".ljust(4) #12-15
                            residue_name = "NME" #16-19
        #                    print (key, value, line)
                            ofile.write(nmeline[0:6] + atom_serial_number + "  " + atom_name + residue_name + nmeline[20:76])
                            nmeline=''
                            atom_num+=1
                            atom_serial_number=str(atom_num).rjust(5)
                        prev_line=line[0:6]+atom_serial_number+line[11:]
                    cur_chain=line.split()[4]

                if line.startswith("TER"):# and cur_chain=='A':
                    ofile.write(line)
          #  for key,value in _nmeline.items():
          #      atom_num += 1
          #      atom_serial_number = str(atom_num).rjust(5) #6-10
          #      atom_name = "N".ljust(4) #12-15
          #      residue_name = "NME" #16-19
          #      ele_symbol = "N".rjust(2) #76-77
          #      ofile.write( value[0:6] + atom_serial_number + "  " + atom_name + residue_name + value[20:76])# + ele_symbol + value[78:] )



            if not nmeline=='':
                ofile.write(prev_line)
                atom_num += 1
                atom_serial_number = str(atom_num).rjust(5) #6-10
                atom_name = "N".ljust(4) #12-15
                residue_name = "NME" #16-19
                ele_symbol = "N".rjust(2) #76-77
                ofile.write( nmeline[0:6] + atom_serial_number + "  " + atom_name + residue_name + nmeline[20:76])# + ele_symbol + NME_line_A[78:] )
            ofile.write("END") 

if __name__ == "__main__":
   main(sys.argv[1:])
