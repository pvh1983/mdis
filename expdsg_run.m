% EXPERIMENTAL DESING USING 1 ADDITIONAL PUMPING WELLs
% Version 5.0 LAST UPDATED: 07142016
% Version 6.0 LAST UPDATED: 10/03/2019 (DEL SIGMA_i)
% Version 6.1: 03/16/2020 some minor edits
% - High pumping rate (-1000)
% 03/20/2020: Add copy files and cleanup
% ATTENTION: All *.dat will be deleted!!!
  
clc; clear all; close all; tic
delete('*.dat');
delete('Dnew_nobs_*.csv');
delete('func_runtime.txt')

% Must read before submiting a job: 
nobsloc       = 1; % % of potential observation location
max_nobsloc = 4;
mea_err_added = 1; % 1: yes; 0: NO
corr_flag     = 1; % corr = 1; no_corr = 0;
pmprate = -1000;

%% Par in func_EED.m ? %%%
%% Comment pmpdsg if head.mat already available in each run %%%
%% getfitness.sh? %% OK
%% Prior OK? 

% initial parameter values
obs = load('pmploc1024.txt'); pmp = load('pmploc256.txt');
Nmodels = 9; rtime =  NaN(max_nobsloc,1);
Prior = [1.77E-01	1.90E-01	1.88E-01	1.71E-01	2.05E-01	6.94E-02	1.71E-13	4.26E-12	6.21E-10]';

% Run pmpdsg to get head.mat and use this file for obsdsg from 1 obs to 10 obs. 
chk = exist('head.mat'); % = 2 exist file.
if chk ~= 2
	pmpdsg % Call script pmpdsg.m to get head.mat
	fprintf("\nRun MC for 9 models, 320 realizations to get head.m\n");
else
	fprintf("\nhead.mat existed. No new model runs!!!\n");
end
%system('rm -r GP* IK* IZ*'); % Delete folders to save space

% Open file to save dnew


count = 1;
while nobsloc <= max_nobsloc	
	%for m = 1:Nmodels % Under model i
		%ofile_dnew = strcat('Dnew_nobs_',num2str(Nobs),'_model_', num2str(m),'.csv' );
		%date = datestr(now, 'dd/mm/yy-HH:MM');
		%dlmwrite(ofile_dnew,date,'-append',delimiter='');
	%end 
	outfile1 = strcat('out',num2str(nobsloc),'.hai');
	%outfile2 = strcat('out',num2str(nobsloc),'_excel.hai');
	outfile3 = strcat('out',num2str(nobsloc),'.mat');
    
	delete('*.dat');
	dlmwrite(outfile1,'WARNING: Deleted all *.dat files.','-append','delimiter','');

    % GENERATE FILE gaobs.inp
    fid = fopen('gaobs2.inp','w');
    fprintf(fid,'nparam= %2d, \n',nobsloc);
    fclose(fid); clear fid 
    %
    fid = fopen('gaobs4.inp','w');
    fprintf(fid,' parmin= %2d*1.0d0, \n',nobsloc);
    fprintf(fid,' parmax= %2d*512.0d0, \n',nobsloc);
    fprintf(fid,' nposibl= %2d*512, \n',nobsloc);
    fprintf(fid,' nichflg= %2d*1, \n',nobsloc);
    fprintf(fid,' $end \n');    
    fclose(fid); clear fid 
    system('cat gaobs1.inp gaobs2.inp gaobs3.inp gaobs4.inp > gaobs.inp');
    delete('gaobs2.inp'); delete('gaobs4.inp');
    
	% Run experimental design using xxx pmp wells and nobsloc
	ofile_mat = strcat('out',num2str(nobsloc),'.mat'); % make sure done running
	chk2 = exist(ofile_mat); % = 2 exist file.
	if chk2 ~= 2
		system('./gaobs > outdspobs.dat');
		fprintf("\nRun gaobs at nobs = %d\n", count);
	else
		fprintf("\nWARNING: Did not run gaobs at nobs = %d\n", count);
	end
    
	%dlmwrite(outfile1,'DONE running gaobs.','-append','delimiter','');

	cmd_cpfile = strcat('bk_results_', num2str(nobsloc), '.tom');
	%system(cmd_cpfile{:,:})
	
	%{
	% Find and print optimal observation locations
	%% read results.dat
	file_result = strcat('results.dat'); 

	r = load(file_result); r_all=r;
	[row col] = size(r);
	r(1:row-5,:) =[]; % Delete all, just take the last five values
	
	Nobs = length(r(1,:))-1; 
	minfit = max(r(:,Nobs+1));
	loc_opt_obs_tmp = find(r(:,Nobs+1) == minfit);
	loc_opt_obs = r(loc_opt_obs_tmp(end),1:Nobs); clear loc_opt_obs_tmp

	dlmwrite(outfile1,'The optimal observation locations:','-append','delimiter','');
	dlmwrite(outfile1,[loc_opt_obs],'-append','delimiter','\t');
	%}
	
	%% [2] RUN MODFLOW FOR TRUE MODEL GIVEN NEW PUMPING LOCATIONS
	loc_opt_pmp = load('param.txt');
	loc_opt_pmp(1) = []; % Delete the first row which is for ID
	func_well(pmp(loc_opt_pmp,2:4), pmprate); % generate the new pmp package
	load err1024 % Measurement errors
	Hobs = NaN(512,1);
	copyfile('mf54.wel','TrueGP2'); 
	cd('TrueGP2'); % Change to each model's directory (GP1, GP2 ...)	
	% Run MODFLOW (max 320 par realizations)
	Hobs = Ofunc; % Gen LPF pack. and run MODFLOW
	cd ..
	dlmwrite(outfile1,'DONE running TrueGP2 with new pmploc.','-append','delimiter','');
	%save('Hobs1024points.mat','Hobs');  % in ASCII format
	save -mat-binary Hobs1024points.mat Hobs
	dlmwrite(outfile1,'The pumping locations:','-append','delimiter','');
	dlmwrite(outfile1,[loc_opt_pmp],'-append','delimiter','\t');
	%dlmwrite(outfile1,'Saved Hobs at Hobs1024points.mat.','-append','delimiter','');

	count = count + 1;
	chk = exist('results.dat'); % = 2 exist file.
	if chk == 2
		movefile('results.dat',cmd_cpfile);
	end
	
	rtime(nobsloc,1) = toc/3600;	
	save -mat-binary data.mat
	movefile('data.mat',outfile3);	
	dlmwrite(outfile1,'Total run time for expdsg_run.m is:','-append','delimiter','');
	dlmwrite(outfile1,[rtime],'-append','delimiter','\t');
	nobsloc = nobsloc + 1


	%{
	%% [3] CALCULATE BAYES FACTOR
	load head.mat
	obsid = loc_opt_obs; 
	Hopt_(:,:) = H(:,1,:); % Heads by MLE model parameters

	% GIVEN POTENTIAL DESIGN LOCATIONS WITH id is obsid:
	Nobs = length(obsid);
	Hopt = Hopt_(obsid,:); 

	% CALCULATE COVARIANCE MATRIX
    % Within-model covariance as follows:
    for m = 1:Nmodels % Under model i
        Htmp(:,:) = H(obsid,:,m); 
        SIGi9(:,:,m) = cov(Htmp')*Prior(m,1); % Covariance matrix under model Mi
    end 
    clear Htmp 
    WMCV = sum(SIGi9,3);

    % The between-model covariance as follows:
    HBMA = Hopt*Prior;
    for m = 1:9
        Hdiff = Hopt(:,m) - HBMA;
        SH(:,:,m) = (Hdiff*Hdiff')*Prior(m,1); % FULL COV. MATRIX
    end
    BMCV = sum(SH,3); clear SH
    SIG = BMCV + WMCV; % Total model covariance by BMA Nobs x Nobs
	
	
	SIG_err = eye(Nobs,Nobs);
	SIG_err(logical(eye(size(SIG_err)))) = err1024(obsid).^2; % Dig terms only

	for m = 1:Nmodels
		COV9(:,:,m) = (SIG + SIG_err);
	end
	clear SIG SIGi9 i j k m 
	clear WMCV BMCV Ci_		

	
	% USE BMA AS FUTURE OBSERVATION DATA
	k=1; % Hopt
	Dtmp(1:Nobs,1:9) = H(obsid,k,:); 
	
	if mea_err_added == 1 	
		D = Dtmp*Prior; % Realization k of future data prediction by BMA + mea errors
	else
		D = Dtmp*Prior; % Realization k of future data prediction by BMA 
	end
	
	
	dlmwrite(outfile1,'Hobs HBMA  GP1 	 GP2 	 GP3 	 IK1 	 IK2 	 IK3 	 IZ1 	 IZ2 	 IZ3 ','-append','delimiter','');
    dlmwrite(outfile1,[Hobs(obsid,1) D Hopt],'-append','delimiter','\t');
	%clear id_obs
	
	
    %% CALCULATE LIKELIHOOD:	
	clear Dtmp
	for m = 1:Nmodels % models
		if corr_flag==0
			COVM = zeros(Nobs,Nobs); 
			COVM(logical(eye(size(COVM)))) = diag(COV9(:,:,m));    
			%L(m,1) = (2*pi)^(-Nobs/2)*det(COVM)^(-1/2)*exp(-0.5*(D-Hopt(:,m))'*(COVM)^(-1)*(D-Hopt(:,m))); %
			XX = -0.5*(D-Hopt(:,m))'*(COVM)^(-1)*(D-Hopt(:,m));
			L(m,1) = det(COVM)^(-1/2)*exp(XX); 		
			clear XX; %
		else
			%L(m,1) = (2*pi)^(-Nobs/2)*det(COV9(:,:,m))^(-1/2)*exp(-0.5*(D-Hopt(:,m))'*(COV9(:,:,m))^(-1)*(D-Hopt(:,m))); %            	
			L(m,1) = det(COV9(:,:,m))^(-1/2)*exp(-0.5*(D-Hopt(:,m))'*(COV9(:,:,m))^(-1)*(D-Hopt(:,m))); %            	
		end
		clear Dbar SIGi

	end
	clear D Dbar SIGi
	Lall(count,1:Nmodels) = L;
	[NS IX] = sort(L,'descend'); % Clear Nsample
	%IX_ALL(k,:) = IX;
	for m = 2:Nmodels % models
		%BFac(k,m-1) = L(IX(1))/L(IX(m));
		BFac(m-1,1) = L(IX(1))/L(IX(m));
	end
    minK = min(BFac);
    BFac(9,1) = 999;


    %% CALCULATED POSTERIOR MODEL PROBABILITY
    for m = 1:Nmodels
        %PMP(m,1) = L(m,1)/sum(L);
		PMP(m,1) = L(m,1)*Prior(m)/(L'*Prior);
    end
	PMP_all(count,1:Nmodels) = PMP;
    results = [BFac PMP*100];

	%clear L IX  
	minK = min(BFac);
	maxminEED_final = -minfit;
	dlmwrite(outfile1,'MaxMinEED | MinBF | All BFs | opt_pmp_loc | opt_obs_loc','-append','delimiter','');
	dlmwrite(outfile1,[maxminEED_final minK PMP' BFac' loc_opt_pmp loc_opt_obs],'-append','delimiter','\t');
	clear  SIGi_ SIG Dbar_ Ci_
	
	dlmwrite(outfile1,'--------------------------------------------------','-append','delimiter','');
	
	%clear H
	
	clear COV9
	%}
	
end % while

% Copy results and cleanup
system('rm -f save_outputs.py');
system('ln -s /home/ftsai/codes/save_outputs.py .');
system('python save_outputs.py');

% Cleanup run_x folder: See save_outputs.py
