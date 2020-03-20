from shutil import copyfile
import subprocess
import os
import numpy as np
#import pandas as pd

'''
Notes: 
- Analyze results from multiple runs in an experimental design
- 

'''

nruns = 3  # Number of run folders
nmodels = 9
pmp = np.empty((nruns, nmodels))
cur_dir = os.getcwd()
count = 0
id_err_run = []
for i in range(0, nruns, 1):  # Go to each folder
    wpath = cur_dir + '/run_' + str(i+1)
    print(f'Working {wpath} \n')
    os.chdir(wpath)

    # Prepare some files
    #subprocess.call(cmd, shell=True)
    os.system('rm -f analyze_single_run.m ')
    os.system('rm -f run_mf_true_model.m')

    os.system(
        'ln -s /home/ftsai/codes/analyze_single_run.m')
    os.system('ln -s /home/ftsai/codes/run_mf_true_model.m .')
    os.system('cp -f ../TrueGP2/mf54.lpf TrueGP2/')

    # Run Matlab code to analyze the result for one design
    os.system('octave analyze_single_run.m')

    # Load ouput files and save the result
    # The csv file is created from analyze_single_run.m
    if os.path.isfile('pmp.csv'):
        data = np.loadtxt('pmp.csv', delimiter=',')
        pmp[i, :] = data
    else:
        print(f'No pmp.csv for this run {wpath}\n')
        data = np.empty((1, 9))
        pmp[i, :] = data
        count += 1
        id_err_run.append(i+1)

#    src = 'gaobs'
#    dst = 'run_' + str(i+1) + '/gaobs'
#    copyfile(src, dst)
    #os.system('cd ..')

# Print the id of FAILED runs:
print(id_err_run)

# Save to the output file
ofile = cur_dir + '/all_pmp.csv'
np.savetxt(ofile, pmp, fmt='%.2f', delimiter=',')
print(f'Saved the output file at {ofile}\n')
