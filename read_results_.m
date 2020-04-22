clc; clear; tic; clf; close all;

model_name = {'GP1','GP2','GP3','IK1','IK2','IK3','IZ1','IZ2','IZ3',};
lwidth = 1;
optplot0 = 1; 
optplot1 = 1; 
optplot2 = 1; 
optplot3 = 1;

fprintf(' ID Iter  Model Bestever    Best      \n');
for imodel = 1:9
   
	fpath = strcat('/work/ftsai/mcali/',model_name{1,imodel},'/');
	
	%%
	input_file = strcat(fpath,'variablescmaes.mat');
	load(input_file);
	RMSE_bestever(imodel,1) = bestever.f;

	if optplot0 == 1
		subplot(2,2,1);
		plot(fitness.histbest,':ob')
		title('variablescmaes.mat');
	end

	
	fprintf('%2d %4d %6s    %4.2f      %4.2f \n', imodel, countiter, model_name{1,imodel}, bestever.f, fitness.histbest(1));


	%% [1] Plot fitness =======================================================
	if optplot1 == 1
		%figure;
		subplot(2,2,2);
		input_file = strcat(fpath,'outcmaesfit.dat');
		data=dlmread(input_file,' ', 1, 0);  %Load file skip the first line
		iter = data(:,1);
		bestever = data(:,5);
		best = data(:,6);
		plot(iter,bestever,'r','LineWidth',lwidth); hold on;
		plot(iter,best,'b','LineWidth',lwidth); hold on;
		title('outcmaesfit.dat');
		legend('Bestever','Best');
		grid on;
	end

	%% [2] Plot xmean =========================================================
	if optplot2 == 1
		%figure;
		subplot(2,2,3);
		input_file = strcat(fpath,'outcmaesxmean.dat');
		data=dlmread(input_file,',', 1, 0);  %Load file skip the first line
		iter = data(:,1);
		xmean = data(:,6:11);
		plot(xmean);
		xlabel('Iterations');
		ylabel('X_Mean');
		title('outcmaesxmean.dat');
		grid on;
	end


	%% [4] Plot recent best====================================================
	if optplot3 == 1
		%figure;
		subplot(2,2,4);
		input_file = strcat(fpath,'outcmaesxrecentbest.dat');
		data=dlmread(input_file,',', 1, 0);  %Load file skip the first line
		iter = data(:,1);
		xmean = data(:,6:11);
		plot(xmean,'LineWidth',lwidth+2);
		xlabel('Interation');
		ylabel('XMean');
		legend('p1','p2','p3','p4','p5','p6');
		title('outcmaesxrecentbest.dat');
		grid on;
	end
	%%

end % model

%set(gcf, 'Position', [50, 100, 1600, 800])

toc