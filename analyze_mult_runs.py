#!/usr/bin/env python3

from shutil import copyfile
import subprocess
import os
import numpy as np
#import pandas as pd

'''
This code analyzes the results from multiple runs in an experimental design
TO RUN: 
    - Go to /work/ftxx/RUN_SCE/
    - Link (copy) this file to the current foder (if needed)
    - python analyze_mult_runs.py
        - This runs analyze_single_run.m (in multiple run_xxx folder) 
          -> read out1.mat, out2.mat and so on
          -> Get file pmp1.csv, pmp2.csv ...
  
Updates: 
- 03/23/2020: 

'''
opt_get_sing_pmp_csv_file = True

nruns = 1218  # Number of run folders [202, 1218, ]
n_new_obs = 4  # new observation wells (from 1 to 5).
nmodels = 9
pmp = np.empty((nruns, nmodels+2))  # add two more columns
cur_dir = os.getcwd()
#dsg_sce = 'h1S4_pmp2000_max_max'

# Opend a txt file to print out log/results
ofile_log = 'res_logs.txt'
fid = open(ofile_log, 'w')
fid.write(f'Analyzing {cur_dir}\n')
fid.write('run_id, nobs_loc, notes\n')

if opt_get_sing_pmp_csv_file:
    for i in range(0, nruns, 1):  # Go to each folder
        wpath = cur_dir + '/output/run_' + str(i+1)
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
        os.system('octave analyze_single_run.m --silent > tmp.log')

        # Load ouput files and save the result
        # The csv file is created from analyze_single_run.m
        print(f'\n Run analyze_single_run.m at {wpath} \n')
    else:
        print('WARNING: Did not run analyze_single_run.m\n')

# Get the ID of failed runs
os.chdir(cur_dir)
count = 0
id_err_run = []
for k in range(n_new_obs):
    for i in range(0, nruns, 1):  # Go to each folder
        wpath = cur_dir + '/output/run_' + str(i+1)
        os.chdir(wpath)
        ifile_csv = 'pmp' + str(k+1) + '.csv'
        if os.path.isfile(ifile_csv):
            print(f'\nReading {wpath}/{ifile_csv}\n')
            data = np.loadtxt(ifile_csv, delimiter=',')
            pmp[i, :] = data
        else:
            print(f'ERROR: No {ifile_csv} for this run {wpath}\n')
            fid.write(f'ERROR: run_{i+1}, {k}, "no" {ifile_csv}\n')
            data = np.empty((1, nmodels+2))
            pmp[i, :] = data
            count += 1
            id_err_run.append(i+1)

    #    src = 'gaobs'
    #    dst = 'run_' + str(i+1) + '/gaobs'
    #    copyfile(src, dst)
        #os.system('cd ..')

    # Print the id of FAILED runs:

    # print(id_err_run)

    # Save to the output file
    ofile = cur_dir + '/all_pmp' + str(k+1) + '.csv'
    np.savetxt(ofile, pmp, fmt='%.4f', delimiter=',')
    print(f'Saved the output file at {ofile}\n')
fid.write('ID of FAILED run:\n')
fid.write(f'{set(id_err_run)}\n')
fid.close()
print(f'ERRORS found. See file {ofile_log} for detail.\n')
# Next: postprocess.py to get figures
