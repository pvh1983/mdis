#!/bin/sh

export PATH=/home/ftsai/codes/:$PATH
export cur_dir=$(pwd)

# Choose Future observation data and measurement err
export opt_future_obs=1 # [0] Hobs, [1] HBMA
export opt_mea_err=0    # [0] no mea err, [1] with err

export nobs_loc=1 # min_new_obs from 1-4. Max:4
export max_nobs_loc=5 # max_new_obs from 1-4 (=1 run only 1newobs, =4 upto 4)
export n_new_pmp_wells=1 # new pmpwells: 1, 2 or 3

export opt_max_or_min=-1 # [-1] max; [1] min 

# Run script
#analyze_mult_runs.py
postprocess.py

# Check count, count2 in getfitness.sh
#cd run_3655
#expdsg_run.m > /dev/null

