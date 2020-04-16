function lnq = ftest(Nobs,D,Hopt,COV9,Prior,corr_flag)
% Version 5.0 071416
if corr_flag == 0 % No Correlation   
    for m = 1:9 % models
        COVM = zeros(Nobs,Nobs); 
        COVM(logical(eye(size(COVM)))) = diag(COV9(:,:,m)); % Dig terms only
        XX(m,1) = -0.5*(D-Hopt(:,m))'*COVM^(-1)*(D-Hopt(:,m));
        LH(m,1) = ((2*pi)^(-Nobs/2))*(det(COVM))^(-1/2)*exp(XX(m,1))*Prior(m,1);
    end  
    lnq = log(sum(LH)); % 1x9 x 9x1
else % with correlation BK            
    for m = 1:9    
        XX(m,1) = -0.5*(D-Hopt(:,m))'*COV9(:,:,m)^(-1)*(D-Hopt(:,m));
        LH(m,1) = ((2*pi)^(-Nobs/2))*(det(COV9(:,:,m)))^(-1/2)*exp(XX(m,1))*Prior(m,1);
    end          
    lnq = log(sum(LH)); % 1x9 x 9x1   
end

