import pandas as pd
import os
import matplotlib.pyplot as plt


'''
1. Process all_pmp.csv [all pmp given different pumping designs]
to run: link code to folder /work/ftxx/output/

'''

# Define some input options/parameters
wdir = '/work/ftsai/'
list_model = ['GP1', 'GP2', 'GP3', 'IK1', 'IK2', 'IK3', 'IZ1', 'IZ2', 'IZ3']
# odir = '../output/check_top_ele'
odir = wdir + 'output/figs/'
if not os.path.exists(odir):  # Make a new directory if not exist
    os.makedirs(odir)
    print(f'\nCreated directory {odir}\n')

# Open a txt file to print logs/results
ifile_log = wdir + 'output/output_log.txt'
fid = open(ifile_log, 'w')

# Define some functions


def plot_pmp(wdir, dsg_sce, list_model, nobs):
    ifile = wdir + dsg_sce + '/output/all_pmp' + str(nobs) + '.csv'
    df = pd.read_csv(ifile)
    print(f'\nReading {ifile}\n')
    df.columns = list_model

    # Count/find the best model
    max_pmp = df.max(axis=1)
    id_max_pmp = df.idxmax(axis=1)
    df['max_pmp'] = max_pmp
    df['id_max_pmp'] = id_max_pmp

    # Count the times a model becomes the best model
    list_of_best_model = id_max_pmp.value_counts()

    # Save figures
    fig, ax = plt.subplots()
    fig.set_size_inches(4, 3)
    plt.grid(color='#e6e6e6', linestyle='-', linewidth=0.5, axis='both')
    list_of_best_model.plot(kind='bar', title=dsg_sce)
    fid.write('\nList of the best models and frequency:\n')
    fid.write(f'{list_of_best_model}')
    ax.set_ylabel('Frequency')
    ofile = odir + '/' + 'hist_best_model_' + \
        dsg_sce + '_nobs_' + str(nobs) + '.png'
    fig.savefig(ofile, dpi=150, transparent=False, bbox_inches='tight')
    print(f'Saved {ofile}')
    plt.close(fig)

    # df.plot(kind='hist')
    # plt.show()


# Generate figures ============================================================
dsg_sce = ['h1S4_pmp2000_max_min', 'h1S4_pmp2000_max_max']
nobs = 4  # Max number of new obs wells
for s in dsg_sce:
    for i in range(nobs):
        nobs_in_this_dsg = i+1
        plot_pmp(wdir, s, list_model, nobs_in_this_dsg)

fid.close()
# References
# [1] pandas.DataFrame.plot
# https://pandas.pydata.org/pandas-docs/version/0.23/generated/pandas.DataFrame.plot.html
