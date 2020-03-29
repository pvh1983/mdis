tic
R = load('MinEED.dat'); R = -R;
[NS IX] = sort(R,'descend'); 
R_sorted = R(IX);

loc = load('pmploc1024.txt');
OUT = [[1:1:length(R)]' R loc(IX,:) R_sorted];
dlmwrite('R.dat','No.       EED           IX        EED_SORTED   Layer Row Column ','delimiter','\t');
dlmwrite('R.dat',OUT,'delimiter','\t');

toc