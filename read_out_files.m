clc; clear all; tic
cal_BF = 1; % 
max_nobs = 5;
npmp = 256;
data1 = NaN(max_nobs,npmp);

for iobs=1:max_nobs
    fout=strcat('out',num2str(iobs),'.mat');
    for kk = 1:256
        fname1=strcat('run_',num2str(kk));
        cd(fname1)
        if exist(fout) == 2
			load(fout); 
			data1(iobs,kk) = -minfit;
			cd ..
		else
			data1(iobs,kk) = 999;
			cd ..
		end
        
    end
end % obs

EED = data1'; 
for k = 1:max_nobs
    id_tmp = find(EED(:,k)<999);
    MaxEED(k,1) = max(EED(id_tmp,k));
end
id_best_pmp_loc = NaN(max_nobs,20);
for k=1:max_nobs
    EED_tmp = EED(:,k);
    id_best_pmp_loc_tmp = find(EED_tmp==MaxEED(k,1));
    id_best_pmp_loc(k,1:length(id_best_pmp_loc_tmp)) = id_best_pmp_loc_tmp;
    clear EED_tmp id_best_pmp_loc_tmp
end
save data_all.mat
save data_tmp.mat id_best_pmp_loc max_nobs
dlmwrite('EED_all.dat',EED);


%% CALCULATE BAYES FACTORS
if cal_BF == 1
    clear all; 
    delete('*.hai');
    load data_tmp
    % Load *.mat file that have MaxMinEED
    %outfile1 = strcat('out',num2str(k),'.hai');
    outfile_final ='out_all.hai';
    dlmwrite(outfile_final,'MaxMinEED | MinBF | All BFs | opt_pmp_loc | opt_obs_loc','-append','delimiter','');
    for k=1:max_nobs
        fout=strcat('out',num2str(k),'.mat');
        fname1=strcat('run_',num2str(id_best_pmp_loc(k,1)));

        cd(fname1)
        load(fout); 
        %
        cd ..

        dlmwrite(outfile_final,[-minfit min(BFac) BFac' loc_opt_pmp loc_opt_obs],'-append','delimiter','\t');
    end
end

save -mat-binary out_all_data.mat

save out_all.mat
toc
