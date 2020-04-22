#!/usr/bin/env python3

import os

'''
This file copies the output file to a new directory (i.e., /work/ftxx/DSC_CSE/output/)
This file should be place in run_1, run_2, ... run_x folders

'''

print('This is save_outputs.py\n')
print(f'Current directory: {os.getcwd()}\n')

# Place this file inside run_xxx folder
#cur_dir = os.getcwd()
#cur_dir = cur_dir.split('/')
cur_dir = '../output/'
#run_sce = 'h1S4_pmp2000_max_min'
#run_sce = os.getenv('run_sce')
# Get run directory (this file created from getfitness.sh)
fid = open('param.txt', 'r')
line_content = fid.read()
run_dir = 'run_' + str(line_content.split()[0])
fid.close()

# Create an output folder to save all results =================================
odir = cur_dir + run_dir + '/'
if not os.path.exists(odir):  # Make a new directory if not exist
    os.makedirs(odir)
    print(f'Created an output directory {odir}\n')

# Copy files ==================================================================
#cmd = 'cp -f out*.mat bk_results_*.tom head.mat Hobs1024points.mat func_runtime.txt Dnew_nobs_*.csv param.txt ' + odir
cmd = 'cp -f out*.mat bk_results_*.tom param.txt ' + odir
print(f'odri: {odir}\n')
print(f'Excuted cmd: {cmd}\n')
os.system(cmd)


# Cleanup
models = ['GP1', 'GP2', 'GP3', 'IK1', 'IK2',
          'IK3', 'IZ1', 'IZ2', 'IZ3', 'TrueGP2']
os.system('cd ..')  # Move back on level
os.system('sleep 3')
#os.system('rm -f *.dat *.tom *.csv *.out *.hai out*.mat *.linux mf54.wel')
print(f'Current directory: {os.getcwd()}\n')
for m in models:
    cmd = 'rm -rf ' + run_dir + '/' + m
    os.system(cmd)
    os.chdir('..')
    print(f'Deleted {m} using cmd {cmd}\n')
