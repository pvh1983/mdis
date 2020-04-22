
% EXPERIMENTAL DESING USING ONE ADDITIONAL PUMPING WELL
clc; clear all;
tic
%global H
%% [1] RUN MODFLOW GIVEN A NEW PUMPING LOCATION
md = ['GP1';'GP2';'GP3';'IK1';'IK2';'IK3';'IZ1';'IZ2';'IZ3']; 
Nobs = 512;
Nmodels = 9;
nmc = 320; % 32 for testing only, final is 320
all_pmp_loc = load('pmploc256.txt'); % All 1024 potential pumping locations (1024x3)
obs = load('pmploc1024.txt'); 
pmp = load('pmploc256.txt');
%id_pmp = load('param.txt'); % id of pmp locations, generated by 'getfitness.sh'
%id_pmp = [252	193]; % id of pmp locations, generated by 'getfitness.sh
id_pmp = [69 87]; % id of pmp locations, generated by 'getfitness.sh



Npmp = length(id_pmp);
for k = 1:Npmp
	pmploc(k,:) = all_pmp_loc(id_pmp(k),2:4); 
end
% pmploc: [L1 R1 C1; L2 R2 C2; ... ; L R C]

% GENERATE A NEW WELL PACKAGE
func_well(pmploc); % generate the new pmp package
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
	end           
	cd ..
	k
end % k

%% [2] FIND MIN(EED) GIVEN A PUMPING SCENARIO
disp('Done running MODFLOW. GA is starting ...');
toc

Prior = [1.77E-01	1.90E-01	1.88E-01	1.71E-01	2.05E-01	6.94E-02	1.71E-13	4.26E-12	6.21E-10]';


%% [2] RUN MODFLOW FOR TRUE MODEL GIVEN NEW PUMPING LOCATIONS
%func_well(pmp(loc_opt_pmp,2:4)); % generate the new pmp package
%load err1024 % Measurement errors
Hobs = NaN(Nobs,1);
copyfile('mf54.wel','TrueGP2');
cd('TrueGP2'); % Change to each model's directory (GP1, GP2 ...)
% Run MODFLOW (max 320 par realizations)
%Hobs(:,1) = Ofunc + err1024; % Gen LPF pack. and run MODFLOW
Hobs = Ofunc; % Gen LPF pack. and run MODFLOW
cd ..
save -mat-binary Hobs1024points.mat Hobs


Hopt_(:,:) = H(:,1,:); % Heads by MLE model parameters
%save 'head_252_193.mat' H Hopt_ Hobs Prior
save -mat-binary head.mat H Hopt_ Hobs Prior

