#!/usr/bin/env python3

from mpi4py import MPI
import subprocess
import os
import timeit
import numpy as np
from datetime import datetime


def DomainDecompose(comm, rank, size, input):
    if rank == 0:
        nruns = input.shape[0]
        counts = np.arange(size, dtype=np.int32)
        displs = np.arange(size, dtype=np.int32)
        ave = int(nruns / size)
        extra = nruns % size
        offset = 0

        for i in range(0, size):
            ntasks_per_proc = ave if i < size-extra else ave+1
            counts[i] = ntasks_per_proc

            if i == 0:
                ntasks_per_proc0 = ntasks_per_proc
                offset += ntasks_per_proc
                displs[i] = 0
            else:
                comm.send(offset, dest=i)
                comm.send(ntasks_per_proc, dest=i)
                offset += ntasks_per_proc
                displs[i] = displs[i-1] + counts[i-1]

        offset = 0
        ntasks_per_proc = ntasks_per_proc0

    comm.Barrier()

    if rank != 0:  # workers
        offset = comm.recv(source=0)
        ntasks_per_proc = comm.recv(source=0)

    comm.Barrier()
    xml_files = input[offset:offset+ntasks_per_proc]
    return xml_files, ntasks_per_proc


if __name__ == '__main__':

    '''
    Usage example
    mpirun -n 4 python tmpir.py

    '''
    comm = MPI.COMM_WORLD
    rank = comm.Get_rank()
    size = comm.Get_size()
    #print('My rank is ', rank)
    #print(f'size is {size}')
    cwd = os.getenv('cur_dir')
    # print(f'cdir={cwd}\n')

    # Load id of pump locations
    data = np.loadtxt(cwd+'/parentpmp.txt')

    runid, ntasks_per_proc = DomainDecompose(comm, rank, size, data)
    # print(f'runid={runid}\n')
    # print(f'ntasks_per_proc={ntasks_per_proc}\n')

    if rank == 0:
        time_start = timeit.default_timer()
        # Preparing run folders
        #init_run_dir = 'run_' + str(int(data[0, 0]))
        # if not os.path.exists(init_run_dir):  # Make a new directory if not exist
        #    os.system('./getfitness.sh')
        #    print('Generated new run folders\n')
    comm.Barrier()

    for j in range(0, ntasks_per_proc):  # ntasks_per_proc: ntasks for each proc
        tic = timeit.default_timer()
        #cwd = os.getcwd()

        run_dir = cwd + '/run_' + str(int(runid[j, 0]))
        #print(f'current run directory is {run_dir}\n')
        #cmd = 'export run_dir=' + run_dir + '/'
        #subprocess.call(cmd, shell=True)
        # print(f'cmd={cmd}\n')

        os.chdir(run_dir)
        # print(f'cdir={cwd}\n')
        # os.system('ln')
        #cmd = 'python test.py'
        #cmd = 'octave expdsg_run.m > dsp.out'
        cmd = 'expdsg_run.m > /dev/null'
        #cmd = 'octave - qH - -no-window-system expdsg_run.m > /dev/null &'
        subprocess.call(cmd, shell=True)
        os.chdir(cwd)
        toc = timeit.default_timer()
        print(
            f'{str(datetime.now())}, CPU {rank}, {run_dir}, {round((toc-tic)/60,2)} mins.\n')
    comm.Barrier()

    # Clean up: Delete all run folders
    # os.system('rm -rf run_*')
