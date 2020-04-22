clc; clear ; close all; tic

% Calculate all pmp given a pumping location(s)
% Last visit: December 24, 2019.

Nmodels = 9;
load Hobs1024points.mat % Load Hobs
load head.mat           % load head MC

ofile = 'output_diff_obslocs.tom';
fid = fopen(ofile,'w');
fprintf(fid, "Curr dir: %s \n", pwd); fprintf(fid,"\n"); fprintf(fid,"\n");

#C = load('enu2_512.dat');
C = [1:1:512]';
err1024 = load('out_512_err.csv');

%% MAKE SURE YOU CHANGE THESE PARAMETERS:
runopt = 4; % Consider m. err or not: [1] with m. err; [0]: no m.err
Dopt   = 1; % Optionf of choosing future observation data: 1: real obs; 0: BMA
mea_err_added = 0; % [1]: yes; [0]: NO
corr_flag     = 1; % corr = 1; no_corr = 0;
%Hopt_9models(:,:) = H(:,1,:); % Heads by MLE model parameters

Prior = [1.77E-01	1.90E-01	1.88E-01	1.71E-01	2.05E-01	6.94E-02	1.71E-13	4.26E-12	6.21E-10]';
nruns = length(C(:,1)); % length(C(:,1))
for kk = 1:nruns  
    obsid = C(kk,:);
    Nobs = length(obsid);
    fprintf(fid, "run %d \n", kk);  fprintf(fid,"\n"); 

    %% 
    #Dtmp(1:Nobs,1:9) = H(obsid,1,:); % Hopt
    if mea_err_added == 1
        D = Hobs(obsid,1)+err1024(obsid,1);     % Use real observation data + err. For confirmation!!! after design
    else
        D = Hobs(obsid,1);     % Use real observation data 
    end
    %Hopt(:,:) = H(obsid,1,:); % At a design location
  
    Hopt_(:,:) = H(:,1,:); % Heads by MLE model parameters
    Hopt = Hopt_(obsid,:); %clear Hopt_;

    fprintf(fid, "obsloc: \n");
    fprintf(fid, '%d, ', obsid); fprintf(fid,"\n");

    fprintf(fid, "Hobs is: \n");
    fprintf(fid, '%6.2f, ', Hobs(obsid,1)); fprintf(fid,"\n");
    
    fprintf(fid, "Hopt are: \n");
    fprintf(fid, '%6.2f, ', Hopt); fprintf(fid,"\n");

    % CALCULATE COVARIANCE MATRIX
    % Within-model covariance as follows:
    for m = 1:Nmodels % Under model i
        Htmp(:,:) = H(obsid,:,m); % Errors of estimated heads 
        SIGi9(:,:,m) = cov(Htmp')*Prior(m,1); % Covariance matrix under model Mi
    end 
    clear Htmp 
    WMCV = sum(SIGi9,3);

    for m = 1:Nmodels
        Hdiff = Hopt(:,m) - Hobs(obsid,1)-err1024(obsid,1);
        SH(:,:,m) = (Hdiff*Hdiff')*Prior(m,1); % FULL COV. MATRIX
        %SH(:,:,m) = diag(Hdiff*Hdiff');
    end
    BMCV = sum(SH,3); clear SH

    #SIG = BMCV + WMCV; % Total model covariance by BMA Nobs x Nobs
    SIG = BMCV + WMCV; % Total model covariance by BMA Nobs x Nobs
    SIG_err = eye(Nobs,Nobs);
    SIG_err(logical(eye(size(SIG_err)))) = err1024(obsid).^2; % Dig terms only

    for m = 1:Nmodels
        COV9(:,:,m) = SIG + SIG_err;
    end

    fprintf(fid, "SIGi9 is: \n");
    fprintf(fid, '%6.3e, ', SIGi9); fprintf(fid,"\n");
    fprintf(fid, "SIG_err is: \n");
    fprintf(fid, '%6.3e, ', SIG_err); fprintf(fid,"\n");
    fprintf(fid, "BMCV is: \n");
    fprintf(fid, '%6.3e, ', BMCV); fprintf(fid,"\n");
    fprintf(fid, "WMCV is: \n");
    fprintf(fid, '%6.3e, ', WMCV); fprintf(fid,"\n");
    #clear Dtmp
    %% CALCULATE LIKELIHOOD:
    for m = 1:Nmodels % models       	
        %L(m,1) = det(SIG_err+SIGi9(:,:,m))^(-1/2)*exp(-0.5*(D-Hopt(:,m))'*(SIG_err+SIGi9(:,:,m))^(-1)*(D-Hopt(:,m))); %            	
        L(m,1) = det(COV9(:,:,m))^(-1/2)*exp(-0.5*(D-Hopt(:,m))'*(COV9(:,:,m))^(-1)*(D-Hopt(:,m))); %            	
    end

    %% CALCULATED POSTERIOR MODEL PROBABILITY
    for m = 1:m
        #PMP(m,1) = L(m,1)/sum(L);
        PMP(m,1) = L(m,1)*Prior(m)/(L'*Prior);
    end

    %%
    clear D Dbar SIGi
    [NS IX] = sort(L,'descend'); % Clear Nsample
    for m = 2:Nmodels % models
        BFac(m-1,1) = L(IX(1))/L(IX(m));
    end

    minK = min(BFac);
    BFac(9,1) = 999;
    results = [BFac PMP];

    fprintf(fid, "L(m,1) is: \n");
    fprintf(fid, '%5.2e, ', L); fprintf(fid,"\n");
    
    fprintf(fid, "Prior Model Probability is: \n");
    fprintf(fid, "%6.2f, ", Prior*100); fprintf(fid,"\n");

    fprintf(fid, "Posterior Model Probability is: \n");
    fprintf(fid, "%6.2f, ", PMP*100); fprintf(fid,"\n");

    fprintf(fid, "BFactor is: \n");
    fprintf(fid, "%6.2f, ", BFac); fprintf(fid,"\n");

    fprintf(fid, "Min BFac = %4.1f \n", minK); fprintf(fid,"\n");  fprintf(fid,"\n");

    
    all_minBF(kk,:) = BFac;
    all_PMP(kk,:) = PMP;

dlmwrite('all_min_PMP.tom',all_PMP,'delimiter','\t');
dlmwrite('all_min_BFac.tom',all_minBF,'delimiter','\t');
end % obsid
%Hopt_all = Hopt_*Prior;
%Hobs_err = Hobs + err1024;
save best2pmp5obs_all_PMP_real_obs.mat


out = [Hobs err1024 Hobs+err1024];
%%
id1 = find(all_minBF(:,1) > 500);
out2 = [all_minBF(id1,1) all_PMP(id1,:)];

min_EED = min(all_minBF(:,1));

id2 = find(all_minBF(:,1) < 500);
max_EED = max(all_minBF(id2,1));
%%

%save all_var_minBF.mat all_minBF all_var Hobs_all Hopt_all

%% FIND PMP = 1
for k = 1:nruns
    id_max_Pr(k,1) = find(all_PMP(k,:)==max(all_PMP(k,:)));
end

%%
for kk = 1:9
    count2(kk,1) = length(find(id_max_Pr==kk));
end
pid2 = count2./length(C(:,1))*100;

%%
% for k = 1:9
%     id_pmp(k,1) = length(find(all_PMP(:,k)>0.5));
% end
%hist(id_max_Pr);figure(gcf);
fig1 = bar(count2);
ylabel('Freq.');
xlabel('Groundwater model');
grid on;
%save best1pmp2obs_all_PMP523776
%bar(id_pmp,'DisplayName','id_pmp');figure(gcf)
saveas(fig1, 'freq_best_model2.png');


fclose(fid);
fprintf("The results were saved at %s \n", ofile)


toc







