kernels = {'original','x_EBC_RA','x_EBC'};

load('tests/input/polbooks.mat', 'x', 'comm_real');
C = numel(unique(comm_real)); % number of communities should be 3 for polbooks
% length(comm_real)/C should be 35 for polbooks

NMI_kernels = NaN(length(kernels),1);
for k = 1:length(kernels)
    % community detection
    comm = mcl_for_graphs_v7(x, C, kernels{k}, ['real_MCL_' num2str(k)]);
    % NMI evaluation
    if length(comm_real)/C < 100
        NMI_kernels(k) = normalized_mutual_information(comm_real, comm, 'adjusted');
    else
        NMI_kernels(k) = normalized_mutual_information(comm_real, comm, 'unadjusted');
    end
    NMI = NMI_kernels(k);
    NMI
    save(['tests/output/unmodified_lgi_mcl/polbooks_' kernels{k} '_MCL_NMI.mat'], 'NMI')
end

for k = 1:length(kernels)
    % community detection
    comm = modified_mcl('tests/input/polbooks.tsv', C, kernels{k}, ['real_MCL_' num2str(k)]);
    % NMI evaluation
    if length(comm_real)/C < 100
        NMI_kernels(k) = normalized_mutual_information(comm_real, comm, 'adjusted');
    else
        NMI_kernels(k) = normalized_mutual_information(comm_real, comm, 'unadjusted');
    end
    NMI = NMI_kernels(k);
    NMI
    save(['tests/output/modified_mcl/polbooks_' kernels{k} '_MCL_NMI.mat'], 'NMI')
end

for k = 1:length(kernels)
    % community detection
    comm = max_iter_modified_mcl('tests/input/polbooks.tsv', C, kernels{k}, ['real_MCL_' num2str(k)], 1);
    % NMI evaluation
    if length(comm_real)/C < 100
        NMI_kernels(k) = normalized_mutual_information(comm_real, comm, 'adjusted');
    else
        NMI_kernels(k) = normalized_mutual_information(comm_real, comm, 'unadjusted');
    end
    NMI = NMI_kernels(k);
    NMI
    save(['tests/output/1_iter_modified_mcl/polbooks_' kernels{k} '_MCL_NMI.mat'], 'NMI')
end

for k = 1:length(kernels)
    % community detection
    comm = max_iter_modified_mcl('tests/input/polbooks.tsv', C, kernels{k}, ['real_MCL_' num2str(k)], 3);
    % NMI evaluation
    if length(comm_real)/C < 100
        NMI_kernels(k) = normalized_mutual_information(comm_real, comm, 'adjusted');
    else
        NMI_kernels(k) = normalized_mutual_information(comm_real, comm, 'unadjusted');
    end
    NMI = NMI_kernels(k);
    NMI
    save(['tests/output/3_iter_modified_mcl/polbooks_' kernels{k} '_MCL_NMI.mat'], 'NMI')
end

for k = 1:length(kernels)
    % community detection
    comm = max_iter_modified_mcl('tests/input/polbooks.tsv', C, kernels{k}, ['real_MCL_' num2str(k)], 5);
    % NMI evaluation
    if length(comm_real)/C < 100
        NMI_kernels(k) = normalized_mutual_information(comm_real, comm, 'adjusted');
    else
        NMI_kernels(k) = normalized_mutual_information(comm_real, comm, 'unadjusted');
    end
    NMI = NMI_kernels(k);
    NMI
    save(['tests/output/5_iter_modified_mcl/polbooks_' kernels{k} '_MCL_NMI.mat'], 'NMI')
end
