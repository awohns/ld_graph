% rng('default')
addpath(genpath('precision'))
p='~/Dropbox/Pouria/data/';
A=importGraph([p,'mutgraph_n238']);
X=load([p, 'genomat_n238'])';

% indices with zero diagonal correspond to SNPs that were on the same brick
% as another SNP
SNPs = find(any(A));
X = X(:,SNPs);
A = A(SNPs,SNPs);

[numHaplotypes, numNodes] = size(X);
assert(issymmetric(A));

% set missing values to the mean genotype value
missing = X==-1;
if any(missing(:))
    warning('Some genotypes missing')
    X(missing) = 0;
    allele_freq = repmat(sum(X)./sum(~missing),numHaplotypes,1);
    X(missing) = allele_freq(missing);
    allele_freq = allele_freq(1,:);
else
    allele_freq = mean(X);
end

[ii,jj] = find(A);

% LD matrix for edges of A
X = (X - mean(X,1))./std(X);

%
% incl = sum(missing,2) > 1500;
% X = X(incl,:);
%

R = arrayfun(@(i,j)dot(X(:,i),X(:,j)),ii,jj)/numHaplotypes;
R = sparse(ii,jj,R);

% estimated precision matrix
tol = 1e-4;
% [omegaEst, pval] = LDPrecision(R, omega~=0, numHaplotypes, reps, speye(size(omega)));
tic;[omegaEst, ~] = LDPrecision(R,A,numHaplotypes,tol, speye(numNodes));toc

% Expected is null, non-null, null
% disp('P-values for G, wrong G, true omega:')
% disp([(pval)])

precisionplotscript
