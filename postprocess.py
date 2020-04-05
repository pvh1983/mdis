#!/usr/bin/env python3

import pandas as pd
import os
import matplotlib.pyplot as plt


'''
1. Process all_pmp.csv [all pmp given different pumping designs]
2. To RUN:
    - link code to folder /work/ftxx/output/
    - Provide input run scenarios (i.e., h2S4_pmp2000_max_min)
INPUT: all_pmpx.csv
OUTPUT: figures

'''

# Define some input options/parameters
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
ifile_log = wdir + 'output/output_log.txt'
fid = open(ifile_log, 'w')

# Define some functions


def read_data(wdir, dsg_sce, col_names, nobs):
    ifile = wdir + dsg_sce + '/all_pmp' + str(nobs) + '.csv'
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
    fid.write('\nList of the best models and frequency:\n')
    fid.write(f'{list_of_best_model}')

    # Save hist figures of posterior model probability
    fig, ax = plt.subplots()
    fig.set_size_inches(4, 3)
    plt.grid(color='#e6e6e6', linestyle='-', linewidth=0.5, axis='both')
    list_of_best_model.plot(kind='bar', title=dsg_sce)
    ax.set_ylabel('Frequency')
    ofile = odir + '/' + 'hist_best_model_' + \
        dsg_sce + '_nobs_' + str(nobs) + '.png'
    fig.savefig(ofile, dpi=150, transparent=False, bbox_inches='tight')
    print(f'Saved {ofile}')
    plt.close(fig)


# main
dsg_sce = ['h1S4_pmp2000_max_min_final', 'h1S4_pmp2000_max_max_final']
# dsg_sce = ['h2S4_pmp2000_max_min', 'h2S4_pmp2000_max_max']
#dsg_sce = ['h3S4_pmp2000_max_min', 'h3S4_pmp2000_max_max']
nobs = 4  # Max number of new obs wells

# [Cal 1] Final max-min IG ------------------------------------------------
for s in dsg_sce:
    for i in range(nobs):
        df = read_data(wdir, s, col_names, i+1)
        IG = abs(df['IG']).max()
        fid.write(f'{s}: nobs={i+1}, IG={IG}\n')

# [Plot 1] hist plots of the best models
for s in dsg_sce:
    for i in range(nobs):
        df = read_data(wdir, s, col_names, i+1)
        df = df[m]
        plot_pmp(df, s, i+1)


# [Plot 2] line plots of IG for different dsg_sce
for i in range(nobs):
    fig2, ax2 = plt.subplots()
    fig2.set_size_inches(8, 3)
    plt.grid(color='#e6e6e6', linestyle='-', linewidth=0.5, axis='both')
    for s in dsg_sce:
        df = read_data(wdir, s, col_names, i+1)
        #x = range(1, df.shape[0], 1)
        y = df['IG']
        ax2.plot(abs(y), label=s)
        ax2.set_ylabel('IG (nat)')
    ax2.set_title('nobs='+str(i+1))
    ax2.legend()  # Add a legend.
    ofile = odir + '/' + 'IG_'+'nobs_' + str(i+1) + '.png'
    fig2.savefig(ofile, dpi=150, transparent=False, bbox_inches='tight')
    print(f'Saved {ofile}')
    plt.close(fig2)

# [Plot 3] line plots of IG one dsg_sce different obs
for s in dsg_sce:
    fig2, ax2 = plt.subplots()
    fig2.set_size_inches(8, 3)
    plt.grid(color='#e6e6e6', linestyle='-', linewidth=0.5, axis='both')
    for i in range(nobs):
        df = read_data(wdir, s, col_names, i+1)
        #x = range(1, df.shape[0], 1)
        y = df['IG']
        ax2.plot(abs(y), label='nobs='+str(i+1))
        ax2.set_ylabel('IG (nat)')
    ax2.set_title(s)
    ax2.legend()  # Add a legend.
    ofile = odir + '/' + 'IG_' + s + '.png'
    fig2.savefig(ofile, dpi=150, transparent=False, bbox_inches='tight')
    print(f'Saved {ofile}')
    plt.close(fig2)

# [Plot 4] line plots of max_PMP one dsg_sce different obs

for s in dsg_sce:
    fig2, ax2 = plt.subplots()
    fig2.set_size_inches(8, 3)
    plt.grid(color='#e6e6e6', linestyle='-', linewidth=0.5, axis='both')
    for i in range(nobs):
        df = read_data(wdir, s, col_names, i+1)
        #x = range(1, df.shape[0], 1)
        df = df[m]
        max_df = df.max(axis=1)
        ax2.plot(max_df*100, label='nobs='+str(i+1))
        ax2.set_ylabel('Max PMP (%)')
    ax2.set_title(s)
    ax2.legend()  # Add a legend.
    ofile = odir + '/' + 'Max_PMP_' + s + '.png'
    fig2.savefig(ofile, dpi=150, transparent=False, bbox_inches='tight')
    print(f'Saved {ofile}')
    plt.close(fig2)

fid.close()
print(f'See the logfile at {ifile_log}\n')
# References
# [1] pandas.DataFrame.plot
# https://pandas.pydata.org/pandas-docs/version/0.23/generated/pandas.DataFrame.plot.html
