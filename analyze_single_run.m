clc; clear ; close all; tic

%{
This code: 
    1. Analyze the outputs from optimal experiment design (i.e., *.mat files).
    2. xxx

Last visit: 03/14/2020.
Status: In use. 
File history: 
    - 03/14/2020: Clean up and print more notifications to the log file
    - 

% How to use:
% Copy this file to run_xxx folder
% octave Cal_BFac_at_best_obs_loc_using_real_data_093016.m 
% 

%}

% Input files: 
% ---- out*.mat (in run_xxx folder)

% Output file: *.tom
delete('*.tom'); % Clean the old *.tom file

% Define other run options
n_new_obs = 5; # from 1 to 5. 
% MAKE SURE YOU CHANGE THESE PARAMETERS:
runopt = 4; % Consider m. err or not: [1] with m. err; [0] no m.err
Dopt   = 1; % Choosing future observation data: [1] real obs; [0] BMA
mea_err_added = 0; % 1: yes; 0: NO
corr_flag     = 1; % corr = 1; no_corr = 0; - Not using this option here?
Nmodels = 9;


% Run TrueGP2 given new pmp and obs locations
system('ln -s /home/ftsai/codes/run_mf_true_model.m .'); % link file
run_mf_true_model
fprintf("\nRunning the TRUE model GP2 with the new pumping location.\n");

ofile = 'output.tom'; % To write outputs and logs
fid = fopen(ofile,'w');
fprintf(fid, "Curr dir: %s \n", pwd); fprintf(fid,"\n"); fprintf(fid,"\n");

for kk = 1:n_new_obs
    fout=strcat('out',num2str(kk),'.mat');
    fprintf(fid, "fout: %s \n", fout);
    fprintf("Reading file: %s \n", fout);
    load(fout);    
    save tmp.mat kk loc_opt_obs loc_opt_pmp err1024 Prior H Hopt_ fid ofile maxminEED_final runopt Dopt mea_err_added corr_flag Nmodels
    clear all; load tmp.mat;    
    clear Hobs
    load Hobs1024points.mat


    obsid = loc_opt_obs;
    Nobs = length(obsid);
    
    fprintf(fid, "Observation locations: \n");
    fprintf(fid, '%d, ', obsid); fprintf(fid,"\n");
    fprintf(fid, "EED (maxmin or maxmax): %6.3f\n", maxminEED_final);   

    %%
    Dtmp(1:Nobs,1:9) = H(obsid,1,:); % Hopt
    
    # Choosing of future observation data (D) and errors
    if mea_err_added == 1
        D = Hobs(obsid,1)+err1024(obsid,1);     % Use real observation data + err
        fprintf(fid, "\nWARNING: Measurement errors were ADDED to future obs.");
    else
        D = Hobs(obsid,1);     % Use real observation data
        fprintf(fid, "\nWARNING: NO measurement errors were added to future obs.");
    end

    if Dopt == 1
        fprintf(fid, "\nWARNING: Used REAL observation data (Hobs from GB2) for future obs.");        
    else
        fprintf(fid, "\nWARNING: Used BMA data for future obs.");
    end 

    # Get Hopt at a design location
    Hopt = H(obsid,1,:);
    
    fprintf(fid, "\nHobs is: \n");
    fprintf(fid, '%6.2f, ', Hobs(obsid,1)); fprintf(fid,"\n");
    
    fprintf(fid, "Hopt are: \n");
    fprintf(fid, '%6.2f, ', Hopt); fprintf(fid,"\n");

    % CALCULATE COVARIANCE MATRIX
    % Within-model covariance as follows:
    for m = 1:Nmodels % Under model i
        Htmp(:,:) = H(obsid,:,m); % Errors of estimated heads 
        SIGi9(:,:,m) = cov(Htmp')*Prior(m,1); % Covariance matrix under model Mi
    end 
    clear Htmp 
    WMCV = sum(SIGi9,3);

    for m = 1:Nmodels
        %Hdiff = Hopt(:,m) - Hobs(obsid,1)-err1024(obsid,1);
        Hdiff = Hopt(:,m) - D;
        SH(:,:,m) = (Hdiff*Hdiff')*Prior(m,1); % FULL COV. MATRIX
        %SH(:,:,m) = diag(Hdiff*Hdiff');
    end
    BMCV = sum(SH,3); clear SH

    SIG = BMCV + WMCV; % Total model covariance by BMA Nobs x Nobs
    SIG_err = eye(Nobs,Nobs);
    SIG_err(logical(eye(size(SIG_err)))) = err1024(obsid).^2; % Dig terms only

    for m = 1:Nmodels
        COV9(:,:,m) = SIG + SIG_err;
    end

    fprintf(fid, "SIGi9 is: \n");
    fprintf(fid, '%6.3e, ', SIGi9); fprintf(fid,"\n");
    fprintf(fid, "SIG_err is: \n");
    fprintf(fid, '%6.3e, ', SIG_err); fprintf(fid,"\n");
    fprintf(fid, "BMCV is: \n");
    fprintf(fid, '%6.3e, ', BMCV); fprintf(fid,"\n");
    fprintf(fid, "WMCV is: \n");
    fprintf(fid, '%6.3e, ', WMCV); fprintf(fid,"\n");

    #clear Dtmp
    %% CALCULATE LIKELIHOOD:
    for m = 1:Nmodels % models       	
        %L(m,1) = det(SIG_err+SIGi9(:,:,m))^(-1/2)*exp(-0.5*(D-Hopt(:,m))'*(SIG_err+SIGi9(:,:,m))^(-1)*(D-Hopt(:,m))); %            	
        L(m,1) = det(COV9(:,:,m))^(-1/2)*exp(-0.5*(D-Hopt(:,m))'*(COV9(:,:,m))^(-1)*(D-Hopt(:,m))); %            	
    end

    %% CALCULATED POSTERIOR MODEL PROBABILITY
    for m = 1:m
        #PMP(m,1) = L(m,1)/sum(L);
        PMP(m,1) = L(m,1)*Prior(m)/(L'*Prior);
    end

    %%
    clear D Dbar SIGi
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

    fprintf(fid, "Min BFac = %4.1f \n", minK)

    %dlmwrite('all_min_BFac.tom',BFac','-append','delimiter','\t');
    dlmwrite('pmp.csv',PMP','delimiter',',');
    %all_minBF(kk,:) = BFac;
    %all_PMP(kk,:) = PMP;
    fprintf(fid, "\n");    fprintf(fid, "\n");
end % obsid

fclose(fid);
fprintf("\nThe results were saved at %s \n", ofile)

% Hopt_all = Hopt_*Prior;
% Hobs_err = Hobs + err1024;
% 
% out = [Hobs err1024 Hobs+err1024 Hopt_ ];
% %%
% id1 = find(all_minBF(:,1) > 500);
% out2 = [all_minBF(id1,1) all_PMP(id1,:)];
% 
% min_EED = min(all_minBF(:,1));
% 
% id2 = find(all_minBF(:,1) < 500);
% max_EED = max(all_minBF(id2,1));
%%

%save all_var_minBF.mat all_minBF all_var Hobs_all Hopt_all
toc
