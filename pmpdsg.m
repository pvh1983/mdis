#!/usr/bin/env octave

% EXPERIMENTAL DESING USING ONE ADDITIONAL PUMPING WELL
% Updated: March 2020
% - Add pmprate to func_well.m


%clc; clear all;
tic
%global H
%% [1] RUN MODFLOW GIVEN A NEW PUMPING LOCATION
md = ['GP1';'GP2';'GP3';'IK1';'IK2';'IK3';'IZ1';'IZ2';'IZ3']; 
Nobs = 512;
Nmodels = 9;
nmc = 320; % 32 for testing only, final is 320
pmprate = -1000;
all_pmp_loc = load('pmploc256.txt'); % All 1024 potential pumping locations (1024x3)
id_pmp = load('param.txt'); % id of pmp locations, generated by 'getfitness.sh'
id_pmp(1) = []; % Delete the first row which is for ID
Npmp = length(id_pmp);
for k = 1:Npmp
	pmploc(k,:) = all_pmp_loc(id_pmp(k),2:4); 
end
% pmploc: [L1 R1 C1; L2 R2 C2; ... ; L R C]

% GENERATE A NEW WELL PACKAGE
func_well(pmploc,pmprate); % generate the new pmp package
%load err1024 % Measurement errors, dif. at 1024 locs, but same in 320 mc.

H = NaN(Nobs,nmc,Nmodels);
for k = 1:Nmodels % 9 models
	fname = md(k,:);           
	copyfile('mf54.wel',fname); 
	cd(fname); % Change to each model's directory (GP1, GP2 ...)
	% Run MODFLOW (max 320 par realizations)
	par = load('input.txt');
	for r = 1:nmc		
		H(:,r,k) = Ofunc(par(r,:),Nobs); % Gen LPF pack. and run MODFLOW
%		H(:,r,k) = Case01(par(r,:),Nobs) + err1024; % Gen LPF pack. and run MODFLOW
%		if exist('mf54._os') == 2
%			out_os = strcat('run_',num2str(r),'._os');
%			movefile('mf54._os',out_os);
%		end 
%		if exist('mf54.hed') == 2 && getfilesize('mf54.hed') > 0                   
%			out_hed = strcat('run_',num2str(r),'.hed');                    
%			movefile('mf54.hed',out_hed);
%		end
		mf_model_run_time = toc;
		out = [k r mf_model_run_time];
		dlmwrite('mf_run_time.txt', out,'-append');
	end           
	cd ..
	k
end % k
%save('head.mat',H);
save -mat7-binary 'head.mat' 'H';


%% [2] FIND MIN(EED) GIVEN A PUMPING SCENARIO
disp('Done running MODFLOW. GA is starting ...');
toc
% USING MICRO GENETIC ALGORITHM 
%system('./gaobs > outdspobs.dat'); % call ga finding obs locs


%{
% delete('fitness');
% load heads_tmp_L5_9_11.mat
% disp('Done loading data')
obsloc = (load('parent.dat'));
for k = 1:length(obsloc(:,1))
	fitness(k,1) = func_EED(obsloc(k,:));
%	toc/60
end
%dlmwrite('fitness.dat',fitness,'-append','delimiter','\t');
best_ever = max(fitness);
dlmwrite('fitness.dat',fitness,'delimiter','\t');
rr = [reshape(obsloc,10,1)' fitness' best_ever];
dlmwrite('results.dat',rr,'-append','delimiter','\t');
toc/60;
%}
