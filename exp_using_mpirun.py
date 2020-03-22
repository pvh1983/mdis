from mpi4py import MPI
import subprocess
import os
import timeit
import numpy as np


'''
def DomainDecompose(comm, rank, size, input):
    if rank == 0:
        for i in range(1, size, 1):
            comm.send(input[i-1], dest=i)
            print(f'Rank {rank} sent {input[i-1]}\n')
    else:
        data = comm.recv(source=0)
        odir = 'run_' + str(int(data[0]))
        os.chdir(odir)
        cmd = 'pwd'
        subprocess.call(cmd, shell=True)
        print(f'Rank {rank} received {data}')

    comm.Barrier()
'''


def DomainDecompose(comm, rank, size, input):
    if rank == 0:
        nruns = input.shape[0]
        counts = np.arange(size, dtype=np.int32)
        displs = np.arange(size, dtype=np.int32)
        ave = int(nruns / size)
        extra = nruns % size
        offset = 0

        for i in range(0, size):
            col = ave if i < size-extra else ave+1
            counts[i] = col

            if i == 0:
                col0 = col
                offset += col
                displs[i] = 0
            else:
                comm.send(offset, dest=i)
                comm.send(col, dest=i)
                offset += col
                displs[i] = displs[i-1] + counts[i-1]

        offset = 0
        col = col0

    comm.Barrier()

    if rank != 0:  # workers
        offset = comm.recv(source=0)
        col = comm.recv(source=0)

    comm.Barrier()
    xml_files = input[offset:offset+col]
    return xml_files, col


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

    # Load id of pump locations
#    if rank == 0:
    data = np.loadtxt('parentpmp.txt')

    '''    
        npruns = 2
        for i in range(npruns):
            istart = i*size
            istop = (i+1)*size
            data_run_1 = data[istart:istop]
            print(f'i={i},istart={istart}, istop={istop}, size={size}\n')
            print(data_run_1)
    '''

    runid, col = DomainDecompose(comm, rank, size, data)
    # print(f'runid={runid}\n')
    # print(f'col={col}\n')

    if rank == 0:
        time_start = timeit.default_timer()
        # Preparing run folders
        os.system('.getfitness.sh')
    comm.Barrier()

    for j in range(0, col):  # total_number_of_tasks/size (e.g., 4 cores)
        tic = timeit.default_timer()
        cwd = os.getcwd()
        # print(f'cdir={cwd}\n')
        run_dir = 'run_' + str(int(runid[j, 0]))
        #print(f'current run directory is {run_dir}\n')
        os.chdir(run_dir)
        #cmd = 'python test.py'
        cmd = 'pwd'
        subprocess.call(cmd, shell=True)
        os.chdir(cwd)
        toc = timeit.default_timer()
        print(f'CPU {rank} run folder {j+1}: {run_dir} cost {toc-tic} seconds\n')
    comm.Barrier()
