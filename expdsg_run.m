% EXPERIMENTAL DESING USING 1 ADDITIONAL PUMPING WELLs
% Version 5.0 LAST UPDATED: 07142016
% Version 6.0 LAST UPDATED: 10/03/2019 (DEL SIGMA_i)
% Version 6.1: 03/16/2020 some minor edits
% - High pumping rate (-2000)
  
clc; clear all; close all; tic
delete('*.dat');

% Must read before submiting a job: 
nobsloc       = 1; % # of potential observation location
mea_err_added = 1; % 1: yes; 0: NO
corr_flag     = 1; % corr = 1; no_corr = 0;
%% Par in func_EED.m ? %%%
%% Comment pmpdsg if head.mat already available in each run %%%
%% getfitness.sh? %% OK
%% Prior OK? 

% initial parameter values
obs = load('pmploc1024.txt'); pmp = load('pmploc256.txt');
Nmodels = 9; rtime =  NaN(10,1);
Prior = [1.77E-01	1.90E-01	1.88E-01	1.71E-01	2.05E-01	6.94E-02	1.71E-13	4.26E-12	6.21E-10]';

% Run pmpdsg to get head.mat and use this file for obsdsg from 1 obs to 10 obs. 
pmpdsg % Call script pmpdsg.m to get head.mat
system('rm -r GP* IK* IZ*'); # Delete folders to save space
count = 1;
while nobsloc <= 5
	outfile1 = strcat('out',num2str(nobsloc),'.hai');
	%outfile2 = strcat('out',num2str(nobsloc),'_excel.hai');
	outfile3 = strcat('out',num2str(nobsloc),'.mat');
    
	delete('*.dat');
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
    system('./gaobs > outdspobs.dat');
	cmd_cpfile = strcat('cp -f results.dat', {' '}, 'results', num2str(nobsloc), '.dat')
	system(cmd_cpfile{:,:})
	
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

	
	%% [2] RUN MODFLOW FOR TRUE MODEL GIVEN NEW PUMPING LOCATIONS
	loc_opt_pmp = load('param.txt');
	func_well(pmp(loc_opt_pmp,2:4)); % generate the new pmp package
	load err1024 % Measurement errors
	Hobs = NaN(512,1);
	copyfile('mf54.wel','TrueGP2'); 
	cd('TrueGP2'); % Change to each model's directory (GP1, GP2 ...)
	% Run MODFLOW (max 320 par realizations)
	Hobs = Ofunc; % Gen LPF pack. and run MODFLOW
	cd ..
	%save('Hobs1024points.mat','Hobs');  % in ASCII format
	save -mat-binary Hobs1024points.mat Hobs


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


    %% CALCULATED POSTERIOR MODEL PROBABILITY
    for m = 1:Nmodels
        PMP(m,1) = L(m,1)/sum(L);
    end
	PMP_all(count,1:Nmodels) = PMP;
	
	%clear L IX  
	minK = min(BFac);
	maxminEED_final = -minfit;
	dlmwrite(outfile1,'MaxMinEED | MinBF | All BFs | opt_pmp_loc | opt_obs_loc','-append','delimiter','');
	dlmwrite(outfile1,[maxminEED_final minK PMP' BFac' loc_opt_pmp loc_opt_obs],'-append','delimiter','\t');
	clear  SIGi_ SIG Dbar_ Ci_
	
	dlmwrite(outfile1,'--------------------------------------------------','-append','delimiter','');
	rtime(nobsloc,1) = toc/3600;
%	clear H
	nobsloc = nobsloc + 1
	clear COV9
	count = count + 1;
	save -mat-binary data.mat
	movefile('data.mat',outfile3);
	
end % while
