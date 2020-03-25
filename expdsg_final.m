% Ver 2.0 06162016 Load 5 potential sets of observation locations
%load head.mat 
obsloc = (load('parentobs.dat'));
Nobs = length(obsloc(1,:));

fitness = NaN(1,1);
fitness = func_EED(obsloc(1,:)); % Call func_EED to get EED

% Avoid -inf problem

if fitness ==-Inf || isnan(fitness)==1
	fitness = -9999;
end

% solve for max-max
#fitness=-fitness;


dlmwrite('fitness.dat',fitness,'delimiter','\t');

rr = NaN(1,Nobs+1);
rr = [reshape(obsloc,Nobs,1)' fitness];
dlmwrite('results.dat',rr,'precision', '%.4f','-append','delimiter','\t');
