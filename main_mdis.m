%{
List of files

[1] Run and analyze the results ===============================================
- Submit.linux (source activate p3)
    - exp_using_mpirun.py -> getfitness.sh 
        - input files: parentpmp.txt, pmploc256.txt, pmploc1024.txt, err1024.mat
    - expdsg_run.m (expdsg_final.m, pmpdsg.m, func_well.m, func_EED.m
                    
    - save_outputs.py (gather all output files to a new folder )
    - 

- Analyze_mult_runs.py 
    - Analyze results from multiple runs (get pmp_all?.csv)
    - Copy py this file to /work/ftxx/DSG_SCE/output/
    - python analyze_mult_runs.py 
    - This runs analyze_single_run.m. You can also run this manually
      by copying this file to a run_? folder and run it using octave.
    - Use submit sing.linux (this call Analyze_mult_runs.py)
- postprocess.py 
- re_run_failed_runs.py % 
- run get_figs.sh (this runs postprocess.py)
-  

%}




