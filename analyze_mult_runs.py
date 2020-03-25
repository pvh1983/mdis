from shutil import copyfile
import subprocess
import os
import numpy as np
#import pandas as pd

'''
Updates: 
- 03/23/2020: 
Notes: 
- Analyze results from multiple runs in an experimental design
- Change nruns and dsg_sce
This code does:
- Go to run_x folders
- Run file analyze_single_run.m -> Get file pmp1.csv, pmp2.csv ...
    -- read out1.mat, out2.mat and so on

-  

'''
opt_get_pmp_csv = False

nruns = 202  # Number of run folders [202, 1378, ]
n_new_obs = 4  # new observation wells (from 1 to 5).
nmodels = 9
pmp = np.empty((nruns, nmodels))
cur_dir = os.getcwd()
#cur_dir = '/work/ftsai/'
#dsg_sce = 'h1S4_pmp2000_max_max'

# Opend a txt file to print out log/results
fid = open('res_logs.txt', 'w')
fid.write(f'Analyzing {cur_dir}\n')
fid.write('run_id, nobs_loc, notes\n')
count = 0
id_err_run = []

for i in range(0, nruns, 1):  # Go to each folder
    wpath = cur_dir + '/run_' + str(i+1)
    #wpath = 'run_' + str(i+1)
    print(f'Working {wpath} \n')
    os.chdir(wpath)

    # Delete some old files
    #subprocess.call(cmd, shell=True)
    '''
    os.system('rm -f analyze_single_run.m ')
    os.system('rm -f run_mf_true_model.m')

    # Prepare some files
    os.system(
        'ln -s /home/ftsai/codes/analyze_single_run.m')
    os.system('ln -s /home/ftsai/codes/run_mf_true_model.m .')
    #os.system('cp -f ../TrueGP2/mf54.lpf TrueGP2/')

    # Run Matlab code to analyze the result for one design
    os.system('octave analyze_single_run.m')
    '''
    # Load ouput files and save the result
    # The csv file is created from analyze_single_run.m
os.chdir(cur_dir)
for k in range(n_new_obs):
    for i in range(0, nruns, 1):  # Go to each folder
        wpath = cur_dir + '/run_' + str(i+1)
        os.chdir(wpath)
        ifile_csv = 'pmp' + str(k+1) + '.csv'
        print(f'Reading {ifile_csv}\n')
        if os.path.isfile(ifile_csv):
            data = np.loadtxt(ifile_csv, delimiter=',')
            pmp[i, :] = data
        else:
            print(f'No {ifile_csv} for this run {wpath}\n')
            fid.write(f'{i+1}, {k}, "no" {ifile_csv}')
            data = np.empty((1, 9))
            pmp[i, :] = data
            count += 1
            id_err_run.append(i+1)

    #    src = 'gaobs'
    #    dst = 'run_' + str(i+1) + '/gaobs'
    #    copyfile(src, dst)
        #os.system('cd ..')

    # Print the id of FAILED runs:
    fid.write('ID of FAILED run:')
    fid.write(f'{id_err_run}\n')
    # print(id_err_run)

    # Save to the output file
    ofile = cur_dir + '/all_pmp' + str(k+1) + '.csv'
    np.savetxt(ofile, pmp, fmt='%.2f', delimiter=',')
    print(f'Saved the output file at {ofile}\n')
fid.close()
