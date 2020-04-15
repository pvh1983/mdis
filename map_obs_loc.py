#!/usr/bin/env python3

import numpy as np
import matplotlib.pyplot as plt
import os
import pandas as pd

# Change to working directory
work_dir = '/work/ftsai/'
# os.chdir(work_dir)

cell_size = 200.  # meters
# Get cell centers
Top = 5000-cell_size/2.
Bot = 0+cell_size/2.
Left = 0+cell_size/2.
Right = 5000-cell_size/2.

# Load data
dfobsid = pd.read_csv(work_dir + 'input/pmploc256.txt')
dfpmpid = pd.read_csv(work_dir + '/input/pmploc256.txt')
# Potential obsloc
dfobsid['xcoor'] = Top - (dfobsid['row']-1)*cell_size
dfobsid['ycoor'] = Left + (dfobsid['col']-1)*cell_size
# Potential pmploc
dfpmpid['xcoor'] = Top - (dfpmpid['row']-1)*cell_size
dfpmpid['ycoor'] = Left + (dfpmpid['col']-1)*cell_size


nx = int((Right-Left)/cell_size) + 1
ny = int((Top-Bot)/cell_size) + 1
nlay = 4
ncells_each_lay = nx*ny
ncells = nx*ny*nlay
print(f'\nnx={nx}, ny={ny}\n')

x = np.linspace(Left, Right, nx)
y = np.linspace(Top, Bot, ny)
ncells = nx*ny

print(f'size x,y ={x.shape, y.shape} \n')

xv, yv = np.meshgrid(x, y)

print(f'size xv,yv ={xv.shape, yv.shape} \n')


x1 = np.reshape(xv, (nx*ny))
y1 = np.reshape(yv, (nx*ny))

# Get cell ijk
cid = np.empty((ncells_each_lay, 2))
ct = 0
for i in range(1, ny+1, 1):
    for j in range(1, nx+1, 1):
        cid[ct, 0] = j  # col (x)
        cid[ct, 1] = i  # row (y)
        ct += 1
out = np.vstack((y1, x1, cid[:, 1], cid[:, 0]))
out2 = np.transpose(out)
print(f'Number of rows of x and y : {out2.shape}\n')

ofile = work_dir + 'output/grid_coor.csv'
np.savetxt(ofile, out2, fmt='%d', delimiter=',')  # fmt='%9.3f',

# plt.plot(x1, y1)
# plt.show()


z = np.random.rand(nx, ny)

#

h = plt.contourf(xv, yv, z)


# Show all potential obs locations
dfobs4 = dfobsid[dfobsid['lay'] == 4]
dfobs4.plot(x='xcoor', y='ycoor', kind='scatter', grid=True, alpha=0.5)

plt.show()

# Show observation location


# References
# [1] pandas.DataFrame.plot
# https://pandas.pydata.org/pandas-docs/version/0.23/generated/pandas.DataFrame.plot.html
