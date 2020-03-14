function H = Ofunc
fprintf("\nRunning MODFLOW using Ofunc.m ...")
%[4] Run MODFLOW
system('./mf2005 mf54.nam > omf.txt'); % Run MODFLOW UNIX
%system('mf2005 mf54.nam > omf.txt'); % Run MODFLOW WINDOWS
Nobs = 512;
chk = exist('mf54._os'); % = 2 exist file.
if chk == 2 &&  getfilesize('mf54._os') > 0
    % Read head from ._os
	fprintf("Susscessfuly run MODFLOW. Reading *._os ...")
	fid = fopen('mf54._os');
	C1 = fscanf(fid,'%s %s %s %s %s %s',[1 6]);
	C = fscanf(fid,'%g %g %1s %*s',[3 inf]);
	C = C';
	%obs = C(:,2); 
	cal = C(:,1); n_ = C(:,3);
	fclose(fid);
	k = 1;
	for i = 1:length(cal)
		tmp = char(n_(i));
		if tmp == 'h'
			%obs1(k,1) = obs(i);
			cal1(k,1) = cal(i);
			k = k + 1;
		end
	end
	H = cal1;
else
    H = NaN(Nobs,1);
	fprintf("WARNING. No mf54._os found. FAILED to run MODFLOW")
end
