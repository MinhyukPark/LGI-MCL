function [comm, C_found, lastI] = max_iter_modified_mcl(edgelist_filepath, C, kernel, fileprefix, max_iter)

edgelist_file = fopen(edgelist_filepath);
edgelist = textscan(edgelist_file,'%s%s');
fclose(edgelist_file);
r = cellfun(@str2num, edgelist{1});
c = cellfun(@str2num, edgelist{2});
node_list = unique([r ; c]);
num_nodes = max([r;c]);
x = sparse(r, c, 1, num_nodes, num_nodes);

% x: original adjacency matrix of the networks
% numbCL: numbe of community
% kernel: type of transformation to compute a weighted network or node-dissimilairties
% filename: prefix of input and output temporary filenames

% comm: community memberships
% noc: flag to indicate if the desired number of clusters has been found

narginchk(5,5)
currdir = strrep([pwd '/'],'\','/');
fileinput = [currdir fileprefix '.in'];
fileoutput = [currdir fileprefix '.out'];
filelog = [currdir fileprefix '.log'];

%%% Writing input file
N = size(x,1);
x1 = weighting(x, kernel);
fileID = fopen(fileinput,'w');
fprintf(fileID,'(mclheader\n');
fprintf(fileID,'mcltype matrix\n');
fprintf(fileID,'dimensions %dx%d\n',size(x1));
fprintf(fileID,')\n');
fprintf(fileID,'(mclmatrix\n');
fprintf(fileID,'begin\n');
for i = 1:size(x1,1)
    fprintf(fileID,'%d:%d ',i-1,N);
    for j = 1:size(x1,2)
       if(x1(j,i)>0)
            fprintf(fileID,'%d:%f ',j-1,x1(j,i));
       end
    end
    fprintf(fileID,'$\n');
end
fprintf(fileID,')\n');
fclose(fileID);

%%% Computing MCL

minInflation = 1.1;
maxInflation = 20;
resolution = [0.1,0.01,0.001];
C_found = 0;
num_iter = 0;

left = 1;
I = minInflation:resolution(1):maxInflation;
right = length(I);
i = left + round((right-left)/2);
c = 1;

for res = resolution
    if left > right
        if lastL == lastR
            if c-1 > C
                lastL = lastL - 1;
            else
                lastR = lastR + 1;
            end
            if lastR > length(I) || lastL < 1
                break
            end
        end
        I = I(lastL):res:I(lastR);
        left = 1;
        right = length(I);
        i = left + round((right-left)/2);
    end
    
    while c-1 ~= C
        
        % Run MCL
        log_file = fopen(filelog,'w');
        fprintf(log_file,'using inflation factor %d\n', I(i));
        fclose(log_file);
        num_iter = num_iter + 1;
        command = "mcl " + fileinput + " -I " + num2str(I(i)) + " -V all -o " + fileoutput;
        system(command);
        lastI = I(i);

        % Reading output file
        fileID = fopen(fileoutput,'r');
        content = textscan(fileID,'%s','delimiter','\n','collectoutput',true);
        comm = NaN(N,1);
        c = 1;
        last = '$';
        for j=8:length(content{1})-1
            ln = content{1}(j);
            sp = strsplit(ln{1});
            if last == '$'
                sp = sp(2:end);
            end
            last = sp{end};
            if last == '$'
                sp = sp(1:end-1);
            end
            for k=1:length(sp)
                idx = str2double(sp{k})+1;
                comm(idx) = c;
            end
            if last == '$'
                c = c + 1;
            end
        end
        
        % Check number of clusters
        lastL = left;
        lastR = right;
        if c-1 > C
            right = i-1;
        elseif c-1 < C
            left = i+1;
        end
        if left > right
            fclose(fileID);
            delete(fileoutput);
            break
        end
        fclose(fileID);
        delete(fileoutput);
        i = left + round((right-left)/2);
        if num_iter == max_iter
            break
        end
    end
    if num_iter == max_iter
        break
    end
    
    if c-1 == C
        C_found = 1;
        break
    end
end
delete(fileinput);
clustering_file_output_path = [currdir fileprefix '_clustering.tsv'];
clustering_file_output_handle = fopen(clustering_file_output_path, 'w');

for i = 1:length(node_list)
    fprintf(clustering_file_output_handle, '%d\t%d\n', i, comm(i));
end

fclose(clustering_file_output_handle);
num_iter
% save(clustering_file_output_path, 'comm', '-tabs');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function x = weighting(x, kernel)
if strcmp(kernel,'original')
    x = x;
elseif strcmp(kernel,'x_EBC')
    x = x + EBC_kernel(x);
elseif strcmp(kernel,'x_EBCr')
    x = x + EBCr_kernel(x);
elseif strcmp(kernel,'x_RA')
    x = x + RA_kernel(x);
elseif strcmp(kernel,'x_RAr')
    x = x + RAr_kernel(x);
elseif strcmp(kernel,'x_EBC_RA')
    x = x + EBC_kernel(x) + RA_kernel(x);
elseif strcmp(kernel,'x_EBCr_RAr')
    x = x + EBCr_kernel(x) + RAr_kernel(x);
elseif strcmp(kernel,'EBC')
    x = EBC_kernel(x);
elseif strcmp(kernel,'EBCr')
    x = EBCr_kernel(x);
elseif strcmp(kernel,'RA')
    x = RA_kernel(x);
elseif strcmp(kernel,'RAr')
    x = RAr_kernel(x);
elseif strcmp(kernel,'EBC_RA')
    x = EBC_kernel(x) + RA_kernel(x);
elseif strcmp(kernel,'EBCr_RAr')
    x = EBCr_kernel(x) + RAr_kernel(x);
elseif strcmp(kernel,'RAs')
    x = RAs_kernel(x);
elseif strcmp(kernel,'EBC_SP')
    x = EBC_SP_kernel(x);
elseif strcmp(kernel,'EBC_SPr')
    x = EBC_SPr_kernel(x);
elseif strcmp(kernel,'RA_SP')
    x = RA_SP_kernel(x);
elseif strcmp(kernel,'RA_SPr')
    x = RA_SPr_kernel(x);
elseif strcmp(kernel,'EBC_RA_SP')
    x = RA_SP_kernel(x) + EBC_SP_kernel(x);
elseif strcmp(kernel,'EBC_RA_SPr')
    x = RA_SPr_kernel(x) + EBC_SPr_kernel(x);
elseif strcmp(kernel,'x_EBC_SP')
    x = x + EBC_SP_kernel(x);
elseif strcmp(kernel,'x_EBC_SPr')
    x = x + EBC_SPr_kernel(x);
elseif strcmp(kernel,'x_RA_SP')
    x = x + RA_SP_kernel(x);
elseif strcmp(kernel,'x_RA_SPr')
    x = x + RA_SPr_kernel(x);
elseif strcmp(kernel,'x_EBC_RA_SP')
    x = x + RA_SP_kernel(x) + EBC_SP_kernel(x);
elseif strcmp(kernel,'x_EBC_RA_SPr')
    x = x + RA_SPr_kernel(x) + EBC_SPr_kernel(x);
end
x = full(x);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Edge Betweenness Centrality
function x_EBC = EBC_kernel(x)
[~,x_EBC]=betweenness_centrality(sparse(x));
x_EBC=1./(1+x_EBC); 
x_EBC(x==0)=0;

function x_EBC = EBCr_kernel(x)
[~,x_EBC]=betweenness_centrality(sparse(x));
x_EBC=1./(1+x_EBC/mean(x_EBC(triu(x,1)==1))); 
x_EBC(x==0)=0;

function x_EBC_SP = EBC_SP_kernel(x)
[~,x_EBC]=betweenness_centrality(sparse(x));
x_EBC_SP = SP(x_EBC);

function x_EBC_SP = EBC_SPr_kernel(x)
[~,x_EBC]=betweenness_centrality(sparse(x));
x_EBC_SP = SPr(x_EBC);

% Repulsion Attraction
function x_RA = RA_kernel(x)
n=size(x,1);
cn=x*x;
ext=repmat(sum(x,2),1,n) - cn - 1;
x_RA=(1 + ext+ext') ./ (1 + cn); % dissimilarity
x_RA=1./(1+x_RA);
x_RA(x==0)=0;

function x_RA = RAr_kernel(x)
n=size(x,1);
cn=x*x;
ext=repmat(sum(x,2),1,n) - cn - 1;
x_RA=(1 + ext+ext') ./ (1 + cn); % dissimilarity
x_RA=1./(1+x_RA/mean(x_RA(triu(x,1)==1)));
x_RA(x==0)=0;

function x_RA_SP = RA_SP_kernel(x)
n=size(x,1);
cn=x*x;
ext=repmat(sum(x,2),1,n) - cn - 1;
x_RA=(1 + ext+ext') ./ (1 + cn); % dissimilarity
x_RA(x==0)=0;
x_RA_SP = SP(x_RA);

function x_RA_SP = RA_SPr_kernel(x)
n=size(x,1);
cn=x*x;
ext=repmat(sum(x,2),1,n) - cn - 1;
x_RA=(1 + ext+ext') ./ (1 + cn); % dissimilarity
x_RA(x==0)=0;
x_RA_SP = SPr(x_RA);

function x_RA = RAs_kernel(x)
n=size(x,1);
cn=x*x;
ext=repmat(sum(x,2),1,n) - cn - 1;
x_RA=(1 + cn)./(1 + ext+ext'); % similarity
x_RA(x==0)=0;

function x_SP = SP(x)
x_SP = graphallshortestpaths(sparse(x),'directed','false');
x_SP = 1./(1+x_SP);
x_SP(eye(size(x))==1) = 0;

function x_SP = SPr(x)
x_SP = graphallshortestpaths(sparse(x),'directed','false');
x_SP = 1./(1+x_SP/mean(x_SP(triu(ones(size(x)),1)==1)));
x_SP(eye(size(x))==1) = 0;

function [bc,E] = betweenness_centrality(A,varargin)
% BETWEENNESS_CENTRALITY Compute the betweenness centrality for vertices.
%
% bc = betweenness_centrality(A) returns the betweenness centrality for
% all vertices in A.  
%
% [bc,E] = betweenness_centrality(A) returns the betweenness centrality for
% all vertices in A along with a sparse matrix with the centrality for each
% edge.  
%
% This method works on weighted or weighted directed graphs.
% For unweighted graphs (options.unweighted=1), the runtime is O(VE).
% For weighted graphs, the runtime is O(VE + V(V+E)log(V)).
%
% ... = betweenness_centrality(A,...) takes a set of
% key-value pairs or an options structure.  See set_matlab_bgl_options
% for the standard options. 
%   options.unweighted: use the slightly more efficient unweighted
%     algorithm in the case where all edge-weights are equal [{0} || 1]  
%   options.ec_list: do not form the sparse matrix with edge [{0} || 1]
%   options.edge_weight: a double array over the edges with an edge
%       weight for each node, see EDGE_INDEX and EXAMPLES/REWEIGHTED_GRAPHS
%       for information on how to use this option correctly
%       [{'matrix'} || length(nnz(A)) double vector]
%
% Note: the edge centrality can also be returned as an edge list using the
% options.ec_list options.  This option can eliminate some ambiguity in the
% output matrix E when the edge centrality of an edge is 0 and Matlab drops
% the edge from the sparse matrix.  
%
% Note: if the edge centrality matrix E is not requested, then it is not
% computed and not returned.  This yields a slight savings in computation
% time.  
%
% Example:
%    load graphs/padgett-florentine.mat
%    betweenness_centrality(A)

% David Gleich
% Copyright, Stanford University, 2006-2008

% History
%  2006-04-19: Initial version
%  2006-05-31: Added full2sparse check
%  2007-03-01: Added edge centrality output
%  2007-04-20: Added edge weight option
%  2007-07-09: Restricted input to positive edge weights
%  2007-07-12: Fixed edge_weight documentation.
%  2008-10-07: Changed options parsing

[trans check full2sparse] = get_matlab_bgl_options(varargin{:});
if full2sparse && ~issparse(A), A = sparse(A); end

options = struct('unweighted', 0, 'ec_list', 0, 'edge_weight', 'matrix');
options = merge_options(options,varargin{:});

% edge_weights is an indicator that is 1 if we are using edge_weights
% passed on the command line or 0 if we are using the matrix.
edge_weights = 0;
edge_weight_opt = 'matrix';

if strcmp(options.edge_weight, 'matrix')
    % do nothing if we are using the matrix weights
else
    edge_weights = 1;
    edge_weight_opt = options.edge_weight;
end

if check
    % check the values
    if options.unweighted ~= 1 && edge_weights ~= 1
        check_matlab_bgl(A,struct('values',1,'noneg',1));
    else
        check_matlab_bgl(A,struct());
    end
    if edge_weights && any(edge_weights < 0)
        error('matlab_bgl:invalidParameter', ...
                'the edge_weight array must be non-negative');
    end
end

if trans
    A = A';
end

weight_arg = options.unweighted;
if ~weight_arg
    weight_arg = edge_weight_opt;
else
    weight_arg = 0;
end
if nargout > 1
    [bc,ec] = betweenness_centrality_mex(A,weight_arg);
    
    [i j] = find(A);
    if ~trans
        temp = i;
        i = j;
        j = temp;
    end
    
    if options.ec_list
        E = [j i ec];
    else
        E = sparse(j,i,ec,size(A,1),size(A,1));
    end
    
else
    bc = betweenness_centrality_mex(A,weight_arg);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [trans check full2sparse] = get_matlab_bgl_options(varargin)
% 
% Internal private function.
%
% Example:
%    Don't use this function!
%

% History
%  2008-09-26: Changed to use merge_options instead

doptions = set_matlab_bgl_default();
if nargin>0
    options = merge_options(doptions,varargin{:});
else
    options = doptions;
end

trans = ~options.istrans;
check = ~options.nocheck;
full2sparse = options.full2sparse;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function old_default = set_matlab_bgl_default(varargin)
% SET_MATLAB_BGL_DEFAULT Sets a default option for the Matlab BGL interface
%
% old_default = set_matlab_bgl_default(options) or
% old_default = set_matlab_bgl_default(...) for key-value pair version
% options.istrans: the input matrices are already transposed [{0} || 1]
% options.nocheck: skip the input checking [{0} || 1]
% options.full2sparse: convert full matrices to sparse [{0} || 1]
%
% to get the current set of default options, call
% options = set_matlab_bgl_default()
%
% These options can make the Matlab BGL interface more efficient by
% eliminating the copying operations that occur between Matlab's structures
% and the BGL structures.  However, they are more difficult to use and are
% disabled by default.
%
% Generally, they are best used when you want to perform a large series of
% computations.
%
% Example:
%   % tranpose the matrix initially...
%   At = A'
%   old_options = set_matlab_bgl_default(struct('istrans',1));
%   % perform a bunch of graph work with At...
%   d1 = dfs(At,1); d2 = dfs(At,2); ...
%   % restore the old options 
%   set_matlab_bgl_default(old_options);

% David Gleich
% Copyright, Stanford University, 2006-2008

persistent default_options;
if ~isa(default_options,'struct')
    % initial default options
    default_options = struct('istrans', 0, 'nocheck', 0, 'full2sparse', 0);
end

if nargin == 0
    old_default = default_options;
else
    old_default = default_options;
    default_options = merge_options(default_options,varargin{:});
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function options = merge_options(default_options,varargin)
% MERGE_OPTIONS Merge a set of default options with options from varargin
% The set of options in varargin can be a list of key,value pairs, or a
% struct with the same information.

% David F. Gleich
% Copyright, Stanford University, 2008

% History
% 2008-09-25: Initial coding

if ~isempty(varargin) && mod(length(varargin),2) == 0
    options = merge_structs(struct(varargin{:}),default_options);
elseif length(varargin)==1 && isstruct(varargin{1})
    options = merge_structs(varargin{1},default_options);
elseif ~isempty(varargin)
    error('matlag_bgl:optionsParsing',...
        'There were an odd number of key-value pairs of options specified');
else
    options = default_options;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function check_matlab_bgl(A, options)
% CHECK_MATLAB_BGL Checks the input A for various properties
%
% check_matlab_bgl(A,options) throws an input error if...
%   A is not square
%   if options.values and A is not double valued
%   if options.sym = 1 and A is not symmetric
%   if options.flow_graph = 1 and A is not a flow graph data structure
%   if options.nosparse = 1 do not check if A is sparse
%   if options.nodefault = 1 then do not check default cases
%   if options.nodiag = 1 throw an error if A has any non-zero diagonal values

% David Gleich
% Copyright, Stanford University, 2006-2008

% History
% 2007-04-20: Added nodefault option
% 2007-07-22: Fixed empty array error for noneg check
% 2008-09-23: Added no diagonal check, misc formatting fixes

if ~isfield(options, 'nodefault') || options.nodefault == 0
    if size(A,1) ~= size(A,2)
        error('matlab_bgl:invalidParameter', 'the matrix A must be square.');
    end
end

if isfield(options, 'values') && options.values == 1
    if ~isa(A,'double')
        error('matlab_bgl:invalidParameter', 'the matrix A must have double values.');
    end
end

if isfield(options, 'noneg') && options.noneg == 1
    v=min(min(A));
    if ~isempty(v) && v < 0
        error('matlab_bgl:invalidParameter', 'the matrix A must have non-negative values.');
    end
end

if isfield(options, 'sym') && options.sym == 1
    if ~isequal(A,A')
        error('matlab_bgl:invalidParameter', 'the matrix A must be symmetric.');
    end
end

if isfield(options, 'nosparse') && options.nosparse == 1
else
    if ~issparse(A)
        error('matlab_bgl:invalidParameter', 'the matrix A must be sparse.  (See set_matlab_bgl_default.)');
    end
end

if isfield(options,'nodiag') && options.nodiag == 1
    if any(diag(A))
        error('matlab_bgl:invalidParameter',...
            'the matrix A must not have any diagonal values')
    end
end
