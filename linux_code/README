# Description
---
[test_mcl_run.m](test_mcl_run.m) is the file used to run the matlab LGI-MCL code and the NMI calculations
[mcl_for_graphs_v7.m](mcl_for_graphs_v7.m) is the minimally modified LGI-MCL code in which the cygwin calls has been replaced with native MCL calls for linux
[modified_mcl.m](modified_mcl.m) is the file with above changes and a modified input format to take in edgelist files in tsv format instead of adjacency matrices in matlab format
[max_iter_modified_mcl.m](max_iter_modified_mcl.m) is the file with above changes and an extra argument to specify the number of maximum allowed calls to MCL in the while loop


# Environment prerequisites
---
Matlab and MCL are required. Below instructons are for the Illinois Campus Cluster.

1. run the below command to load the module
'''
module load matlab/9.4
'''
2. run the below command assuming that one is on the Illinois Campus Cluster
'''
export LD_LIBRARY_PATH="/usr/local/matlab/R2018a/runtime/glnxa64:/usr/local/matlab/R2018a/bin/glnxa64:/usr/local/matlab/R2018a/sys/os/glnxa64:/usr/local/matlab/R2018a/sys/opengl/lib/glnxa64:${LD_LIBRARY_PATH}"
'''
3. make sure the mcl binary is in the path

# Compilation Instructions
---
Compiling LGI-MCL for use on a linux machine such as the Illinois Campus Cluster is as simple as below. Note that this mex file is not the same mex file as the one provided in the upstream LGI-MCL repository.
'''
mcc -m ./<name of the .m file you want> -a ./betweenness_centrality_mex.mexa64
'''

# How to run
---
Run the comand as below where the syntax is binary {input tsv} {number of communities} {'original' | 'x_EBC_RA' | 'x_RA' | 'x_EBC_RA'} {relative output prefix}. A sample command is filled in
'''
./<binary> "test.tsv" 3 "original" "output/test"
'''
