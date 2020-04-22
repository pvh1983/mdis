#!/usr/bin/env octave

%% [2] RUN MODFLOW FOR TRUE MODEL GIVEN NEW PUMPING LOCATIONS
obs = load('pmploc1024.txt'); 
pmp = load('pmploc256.txt');
loc_opt_pmp = load('param.txt');
func_well(pmp(loc_opt_pmp,2:4)); % generate the new pmp package
load err1024 % Measurement errors
Hobs = NaN(512,1);
copyfile('mf54.wel','TrueGP2'); 
fprintf("\nCopied new mf54.well to TrueGP2.\n");
cd('TrueGP2'); % Change to each model's directory (GP1, GP2 ...)
fprintf("\nCurrent dir is: %s. \n", pwd);

% Run MODFLOW (max 320 par realizations)
Hobs = Ofunc; % Gen LPF pack. and run MODFLOW
cd ..
%save('Hobs1024points.mat','Hobs');  % in ASCII format
save -mat-binary Hobs1024points.mat Hobs

