#!/usr/bin/env octave

% EXPERIMENTAL DESING USING 1 ADDITIONAL PUMPING WELLs
% Version 5.0 LAST UPDATED: 07142016
% Version 6.0 LAST UPDATED: 10/03/2019 (DEL SIGMA_i)
% Version 6.1: 03/16/2020 some minor edits
% - High pumping rate (-1000)
% 03/20/2020: Add copy files and cleanup
% ATTENTION: All *.dat will be deleted!!!
  
clc; clear all; close all; tic
addpath('/home/ftsai/codes/')

fid_log = fopen('runlog.txt','a');
cdatetime = datestr(now, 'dd-mmm-yyyy HH:MM:SS');

fprintf(fid_log, "\n\nStart time: %s\n", cdatetime);

source_dir = getenv('cur_dir')
%fprintf(fid_log, "source_dir=%s\n", source_dir);

run_dir = pwd;
cd(run_dir);
fprintf(fid_log, "%s\n", pwd);

% Delete old files
delete('*.dat');
%delete('Dnew_nobs_*.csv');
%delete('func_runtime.txt')
delete('gaobs.inp')
delete('ga.out')


% Must read before submiting a job: 
%nobsloc       = 2; % % of potential observation location
nobsloc = int8(str2num(getenv('nobs_loc')));
max_nobsloc = int8(str2num(getenv('max_nobs_loc')));

fprintf(fid_log, "nobsloc= %d\n", nobsloc);
fprintf(fid_log, "max_nobsloc= %d\n", max_nobsloc);

%mea_err_added = 1; % 1: yes; 0: NO
%corr_flag     = 1; % corr = 1; no_corr = 0;
pmprate = int8(str2num(getenv('pmprate')));
%pmprate = -1000;

%% Par in func_EED.m ? %%%
%% Comment pmpdsg if head.mat already available in each run %%%
%% getfitness.sh? %% OK
%% Prior OK? 

% initial parameter values
obs = load(strcat(source_dir,'/pmploc1024.txt')); 
pmp = load(strcat(source_dir, '/pmploc256.txt'));

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
	%outfile1 = strcat('out',num2str(nobsloc),'.hai');
	%outfile2 = strcat('out',num2str(nobsloc),'_excel.hai');
	outfile3 = strcat('out',num2str(nobsloc),'.mat');
    
	delete('*.dat');
	%dlmwrite(outfile1,'WARNING: Deleted all *.dat files.','-append','delimiter','');

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
    system('cat ../gaobs1.inp gaobs2.inp ../gaobs3.inp gaobs4.inp > gaobs.inp');
    delete('gaobs2.inp'); delete('gaobs4.inp');
    
	% Run experimental design using xxx pmp wells and nobsloc =================
	cmd_cpfile = strcat('bk_results_', num2str(nobsloc), '.tom');
	%ofile_mat = strcat('out',num2str(nobsloc),'.mat'); % make sure done running
	%ofile_mat = strcat('out',num2str(nobsloc),'.mat'); % make sure done running
	chk2 = exist(cmd_cpfile); % = 2 exist file.
	if chk2 ~= 2
		system('rm -f expdsg_final.m ga.restart')
		system('ln -s /home/ftsai/codes/expdsg_final.m .')
		system('cp -f /home/ftsai/codes/ga.restart .')
		system('ln -s /home/ftsai/codes/gaobs .')
		system('./gaobs > outdspobs.dat');
		%system('gaobs > outdspobs.dat');
		fprintf("\nRun gaobs at nobs = %d\n", count);
	else
		fprintf("\nWARNING: Did not run gaobs at nobs = %d\n", count);
	end
    delete('gaobs.inp');
	%dlmwrite(outfile1,'DONE running gaobs.','-append','delimiter','');
 
	
	%system(cmd_cpfile{:,:})
	
	
	%% [2] RUN MODFLOW FOR TRUE MODEL GIVEN NEW PUMPING LOCATIONS
	loc_opt_pmp = load('param.txt');
	loc_opt_pmp(1) = []; % Delete the first row which is for ID

	chk2 = exist('Hobs1024points.mat'); % = 2 exist file.
	if chk2 ~= 2
		func_well(pmp(loc_opt_pmp,2:4), pmprate); % generate the new pmp package
		load('../err1024.mat') % Measurement errors
		Hobs = NaN(512,1);
		copyfile('mf54.wel','TrueGP2'); 
		cd('TrueGP2'); % Change to each model's directory (GP1, GP2 ...)	
		% Run MODFLOW (max 320 par realizations)
		Hobs = Ofunc; % Gen LPF pack. and run MODFLOW
		cd ..
		%dlmwrite(outfile1,'DONE running TrueGP2 with new pmploc.','-append','delimiter','');
		%save('Hobs1024points.mat','Hobs');  % in ASCII format
		save -mat-binary Hobs1024points.mat Hobs
	end
 
	%dlmwrite(outfile1,'The pumping locations:','-append','delimiter','');
	%dlmwrite(outfile1,[loc_opt_pmp],'-append','delimiter','\t');
	%dlmwrite(outfile1,'Saved Hobs at Hobs1024points.mat.','-append','delimiter','');

	count = count + 1;
	chk = exist('results.dat'); % = 2 exist file.
	if chk == 2
		movefile('results.dat',cmd_cpfile);
	end
	
	rtime(nobsloc,1) = toc/3600;
	clear chk chk2 	
	%save -mat-binary data.mat
	%movefile('data.mat',outfile3);	
	%dlmwrite(outfile1,'Total run time for expdsg_run.m is:','-append','delimiter','');
	%dlmwrite(outfile1,[rtime],'-append','delimiter','\t');
	fprintf(fid_log, "Nobs = %d, run time = %4.3f (hours)\n", nobsloc, toc/3600);
	cdatetime = datestr(now, 'dd-mmm-yyyy HH:MM:SS');
	fprintf(fid_log, "End time: %s\n", cdatetime);	
	nobsloc = nobsloc + 1	
end % while
fclose(fid_log);

% Copy results and cleanup
%{
system('rm -f save_outputs.py');
system('ln -s /home/ftsai/codes/save_outputs.py .');
system('python save_outputs.py');
%}

% Cleanup run_x folder: See save_outputs.py
