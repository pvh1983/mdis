function func_well(wloc, pmprate)
% Version 2.0
% wloc Npmp x 3 (3 columns is L R C)
% Print new pmp file - yearly (15)
# - Add pmprate to func_well.m
Total_Npmp = length(wloc(:,1)) + 3; % 2 is the number of existing pumping wells
f3 = 'mf54.wel';
fid1 = fopen(f3,'w');
fprintf(fid1,'%3d %39s\n',Total_Npmp,'740 AUX IFACE AUX QFACT AUX CELLGRP');  % 2 wells
fprintf(fid1,'%3d %25s\n',Total_Npmp,'         0         0');                 % 2 wells
fprintf(fid1,'%3i %3i %3i %9.2f %2i %2i %2i \n', 5, 11, 21, -200,0,1,1); % existing pmp1
fprintf(fid1,'%3i %3i %3i %9.2f %2i %2i %2i \n', 1,  5, 17, -100,0,1,2); % existing pmp2
fprintf(fid1,'%3i %3i %3i %9.2f %2i %2i %2i \n', 3, 11,  5,   25,0,1,3);   % existing injection1
for k = 1:length(wloc(:,1))
	fprintf(fid1,'%3i %3i %3i %9.2f %2i %2i %2i \n',wloc(k,1),wloc(k,2),wloc(k,3),pmprate,0,1,3+k);
end
fclose(fid1);
