#!/usr/bin/env python3

from shutil import copyfile
import subprocess
import os
import numpy as np
#import pandas as pd

'''
This code analyzes the results from multiple runs in an experimental design
TO RUN: 
    - Go to /work/ftxx/PMPRUN_SCE/
    - copy sing.linux
    - Link (copy) this file to the current foder (if needed)
    - python analyze_mult_runs.py
        [This runs analyze_single_run.m (in multiple run_xxx folder) 
          -> read out1.mat, out2.mat and so on
          -> Get file pmp1.csv, pmp2.csv ...]
  
Updates: 
- 03/23/2020: 

'''

#
opt_get_sing_pmp_csv_file = True  # run analyze_single_run.m

# Get variable values from system env
n_new_pmp_wells = int(os.getenv('n_new_pmp_wells'))  # Values of 1, 2, or 3
nobs = int(os.getenv('max_nobs_loc'))  # newobs wells (from 1-5).
Dopt = int(os.getenv('opt_future_obs'))
mea_err = int(os.getenv('opt_mea_err'))

nmodels = 9
cur_dir = os.getcwd()
#dsg_sce = 'h1S4_pmp2000_max_max'
# main program
if n_new_pmp_wells == 0:
    nruns = 1  # Number of run folders
elif n_new_pmp_wells == 1:
    nruns = 202  # Number of run folders
elif n_new_pmp_wells == 2:
    nruns = 1378  # Number of run folders
elif n_new_pmp_wells == 3:
    nruns = 3654  # Number of run folders

# Opend a txt file to print out log/results
ofile_log = 'res_logs.txt'
fid = open(ofile_log, 'w')
fid.write(f'Analyzing {cur_dir}\n')
fid.write('run_id, nobs_loc, notes\n')

if opt_get_sing_pmp_csv_file:
    for i in range(0, nruns, 1):  # Go to each folder
        # wpath = cur_dir + '/output/run_' + str(i+1) # Old, read output folder
        wpath = cur_dir + '/run_' + str(i+1)
        #wpath = 'run_' + str(i+1)

        os.chdir(wpath)

        # Delete some old files
        #subprocess.call(cmd, shell=True)

        os.system('rm -f analyze_single_run.m ')
        os.system('rm -f run_mf_true_model.m')

        # Prepare some files
        os.system(
            'ln -s /home/ftsai/codes/analyze_single_run.m')
        os.system('ln -s /home/ftsai/codes/run_mf_true_model.m .')
        #os.system('cp -f ../TrueGP2/mf54.lpf TrueGP2/')

        # Run Matlab code to analyze the result for one design
        os.system('octave analyze_single_run.m --silent > /dev/null')

        # Load ouput files and save the result
        # The csv file is created from analyze_single_run.m
        print(f'\n Run analyze_single_run.m at {wpath} \n')
    else:
        print('WARNING: Did not run analyze_single_run.m\n')

# Get the ID of failed runs
os.chdir(cur_dir)
count = 0
id_err_run = []
for k in range(nobs):
    pmp = np.empty((nruns, nmodels+2))  # add two more columns
    for i in range(0, nruns, 1):  # Go to each folder
        wpath = cur_dir + '/run_' + str(i+1)
        os.chdir(wpath)
        ifile_csv = 'pmp' + str(k+1) + 'Dopt' + str(Dopt) + '.csv'
        if os.path.isfile(ifile_csv):
            print(f'\nReading {wpath}/{ifile_csv}\n')
            data = np.loadtxt(ifile_csv, delimiter=',')
            pmp[i, :] = data.copy()
        else:
            print(f'ERROR: No {ifile_csv} for this run {wpath}\n')
            fid.write(f'ERROR: run_{i+1}, {k}, "no" {ifile_csv}\n')
            #data = np.empty((1, nmodels+2))
            pmp[i, :] = np.empty((1, nmodels+2))
            count += 1
            id_err_run.append(i+1)

    #    src = 'gaobs'
    #    dst = 'run_' + str(i+1) + '/gaobs'
    #    copyfile(src, dst)
        #os.system('cd ..')

    # Print the id of FAILED runs:

    # print(id_err_run)

    # Save to the output file
    ofile = cur_dir + '/res_Dopt' + \
        str(Dopt) + 'Eopt' + str(mea_err) + 'Nobs' + str(k+1) + '.csv'
    np.savetxt(ofile, pmp, fmt='%.4f', delimiter=',')
    print(f'Saved the output file at {ofile}\n')
fid.write('ID of FAILED run:\n')
fid.write(f'{set(id_err_run)}\n')
fid.write(f'Total number of FAILED runs: {len(set(id_err_run))}\n')
fid.close()
print(f'ERRORS (if found) are at {ofile_log}.\n')
# Next: postprocess.py to get figures
# Next: Cleanup (del *.csv in run_? folers)
