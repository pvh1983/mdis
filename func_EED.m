function EED_KPN = func_EED(obsid)
% Version 5.0 07142016: Fix m. error covariance matrix in I2
% Version 6.0 LAST UPDATED: 10/03/2019 (DEL SIGMA_i)
% Version 6.1: Printer out Dnew to file
addpath('/home/ftsai/codes/')
%clc; clear all; 
tic
load head.mat
load('../err1024.mat')
%for obsid = 1:1024


% Must read before submiting a job: 
corr_flag     = 1; % corr = 1; no_corr = 0;
%mea_err_added = 1; % 1: yes; 0: NO
%% ALSO file expdsg_run.m to make sure they are the same %%%


% Run options
runopt.KPN = 1; % run_mc = 1: run; other no run.
%runopt.MC = 1; acc.MC  = 2^10; % number of MC samples
acc.KPN = 5; % KPN
Hopt_(:,:) = H(:,1,:); % Heads by MLE model parameters
Prior = [0.177	0.190	0.188	0.171	0.205	0.069	1.71E-13	4.26E-12	6.21E-10]';

Nmodels = 9;
Nobs = length(obsid);
Hopt = Hopt_(obsid,:); clear Hopt_ % Nobs x Nmodels

% CALCULATE COVARIANCE MATRIX
% Within-model covariance as follows:
for m = 1:Nmodels % Under model i
    %Htmp(:,:) = H(obsid,:,m)-repmat(H(obsid,1,m)+err1024(obsid,1),[1 320]); 
    Htmp(:,:) = H(obsid,:,m);
    SIGi9(:,:,m) = cov(Htmp')*Prior(m,1); % Covariance matrix under model Mi
end 
clear Htmp 
WMCV = sum(SIGi9,3);

% The between-model covariance as follows:
HBMA = Hopt*Prior
for m = 1:9
    Hdiff = Hopt(:,m) - HBMA;
    SH(:,:,m) = (Hdiff*Hdiff')*Prior(m,1); % FULL COV. MATRIX
end
BMCV = sum(SH,3); clear SH

SIG = BMCV + WMCV; % Total model covariance by BMA Nobs x Nobs
clear BMCV WMCV
 
SIG_err = eye(Nobs,Nobs);
SIG_err(logical(eye(size(SIG_err)))) = err1024(obsid).^2; % Dig terms only

%for m = 1:9
%COV9(:,:) = (SIG + SIG_err + SIGi9(:,:,m))/10; % FINAL after discusion 071416
COV9(:,:) = (SIG + SIG_err); % After dis 071416, one matrix for all 9 models
det_COV9 = det(COV9(:,:));
[L,pp] = chol(COV9(:,:),'lower'); % Cholesky decompotition: r = Lz where L satisfies LL' = C.
LL(:,:) = L;
%dA(m,1) = prod(diag(L));
% dependent variables with Cov SIGMA = L* independent
%Dmean(:,m) = inv(L)*Hopt(:,m); % Dmean is A_bar in notebook (Cholesky transformation)
%Dmean(:,m) = L\Hopt(:,m); % Dmean is A_bar in notebook (Cholesky transformation)
% Calculate I1 (Same for all methods)
if corr_flag == 1 % WITH CORRELATION
    I1 = log((2*pi)^(-Nobs/2)*(det(COV9(:,:)))^(-0.5)); % Same for all methods
else  % NO CORRELATION
    COVM = zeros(Nobs,Nobs); 
    COVM(logical(eye(size(COVM)))) = diag(COV9(:,:));           
    I1 = log((2*pi)^(-Nobs/2)*(det(COVM))^(-0.5));
end
%end
clear SIG SIGi9 i j k m 
%Hopt(:,1)
%% [2] Method 1: Univariate nested quadrature rules as basis
if runopt.KPN == 1
%    clear D miu
    [z w] = nwspgr('KPN', Nobs, acc.KPN);
    NKPpoints = length(z);
    for k = 1:NKPpoints % k is i in the MS.
        if corr_flag == 1 % with correlation
            % Old version for Dnew
            %Dnew =   [Hopt(:,m)+LL(:,:)*z(k,:)'];  % NO CORRELATION 2x1 if 2 obs (samples of future data) 
            % new version for Dnew 04-17-2020, sample from HBMA and COV9
            Dnew(k,:) =   [HBMA + LL(:,:)*z(k,:)'];  % NO CORRELATION 2x1 if 2 obs (samples of future data) 
        else % No correlation
            %Dnew =   [Hopt(:,m)+z(k,:)'.*sqrt(diag(COV9(:,:)))];  % NO CORRELATION 2x1 if 2 obs (samples of future data)            
            %qi(k,1) = ftest(Nobs,Dnew,Hopt,COV9,Prior,corr_flag); % 10x1 Call function, using PDF pi            
        end
    end % k

    

    % Write Dnew to file
    ofile_dnew = strcat('Dnew_nobs_',num2str(Nobs),'.csv' );
    dlmwrite(ofile_dnew,Dnew','-append','delimiter',',','precision','%.3f'); 
    
    for m = 1:9
        [qi, LH]= ftest(Nobs,Dnew,Hopt,COV9,Prior,corr_flag); % 10x1 Call function, using PDF pi                
        %size(w)
        
        % Calculate I2
        if corr_flag == 0
            %I2(m,1) = (qi'*w); clear qi
        elseif corr_flag == 1
            %I2(m,1) = (qi'*w)*dA(m,1)*det_COV9(m,1)^(-0.5); clear qi
            I2(m,1) = (qi'*w);
            clear qi
        end
        % Record qi to check the result:
        %qi_all(:,m) = qi;clear qi
        
    end % m
    clear Dnew

    LH_all = LH'*w;

    EED_KPN = (I1-Nobs/2-I2)'*Prior; % I2 is E[log(q)]

    ofile_LH = strcat('LH',num2str(Nobs),'.csv' );
    dlmwrite(ofile_LH,LH_all','-append','delimiter',',','precision','%4.3e'); 


    func_run_time = toc;
    %out = [obsid EED_KPN func_run_time];
    %out = [obsid EED_KPN];
    %dlmwrite('EED_KPN.txt',out,'-append')
     if EED_KPN < 0
         EED_KPN = -999;
     else
         EED_KPN = -(I1-Nobs/2-I2)'*Prior;
     end
    clear i j  k NKPpoints
    clear I2 z  COVM w m   
end
clear L dA det_COV9 pp

%{
%% [3] Method 2: CALCULATE INTERGRAL I2 using the Monte Carlo method
if runopt.MC == 1
    for m = 1:Nmodels              
        % Calculate I1
        if corr_flag == 1 % With correlation           
            Dnew = mvnrnd(Hopt(:,m),COV9(:,:),acc.MC); % Measurement values (yn)
            %I1(m,1) = log((2*pi)^(-Nobs/2)*(det(COV9(:,:)))^(-0.5)); % CORRECT? YES 050316
        else % No correlation            
            %Dnew = mvnrnd(Hopt(:,m),COVM,acc.MC); 
            %COVM = zeros(Nobs,Nobs); 
            %COVM(logical(eye(size(COVM)))) = diag(COV9(:,:)); % No correlation                       
            %I1(m,1) = log((2*pi)^(-Nobs/2)*(det(COVM))^(-0.5));
        end

        % Calculate I2
        for k = 1:acc.MC
            I2_tmp(k,1)   = ftestMC(Nobs,Dnew(k,:)',Hopt,COV9,Prior,corr_flag);
        end          
        id = find(I2_tmp > -inf);
        I2(m,1) = mean(I2_tmp(id)); % Final                
    end % Nmodels
    EED_MC = -(I1 - I2 - Nobs/2)'*Prior;
    clear I2_tmp  k id m
    clear I1 I2 Dnew
%end
%}
%disp('EED_KPN    EED_MC');
%EED_all(obsid,:) = [EED_KPN EED_MC]; 

%end
%toc

