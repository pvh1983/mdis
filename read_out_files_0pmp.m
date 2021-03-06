clc; 
clear
clf; tic
system('rm -f *.hai');
cal_BF = 1; % 
max_nobs = 5;
opt_opt_type = 'MaxMin'; # MaxMin or MaxMax

data2 = NaN(max_nobs,10);

for iobs=1:max_nobs
    fout=strcat('out',num2str(iobs),'.mat');    
    load(fout); 
    #data1 = [-minfit min(BFac) BFac' loc_opt_pmp loc_opt_obs];
    data1 = [maxminEED_final min(BFac) PMP' BFac' loc_opt_pmp loc_opt_obs];
    data2(iobs,1:length(data1)) = data1; 

    IG = data2(:,1)
    out_IG(iobs,1:3) = [min(IG), max(IG), std(IG)]

    outfile_final =strcat('out_all_', num2str(iobs),'obs_wells.hai');

    tl1 = strcat(opt_opt_type, ' I_G: ')
    dlmwrite(outfile_final,tl1, 'delimiter','')
    dlmwrite(outfile_final,out_IG(iobs,1:3),'-append')
    dlmwrite(outfile_final,'','-append')
    dlmwrite(outfile_final,'MaxMinEED,MinBF,p1,p2,p3,p4,p5,p6,p7,p8,p9,bf1,bf2,bf3,bf4,bf5,bf6,bf7,bf8,opt_pmp_loc, opt_obs_loc','-append','delimiter','');
    dlmwrite(outfile_final,data2,'-append','delimiter',',');

end % obs
# 
outfile_final = 'all_IG.hai'
dlmwrite(outfile_final,'min, max, std','delimiter','')
dlmwrite(outfile_final,out_IG,'-append','delimiter',',')
