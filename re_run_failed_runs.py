#!/usr/bin/env python3

from shutil import copyfile
import subprocess
import os
import numpy as np
import datetime


#import pandas as pd

'''
Place this script at a root folder such as h2S4_pmp2000_max_min


'''

opt_get_id_of_failed_runs = False
start_run_id = 1
stop_run_id = 1378
opt_rerun_failed_runs = False
opt_check_head_exist = True  # Check if head.mat exists

# Get ID of failed run
nruns = 1378  # Number of run folders [202, 1378, 3655]
n_new_obs = 4  # new observation wells (from 1 to 5).
nmodels = 9

#cur_dir = '/work/ftsai/'
#dsg_sce = 'h1S4_pmp2000_max_max'

cur_dir = os.getcwd()
cur_sce = cur_dir.split('/')[-1:][0]  # get the run scenario
print(f'cur_dir: {cur_dir}\n')
print(f'cur_sce: {cur_sce}\n')

Current_Date = datetime.datetime.today()

# [1]
if opt_get_id_of_failed_runs:
    ofile_id_failed_runs = 'id_failed_' + cur_sce + '.csv'  # output log file

    # Get the list of run directory
    list_of_run = os.listdir('output')

    # Open a file to write out id of failed runs
    fid = open(ofile_id_failed_runs, 'w')
    fid.write(f'{Current_Date}\n')
    fid.write(f'\nAnalyzing {cur_dir}\n')
    fid.write(f'\ni,j,file\n')
    list_id_failed = []

    # for i in list_of_run:  # Go to each folder
    for rid in range(start_run_id, stop_run_id+1, 1):  # Go to each folder
        i = 'run_' + str(rid)
        for j in range(1, n_new_obs+1, 1):
            fname = cur_dir + '/output/' + \
                str(i) + '/out' + str(j) + '.mat'

            if not os.path.isfile(fname):  # file not exist
                fid.write(f'{i}, {j}, {fname})\n')
                list_id_failed.append(i)
                print(f'Warning: File {fname} does not exist.\n')
    id = set(list_id_failed)
    fid.write('List of failed runs:\n')
    fid.write(f'{id}\n')
    fid.write(f'Total number of failed runs: {len(id)}\n')
    fid.close()
    print(f'The log file was saved at {cur_dir}\n')

# [2] Check if head.mat exist ========================================
if opt_check_head_exist:
    # Open a file to write log
    ofile_id_failed_runs = '/work/ftsai/output/' + \
        'id_head_failed_' + cur_sce + '.csv'
    fid = open(ofile_id_failed_runs, 'w')
    fid.write(f'{Current_Date}\n')
    fid.write(f'\nAnalyzing {cur_dir}\n')
    fid.write(f'\ni,file\n')
    list_id_failed = []
    for i in range(1, nruns+1, 1):  # Go to each folder
        # Name of a checking file
        fname = cur_dir + '/run_' + str(i) + '/out5.mat'
        if not os.path.isfile(fname):  # file not exist
            fid.write(f'{i}, {fname})\n')
            list_id_failed.append(i)
            print(f'Warning: File {fname} does not exist.\n')
    id_hed_failed = set(list_id_failed)
    fid.write('List of failed runs:\n')
    fid.write(f'{id_hed_failed}\n')
    fid.write(f'Total number of failed runs: {len(id_hed_failed)}\n')
    print(f'Total number of failed runs: {len(id_hed_failed)}\n')
    fid.close()
    print(f'The log file was saved at {ofile_id_failed_runs}\n')


if opt_rerun_failed_runs:
    # Prepre input files to re-run some failed runs.
    # List of failed runs
    #id = [8, 57, 60, 137, 153, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202]
    #id = [64, 37, 38, 43, 77, 111, 17]
    #cur_dir = '/work/ftsai/h1S4_pmp2000_max_max'

    # for i in range(6, nruns, 1):
    for i in id:
        wpath = cur_dir + '/run_' + str(i)
        print(f'\nWorking {wpath}')
        os.chdir(wpath)

        # Clean old files, link new files and dupplicate run folders
        os.system('rm -f dup_model_files.sh')
        os.system('rm -f sing.linux')
        os.system('ln -s /home/ftsai/codes/dup_model_files.sh .')
        cmd = 'ln -s ' + cur_dir + '/sing.linux .'
        os.system(cmd)
        os.system('./dup_model_files.sh')
        os.system('qsub sing.linux')

    # Next, submit a job to run octave expdsg_run.m
