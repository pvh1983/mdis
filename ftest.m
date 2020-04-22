function [lnq, LH]= ftest(Nobs,Dnew,Hopt,COV9,Prior,corr_flag)
% Version 5.0 071416
for k = 1:length(Dnew(:,1))        
    if corr_flag == 0 % No Correlation   
        for m = 1:9 % models
            COVM = zeros(Nobs,Nobs); 
            COVM(logical(eye(size(COVM)))) = diag(COV9(:,:)); % Dig terms only
            XX = -0.5*(Dnew(k,:)'-Hopt(:,m))'*COVM^(-1)*(Dnew(k,:)'-Hopt(:,m));
            LH(k,m) = ((2*pi)^(-Nobs/2))*(det(COVM))^(-1/2)*exp(XX)*Prior(m,1);
        end  
        lnq(k,1) = log(sum(LH(k,:))); % 1x9 x 9x1
    else % with correlation BK            
        for m = 1:9    
            XX = -0.5*(Dnew(k,:)'-Hopt(:,m))'*COV9(:,:)^(-1)*(Dnew(k,:)'-Hopt(:,m));
            LH(k,m) = ((2*pi)^(-Nobs/2))*(det(COV9(:,:)))^(-1/2)*exp(XX)*Prior(m,1);
        end          
        lnq(k,1) = log(sum(LH(k,:))); % 1x9 x 9x1   
    end
end % k
