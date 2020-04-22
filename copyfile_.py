#!/usr/bin/env python3

from shutil import copyfile
import os
#import save_outputs.py

nruns = 202

opt_copy_files = False
opt_copy_files2 = False
opt_delete_files = False
opt_cp_model_files = False
opt_cp_param_files = True

cur_dir = os.getcwd()


def cp_outputs(cur_dir, run_dir):
    # Place this file inside run_xxx folder
    #cur_dir = os.getcwd()
    #cur_dir = cur_dir.split('/')
    #cur_dir = '../output/'
    #run_sce = 'h1S4_pmp2000_max_min'
    #run_sce = os.getenv('run_sce')
    # Get run directory (this file created from getfitness.sh)
    #fid = open('param.txt', 'r')
    #line_content = fid.read()
    #run_dir = 'run_' + str(line_content.split()[0])
    # fid.close()

    # Create an output folder to save all results
    odir = cur_dir + run_dir + '/'
    if not os.path.exists(odir):  # Make a new directory if not exist
        os.makedirs(odir)
        print(f'\nCreated directory {odir}\n')

    # Copy files
    #cmd = 'cp -f out*.mat bk_results_*.tom parentobs.dat head.mat func_runtime.txt Hobs1024points.mat ' + odir
    cmd = 'cp -f out*.mat bk_results_*.tom head.mat Hobs1024points.mat func_runtime.txt Dnew_nobs_*.csv param.txt ' + odir
    #print(f'odri: {odir}\n')
    #print(f'cmd: {cmd}\n')
    os.system(cmd)


if opt_delete_files:
    for i in range(nruns):  # Work with nruns folders only
        cmd = 'rm -f run_' + str(i+1) + '/*.m' + \
            ' run_' + str(i+1) + '/pmploc*.*'
        # os.remove(file_name)
        os.system(cmd)

if opt_copy_files:
    list_of_run = os.listdir('output')
    count = 1
    for run_dir in list_of_run:

        '''
        # Copy files
        src = 'gaobs'
        dst = str(i+1) + '/gaobs'
        copyfile(src, dst)
        '''

        # Copy files
        #src = 'save_outputs.py'
        #dst = str(i+1) + '/' + src
        #copyfile(src, dst)

        os.chdir(run_dir)
        os.system('rm -f save_outputs.py')
        os.system('ln -s /home/ftsai/codes/save_outputs.py .')
        # print(os.getcwd())
        # cp_outputs(run_dir)
        odir = cur_dir + '/output/' + run_dir + '/'
        cmd = 'cp -f out*.mat bk_results_*.tom head.mat Hobs1024points.mat Dnew_nobs_*.csv param.txt ' + odir
        os.system(cmd)
        os.chdir(cur_dir)
        print(f'{count}/{len(run_dir)} Copying output files from folder {run_dir}')
        count += 1

if opt_cp_model_files:
    # models = ['GP1', 'GP2', 'GP3', 'IK1', 'IK2',
    #          'IK3', 'IZ1', 'IZ2', 'IZ3', 'TrueGP2']
    # os.system('cd ..')  # Move back on level
    #os.system('sleep 3')
    #print(f'Current directory: {os.getcwd()}\n')
    for i in range(1, 203, 1):
        run_dir = cur_dir + '/' + 'run_' + str(i)
        os.chdir(run_dir)
        os.system('rm -f dup_model_files.sh expdsg_final.m')
        os.system('ln -s /home/ftsai/codes/dup_model_files.sh .')
        os.system('ln -s /work/ftsai/h1S4_pmp2000_max_min/expdsg_final.m .')
        os.system('./dup_model_files.sh')
        os.chdir(cur_dir)

if opt_cp_param_files:
    #cur_dir = '/work/ftsai/h1S4_pmp2000_max_min/'
    #list_files = ['out1.mat', 'bk_results_1.tom']
    list_files = ['head.mat', 'Hobs1024points.mat']
    for i in range(1250, 3655, 1):
        #run_dir = cur_dir + '/' + 'run_' + str(i)
        # Copy files
        #src = cur_dir + 'output/' + 'run_' + str(i) + '/param.txt'
        for j in list_files:
            src = '/work/ftsai/h3S4_pmp2000_max_min/' + \
                'run_' + str(i) + '/' + j
            dst = cur_dir + '/run_' + str(i) + '/' + j
            cmd = 'cp -f ' + src + ' ' + dst
            print(f'{i}, {cmd}\n')
            # os.chdir(cmd)
            copyfile(src, dst)

if opt_copy_files2:
    #list_of_run = os.listdir('output')
    #count = 1
    # for run_dir in list_of_run:
    for i in range(2129, 3655, 1):
        run_dir = 'run_' + str(i)
        os.chdir(run_dir)
        cmd = 'mv -f * ../output/run_' + str(i)
        os.system(cmd)
        os.chdir(cur_dir)
        print(f'{i}/{3654} | {cmd}')
        #count += 1
