#!/usr/bin/env python3

import pandas as pd
import os
import matplotlib.pyplot as plt
import datetime

'''
1. Process all_pmp.csv [all pmp given different pumping designs]
2. To RUN:
    - execute get_figs.sh. Remember to provide input run scenarios
      (i.e., h2S4_pmp2000_max_min)
    - This code does:
        - export path to codes: export PATH=/home/ftsai/codes/:$PATH        
        - run postprocess.py (no need 'python postprocess.py')
INPUT: all_pmpx.csv
OUTPUT: figures

'''

# Get variable values from system env
n_new_pmp_wells = int(os.getenv('n_new_pmp_wells'))  # Values of 1, 2, or 3
nobs = int(os.getenv('max_nobs_loc'))  # newobs wells (from 1-5).
Dopt = int(os.getenv('opt_future_obs'))
mea_err = int(os.getenv('opt_mea_err'))

# If mannual input
# nobs = 5  # Max number of new obs wells choose 1 to 5
#n_new_pmp_wells = 1

wdir = '/work/ftsai/'
col_names = ['GP1', 'GP2', 'GP3', 'IK1', 'IK2',
             'IK3', 'IZ1', 'IZ2', 'IZ3', 'IG', 'MinBF']
m = ['GP1', 'GP2', 'GP3', 'IK1', 'IK2',
     'IK3', 'IZ1', 'IZ2', 'IZ3']
# odir = '../output/check_top_ele'
odir = wdir + 'output/figs/'
if not os.path.exists(odir):  # Make a new directory if not exist
    os.makedirs(odir)
    print(f'\nCreated directory {odir}\n')

# Open a txt file to print logs/results
ifile_log = wdir + 'output/olog_' + 'Dopt' + str(Dopt) + '.txt'
fid = open(ifile_log, 'a')
fid.write(
    f'\n\nStart time, {datetime.datetime.now()} --------------------------------\n')
fid.write(f'Dopt, {Dopt}\n')
fid.write(f'mea_err, {mea_err}\n')
# Define some functions
 

def read_data(wdir, dsg_sce, col_names, nobs, Dopt, mea_err):
    ifile = wdir + dsg_sce + '/res_Dopt' + \
        str(Dopt) + 'Eopt' + str(mea_err) + 'Nobs' + str(nobs) + '.csv'
    df = pd.read_csv(ifile)
    print(f'\nReading {ifile}\n')
    df.columns = col_names
    return df


def plot_pmp(df, dsg_sce, nobs):
    # Count/find the best model
    max_pmp = df.max(axis=1)
    id_max_pmp = df.idxmax(axis=1)
    df['max_pmp'] = max_pmp  # Max posterior model probability
    df['id_max_pmp'] = id_max_pmp

    # Count the times a model becomes the best model
    list_of_best_model = id_max_pmp.value_counts()
    fid.write('\nList of the best models and frequency for nobs={nobs}:\n')
    fid.write(f'{list_of_best_model}\n')

    # Save hist figures of posterior model probability
    fig, ax = plt.subplots()
    fig.set_size_inches(4, 3)
    plt.grid(color='#e6e6e6', linestyle='-', linewidth=0.5, axis='both')
    list_of_best_model.plot(kind='bar', title=dsg_sce, alpha=0.8)
    ax.set_ylabel('Frequency')
    ofile = odir + '/' + 'hist_best_model_' + \
        dsg_sce + '_nobs_' + str(nobs) + 'Dopt' + str(Dopt) + '.png'
    fig.savefig(ofile, dpi=150, transparent=False, bbox_inches='tight')
    print(f'Saved {ofile}')
    plt.close(fig)


# main program
if n_new_pmp_wells == 0:
    nruns = 1  # Number of run folders
    dsg_sce = ['h0S4_wi_corr_max_min_NEW2019']
elif n_new_pmp_wells == 1:
    #dsg_sce = ['h1S4_pmp2000_max_min_final', 'h1S4_pmp2000_max_max_final']
    #dsg_sce = ['h1S4_pmp2000_max_max_final']
    dsg_sce = ['d1pmp1000_mama_ver042020']
elif n_new_pmp_wells == 2:
    #dsg_sce = ['h2S4_pmp2000_max_min_final', 'h2S4_pmp2000_max_max_final']
    dsg_sce = ['h2S4_pmp2000_max_max_final']
elif n_new_pmp_wells == 3:
    #dsg_sce = ['h3S4_pmp2000_max_min', 'h3S4_pmp2000_max_max']
    #dsg_sce = ['h3S4_pmp2000_max_max']
    dsg_sce = ['d3pmp1000_mama_ver042020']
    

# [Cal 1] Final max-min IG ------------------------------------------------
for s in dsg_sce:
    fid.write(f'Run scenario, {s} --------------------------------\n')
    fid.write('Nobs,IG_min,IG_max,IG_std,MinBF_min,MinBF_max,MinBF_std\n')
    for i in range(nobs):
        df = read_data(wdir, s, col_names, i+1, Dopt, mea_err)
        IG_min, IG_max, IG_std = abs(df['IG']).min(), abs(
            df['IG']).max(), abs(df['IG']).std()

        MinBF_min, MinBF_max, MinBF_std = abs(df['MinBF']).min(), abs(
            df['MinBF']).max(), abs(df['MinBF']).std()
        fid.write(
            f'{i+1},{IG_min},{IG_max},{IG_std},{MinBF_min},{MinBF_max},{MinBF_std}\n')

# [Plot 1] hist plots of the best models
for s in dsg_sce:
    for i in range(nobs):
        df = read_data(wdir, s, col_names, i+1, Dopt, mea_err)
        df = df[m]
        plot_pmp(df, s, i+1)


# [Plot 2] nobs x n_dsg_sce line plots of IG for different dsg_sce
for i in range(nobs):
    fig2, ax2 = plt.subplots()
    fig2.set_size_inches(8, 3)
    plt.grid(color='#e6e6e6', linestyle='-', linewidth=0.5, axis='both')
    for s in dsg_sce:
        df = read_data(wdir, s, col_names, i+1, Dopt, mea_err)
        #x = range(1, df.shape[0], 1)
        y = df['IG']
        ax2.plot(abs(y), label=s, alpha=0.8)
        ax2.set_ylabel('IG (nat)')

        # Plot Bayes Factore in the secondary axis
        ax22 = ax2.twinx()
        y2 = df['MinBF']
        ax22.plot(abs(y2), color='r', alpha=0.8)
        ax22.set_ylabel('Bayes Factor')
    ax2.set_title('nobs='+str(i+1))
    ax2.legend()  # Add a legend.
    ofile = odir + '/' + 'IG_'+'nobs_' + str(i+1) + 'Dopt' + str(Dopt) + '.png'
    fig2.savefig(ofile, dpi=150, transparent=False, bbox_inches='tight')
    print(f'Saved {ofile}')
    plt.close(fig2)

# [Plot 3] dsg_sce LINE plots of IG one dsg_sce different obs
for s in dsg_sce:
    fig2, ax2 = plt.subplots()
    fig2.set_size_inches(8, 3)
    plt.grid(color='#e6e6e6', linestyle='-', linewidth=0.5, axis='both')
    for i in range(nobs):
        df = read_data(wdir, s, col_names, i+1, Dopt, mea_err)
        #x = range(1, df.shape[0], 1)
        y = df['IG']
        ax2.plot(abs(y), label='nobs='+str(i+1), alpha=0.8)
        ax2.set_ylabel('IG (nat)')
    ax2.set_title(s)
    ax2.legend()  # Add a legend.
    ofile = odir + '/' + 'IG_' + s + 'Dopt' + str(Dopt) + '.png'
    fig2.savefig(ofile, dpi=150, transparent=False, bbox_inches='tight')
    print(f'Saved {ofile}')
    plt.close(fig2)

# [Plot 4] dsg_sce HIST plots of IG one dsg_sce different obs
for s in dsg_sce:
    fig2, ax2 = plt.subplots()
    fig2.set_size_inches(8, 3)
    plt.grid(color='#e6e6e6', linestyle='-', linewidth=0.5, axis='both')
    for i in range(nobs):
        df = read_data(wdir, s, col_names, i+1, Dopt, mea_err)
        #x = range(1, df.shape[0], 1)
        y = df['IG']
        #ax2.plot(abs(y), label='nobs='+str(i+1))
        ax2.hist(abs(y), bins=50, density=False, histtype='step',
                 label='nobs='+str(i+1), alpha=0.8)  # color='blue', ls='dashed',
        ax2.set_ylabel('Frequency')
    ax2.set_title(s)
    ax2.legend()  # Add a legend.
    ofile = odir + '/' + 'IG_hist_' + s + 'Dopt' + str(Dopt) + '.png'
    fig2.savefig(ofile, dpi=150, transparent=False, bbox_inches='tight')
    print(f'Saved {ofile}')
    plt.close(fig2)

# [Plot 5] line plots of max_PMP one dsg_sce different obs
for s in dsg_sce:
    fig2, ax2 = plt.subplots()
    fig2.set_size_inches(8, 3)
    plt.grid(color='#e6e6e6', linestyle='-', linewidth=0.5, axis='both')
    for i in range(nobs):
        df = read_data(wdir, s, col_names, i+1, Dopt, mea_err)
        #x = range(1, df.shape[0], 1)
        df = df[m]
        max_df = df.max(axis=1)
        ax2.plot(max_df*100, label='nobs='+str(i+1), alpha=0.8)
        ax2.set_ylabel('Max PMP (%)')
    ax2.set_title(s)
    ax2.legend()  # Add a legend.
    ofile = odir + '/' + 'Max_PMP_' + s + 'Dopt' + str(Dopt) + '.png'
    fig2.savefig(ofile, dpi=150, transparent=False, bbox_inches='tight')
    print(f'Saved {ofile}\n')
    plt.close(fig2)

fid.write(f'\n\nFinish time: {datetime.datetime.now()}\n')
fid.close()
print(f'See the logfile at {ifile_log}\n')

#
# References
# [1] pandas.DataFrame.plot
# https://pandas.pydata.org/pandas-docs/version/0.23/generated/pandas.DataFrame.plot.html
