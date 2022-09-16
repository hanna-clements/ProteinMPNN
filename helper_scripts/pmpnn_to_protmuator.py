#this script will take pmpnn output file, the native pdb and mutate the native pdb to contain aa obtained from pmpnn using protmutator
#input: native pdb file, pmpnnfile
#output: protmutator file

import sys
import subprocess

pdbfile=sys.argv[1]
pmpnnfile=open(sys.argv[2]).readlines()
binder=sys.argv[3]
peptide=sys.argv[4]
refseq=[]
sequence=''
seqid=''
count=0

def finddiff(querys):
    muts=[]
    for x in range(0, len(querys)):
        if not refseq[0][x]==querys[x]:
            t_mut=refseq[0][x]+str(x+1)+querys[x]
            muts.append(t_mut)
    return muts
for line in pmpnnfile:
    line_strip=line.strip()
    if line_strip.startswith('>'):
        if count==1:
          #  print (seqid)
          #  print (sys.argv[1][:sys.argv[1].index('.')])
            if sys.argv[1][:sys.argv[1].index('.')] in seqid:
                refseq.append(sequence)
                sequence=''
        elif count>1:
        #    print(seqid)
            mutation=finddiff(sequence)
            mutfile=open('mutator.txt','w')
            mutfile.write('Input PDB File,'+pdbfile+','+'\n')
            mutfile.write('Active Chain,0,'+'\n')
            for x in mutation:
                mutfile.write(x+',')
            mutfile.write('\n')
            mutfile.close()
            outfile=binder+'_'+seqid+'_'+peptide+'.pdb'
            print(outfile,'outfile')
            subprocess.call(['protMutator', 'mutator.txt', outfile])
            print ("Mutatation complete with:",seqid+'\n')
         #   print (mutation)
         #   input()
            sequence=''
     #   print(seqid, "hkhkj",count)
        seqid=line_strip[1:]
        count+=1
    else:
        if ':' in line_strip:
            sequence+=line_strip[:line_strip.index(':')]
        else:
            sequence+=line_strip
mutation=finddiff(sequence)
mutfile=open('mutator.txt','w')
mutfile.write('Input PDB File,'+pdbfile+','+'\n')
mutfile.write('Active Chain,0,'+'\n')
for x in mutation:
    mutfile.write(x+',')
mutfile.write('\n')
mutfile.close()
outfile=binder+'_'+seqid+'_'+peptide+'.pdb'
#outfile=seqid+'.pdb'
#print(outfile,'outfile')
subprocess.call(['protMutator', 'mutator.txt', outfile])
print("Mutation complete with:",seqid+'/n')
#print (line_strip)
