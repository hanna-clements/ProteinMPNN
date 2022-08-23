#this script will select for lowest score and above 0.3 seq_recovery
#input: pmpnn generated file in fasta format
import sys
import subprocess
pmpnnfile=open(sys.argv[1]).readlines()
seq_recovery=sys.argv[2]
outputfile=open(sys.argv[1][:sys.argv[1].index('.')]+'_pmpnnfilter.fa','w')
statfile=open(sys.argv[1][:sys.argv[1].index('.')]+'_pmpnnfilter_stat.csv','w')
statfile.write('Protein_Id'+'\t'+'Score'+'\t'+'Sequence_recovery'+'\n')
_score=[]
tcount=0
for line in pmpnnfile:
    line_strip=line.strip()
    if line_strip.startswith('>'):
        line_split=line_strip.split(',')
        if tcount>0:
            if float(line_split[3][line_split[3].index('=')+1:])>=float(seq_recovery):
                _score.append(line_split[2][line_split[2].index('=')+1:])
        tcount+=1
#print (_score)
_score_sorted=sorted(_score)
#print(_score_sorted)
_score_top100=_score_sorted[:100]
#print (_score_top100)
copying=False
count=0
for word in pmpnnfile:
    word_strip=word.strip()
    if word_strip.startswith('>'):
        copying=False
        word_split=word_strip.split(',')
        if count == 0:
            copying=True
            outputfile.write(word_split[0]+'\n')
            count+=1
        else:
            if float(word_split[3][word_split[3].index('=')+1:])>=float(seq_recovery):
                for x in _score_top100:
                    if (word_split[2][word_split[2].index('=')+1:])==x:
                        outputfile.write('\n'+'>Seq-'+str(count)+'\n')
                        statfile.write('Seq-'+str(count)+'\t'+word_split[2][word_split[2].index('=')+1:]+'\t'+word_split[3][word_split[3].index('=')+1:]+'\n')
                        count+=1
                        copying=True
                        break
    elif copying:
        outputfile.write(word_strip)
