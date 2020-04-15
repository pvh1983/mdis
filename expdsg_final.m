#!/usr/bin/env octave
addpath('/home/ftsai/codes/')
% Ver 2.0 06162016 Load 5 potential sets of observation locations
% Ver 2.1 04052020 Make sure new obs are unique
%load head.mat 

source_dir = getenv('cur_dir');
%fprintf(fid_log, "source_dir=%s\n", source_dir);

obs = load(strcat(source_dir,'/pmploc1024.txt')); 
pmp = load(strcat(source_dir, '/pmploc256.txt'));

loc_opt_pmp = load('param.txt'); % cols: id, idpmp1, idpmp2, ..., idpmp_x
loc_opt_pmp(1) = []; % Delete the first row which is for ID

obsloc = (load('parentobs.dat')); % No. of potential obs locs

% check if a new obs well is at a pumping well location
flag = 0;
for i=1:length(loc_opt_pmp) % id of pmplocs
	pmp_cell_loc = pmp(loc_opt_pmp(i),2:4); % k,i,j of a pmp cell
	for j=1:length(obsloc) % id of new obs wells
		obs_cell_loc = obs(obsloc(j),2:4);
		loc_diff = sum(abs(obs_cell_loc - pmp_cell_loc));
		if loc_diff == 0 % obsloc is the same as pmploc
			flag = 1;
			break;
		end	
	end
end

opt_maxmin = str2num(getenv('opt_max_or_min'));

Nobs = length(obsloc(1,:));
obsloc_unique = unique(obsloc);
% Check and skip if found a same obs id

if opt_maxmin==1 % maxmin
	if length(obsloc_unique) == Nobs && flag~=1
		fitness = NaN(1,1);
		fitness = func_EED(obsloc(1,:)); % Call func_EED to get EED
		% Avoid -inf problem	
		if fitness ==-Inf || isnan(fitness)==1
			fitness = -9999; % assign a much smaller
		end
	else
		fitness = -9999; % assign a much smaller
	end
elseif opt_maxmin==-1 % maxmax
	if length(obsloc_unique) == Nobs && flag~=1
		fitness = NaN(1,1);
		fitness = func_EED(obsloc(1,:)); % Call func_EED to get EED
		% find max-max
			
		% Avoid -inf problem	
		if fitness ==-Inf || isnan(fitness)==1
			fitness = -9999; % assign a much smaller
		else
			fitness = -fitness; % example 0.78, 0.92, 1.12
		end
	else % new loc is at pmploc or dupplicated
		fitness = -9999; % assign a much smaller
	end
end
	



% solve for max-max



dlmwrite('fitness.dat',fitness,'delimiter','\t');

rr = NaN(1,Nobs+1);
rr = [reshape(obsloc,Nobs,1)' fitness];
dlmwrite('results.dat',rr,'-append'); %'precision', '%5.4f', 'delimiter','\t'
