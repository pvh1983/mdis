#!/usr/bin/env octave

clc; clear ; close all; tic

%{
This code: 
    1. Analyze the outputs from an optimal experiment design (i.e., *.mat files).
       i.e., read file out1.mat, out2.mat ... 
    2. These ouput files are from a single run_xxx (one new pmploc, multiple obsloc)

Last visit: 03/14/2020.
Status: In use. 
File history: 
03/14/2020: 
    - Clean up and print more notifications to the log file
    - Rename to analyze_single_run.m
03/25/2020
    - Minor edits to read new ouput file after the mpirun ver.
    -     

% How to use:
% Copy file analyze_sing_run.m to run_xxx folder
% octave analyze_sing_run.m 
% 
% NOTES: use copyfile_.py too run analyze_sing_run.m for all run folders

%}

% Input files: 
% ---- out*.mat (in run_xxx folder)

% Output file: *.tom
% pmp1.csv, pmp2.csv ... and *.tom

%delete('*.tom'); % Clean the old *.tom file


% Define other run options
%n_new_obs = 4; % from 1 to 5. 
n_new_obs = int8(str2num(getenv('max_nobs_loc')));
% MAKE SURE YOU CHANGE THESE PARAMETERS:
%runopt = 4; % Consider m. err or not: [1] with m. err; [0] no m.err

Dopt = int8(str2num(getenv('opt_future_obs'))); %[0] real obs; [1] BMA
%Dopt   = 1; % Choosing future observation data: [0] real obs; [1] BMA

Err_opt = int8(str2num(getenv('opt_mea_err'))); %[0] No mea err; [1] WITH err
%Err_opt = 1; % 1: yes; 0: NO

corr_flag     = 1; % corr = 1; no_corr = 0; - Not using this option here?
Nmodels = 9;
opt_run_true_model = 0; % 1:run; other: no_run
%run_folder_id = 3

% Jump to run_xxx folder
%cur_run_folder = strcat(pwd, '/run_', num2str(run_folder_id))
%cd(cur_run_folder)

% Run TrueGP2 given new pmp and obs locations
if opt_run_true_model == 1
    system('ln -s /home/ftsai/codes/run_mf_true_model.m .'); % link file
    run_mf_true_model
    fprintf("\nFinished running TRUE model GP2 with the new pmploc.\n");
else
    fprintf("\nNo TrueGP2 was run. Used the existing result.\n");
end

% Load some files
load head.mat
load('../err1024.mat')

ofile = strcat('output_', 'Dopt',num2str(Dopt),'Eopt',num2str(Err_opt), '.tom'); % To write outputs and logs
fid = fopen(ofile,'w');
fprintf(fid, "Curr dir: %s \n", pwd); fprintf(fid,"\n"); fprintf(fid,"\n");

for kk = 1:n_new_obs % max =5 to avoid numerical errors
    fout=strcat('out',num2str(kk),'.mat');
    fprintf(fid, "fout: %s =================================================== \n", fout);
    fprintf("\nReading file: %s \n", fout);
    load(fout);
    
    %save tmp.mat kk loc_opt_obs loc_opt_pmp err1024 Prior H Hopt_ 
    %fid ofile maxminEED_final runopt Dopt Err_opt corr_flag Nmodels
    %clear all; load tmp.mat;    
    %clear Hobs
    load Hobs1024points.mat


	% Find and print optimal observation locations ----------------------------
	%% read results.dat
    ifile_results = strcat('bk_results_',num2str(kk),'.tom')
	file_result = strcat(ifile_results); 
	r = load(file_result); r_all=r;
	[row col] = size(r);
	r(1:row-5,:) =[]; % Delete all, just take the last five values
	
	Nobs = length(r(1,:))-1; 
	minfit = max(r(:,Nobs+1));
    maxminEED_final = -minfit;
	obsid_tmp = find(r(:,Nobs+1) == minfit);
	obsid = r(obsid_tmp(end),1:Nobs); clear obsid_tmp
    
    fprintf(fid, "Observation locations: \n");
    fprintf(fid, '%d, ', obsid); fprintf(fid,"\n");
    fprintf(fid, "EED (maxmin or maxmax): %6.3f (nat)\n", maxminEED_final);   

    %%
    Dtmp(1:Nobs,1:9) = H(obsid,1,:); % Hopt
    



    % Get Hopt at a design location
    Hopt(1:length(obsid),1:Nmodels) = H(obsid,1,:);
    fprintf('%6.2f\n', size(Hopt));
    fprintf(fid, "\nHobs is: \n");
    fprintf(fid, '%6.2f, ', Hobs(obsid,1)); fprintf(fid,"\n");
    
    fprintf(fid, "Hopt are:\n");
    fprintf(fid, "GP1, GP2, GP3, IK1, IK2, IK3, IZ1, IZ2, IZ3\n");
    %for i=1:size(Hopt)(1)
    %    fprintf(fid, '%6.2f,', Hopt(i,:)'); 
    %end
    %writematrix(Hopt,fid,'-append')
    dlmwrite(fid,Hopt,'-append', 'precision','%4.3f')
    fprintf(fid,"\n");

    % CALCULATE COVARIANCE MATRIX
    % Within-model covariance as follows:
    for m = 1:Nmodels % Under model i
        Htmp(:,:) = H(obsid,:,m); % Errors of estimated heads 
        SIGi9(:,:,m) = cov(Htmp')*Prior(m,1); % Covariance matrix under model Mi
    end 
    clear Htmp 
    WMCV = sum(SIGi9,3);
    
    fprintf(fid, "HBMA are:\n");
    HBMA = Hopt*Prior;
    dlmwrite(fid,HBMA,'-append', 'precision','%4.3f')
    fprintf(fid,"\n");


    % Choosing of future observation data (D) and errors
   
    if Dopt == 1 && Err_opt == 1
        D = HBMA + err1024(obsid,1);
        fprintf(fid, "\nWARNING: [1] Used HBMA + err for future observation \n");        
    elseif Dopt == 1 && Err_opt == 0
        D = HBMA
        fprintf(fid, "\nWARNING: [2] Used HBMA (NO err) for future observation\n");        
    elseif Dopt == 0 && Err_opt == 1
        D = Hobs(obsid,1)+err1024(obsid,1);
        fprintf(fid, "\nWARNING: [3] Used Hobs + err for future observation \n");        
    elseif Dopt == 0 && Err_opt == 0
        D = Hobs(obsid,1);     % Use real observation data
        fprintf(fid, "\nWARNING: [4] Used Hobs (NO err) for future observation\n");        
    end 

    %fprintf('Hdiff:\n');
    for m = 1:Nmodels
        %Hdiff = Hopt(:,m) - Hobs(obsid,1)-err1024(obsid,1);
        Hdiff = Hopt(:,m) - D;
        %fprintf('%6.2f\n', Hdiff');
        SH(:,:,m) = (Hdiff*Hdiff')*Prior(m,1); % FULL COV. MATRIX
        %SH(:,:,m) = diag(Hdiff*Hdiff');
    end
    BMCV = sum(SH,3); clear SH

    SIG = BMCV + WMCV; % Total model covariance by BMA Nobs x Nobs
    SIG_err = eye(Nobs,Nobs);
    SIG_err(logical(eye(size(SIG_err)))) = err1024(obsid).^2; % Dig terms only

    %for m = 1:Nmodels
    COV9(:,:) = SIG + SIG_err;
    %end

    fprintf(fid, "SIGi9 (m^2): \n");
    %fprintf(fid, '%6.3e, ', SIGi9); fprintf(fid,"\n");
    for i=1:9
        dlmwrite(fid,SIGi9(:,:,m),'-append', 'precision','%4.3e')
        fprintf(fid,"\n");
    end
    fprintf(fid, "SIG_err (m^2): \n");
    %fprintf(fid, '%6.3e, ', SIG_err); fprintf(fid,"\n");
    dlmwrite(fid,SIG_err,'-append', 'precision','%4.3e')
    fprintf(fid,"\n");
    
    fprintf(fid, "BMCV (m^2): \n");
    %fprintf(fid, '%6.3e, ', BMCV); fprintf(fid,"\n");
    dlmwrite(fid,BMCV,'-append', 'precision','%4.3f')
    fprintf(fid,"\n");
    
    fprintf(fid, "WMCV (m^2): \n");
    %fprintf(fid, '%6.3e, ', WMCV); fprintf(fid,"\n");
    dlmwrite(fid,WMCV,'-append', 'precision','%4.3e')
    fprintf(fid,"\n");

    fprintf(fid, "COV9 (m^2): \n");
    %fprintf(fid, '%6.3e, ', WMCV); fprintf(fid,"\n");
    dlmwrite(fid,COV9,'-append', 'precision','%4.3f')
    fprintf(fid,"\n");

    %clear Dtmp
    %% CALCULATE LIKELIHOOD:
    for m = 1:Nmodels % models       	
        %L(m,1) = det(SIG_err+SIGi9(:,:,m))^(-1/2)*exp(-0.5*(D-Hopt(:,m))'*(SIG_err+SIGi9(:,:,m))^(-1)*(D-Hopt(:,m))); %            	
        L(m,1) = det(COV9(:,:))^(-1/2)*exp(-0.5*(D-Hopt(:,m))'*(COV9(:,:))^(-1)*(D-Hopt(:,m))); %            	
    end

    %% CALCULATED POSTERIOR MODEL PROBABILITY
    for m = 1:m
        %PMP(m,1) = L(m,1)/sum(L);
        PMP(m,1) = L(m,1)*Prior(m)/(L'*Prior);
    end

    %%
    clear D Dbar SIGi SIGi9 COV9 SIG SIG_err
    [NS IX] = sort(L,'descend'); % Clear Nsample
    for m = 2:Nmodels % models
        %fprintf(L(IX(m));
        BFac(m-1,1) = L(IX(1))/L(IX(m));
    end

    minK = min(BFac);
    BFac(9,1) = 999;
    results = [BFac PMP*100];
    
    fprintf(fid, "L(m,1) is: \n");
    fprintf(fid, '%5.2e, ', L); fprintf(fid,"\n");
    
    fprintf(fid, "Prior Model Probability is: \n");
    fprintf(fid, "%6.2f, ", Prior*100); fprintf(fid,"\n")

    fprintf(fid, "Posterior Model Probability is: \n");
    fprintf(fid, "%6.2f, ", PMP*100); fprintf(fid,"\n")
    fprintf(fid, "BFactor is: \n");
    fprintf(fid, "%6.2f, ", BFac); fprintf(fid,"\n")

    fprintf(fid, "Min BFac = %4.3f \n", minK)

    %dlmwrite('all_min_BFac.tom',BFac','-append','delimiter','\t');
    ofile_csv = strcat('pmp', num2str(kk),'.csv')
    dlmwrite(ofile_csv, [PMP', maxminEED_final, minK],'precision','%.6f','delimiter',',');
    %all_minBF(kk,:) = BFac;
    %all_PMP(kk,:) = PMP;
    fprintf(fid, "\n");    fprintf(fid, "\n");
end % obsid

fclose(fid);
fprintf("\nThe results were saved at %s \n", ofile)
%cd .. % Move back
toc
