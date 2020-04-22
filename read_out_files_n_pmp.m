clc; clear all; tic
delete('out_all.hai');
cal_BF = 1; % 
max_nobs = 7;
npmp = 256;
%data2 = NaN(max_nobs,npmp);

for iobs=1:max_nobs
    fout=strcat('out',num2str(iobs),'.mat');    
    load(fout); 
    data1 = [maxminEED_final min(BFac) BFac' loc_opt_pmp loc_opt_obs];
    data2(iobs,1:length(data1)) = data1; 
end % obs
outfile_final ='out_all.hai';
dlmwrite(outfile_final,'MaxMinEED | MinBF | All BFs | opt_pmp_loc | opt_obs_loc','-append','delimiter','');
dlmwrite(outfile_final,data2,'-append','delimiter','\t');
save out_all.mat

toc