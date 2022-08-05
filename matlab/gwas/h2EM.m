function [h2, sigmasq, betaExpectation, betaVariance] =...
    h2EM(alphaHat, P_cells, nn, annot, reps, betaVar, convergence_tol, approx_threshold, upweight_factor, upweight_factor_decay, weighted_avg_factor)
%h2EM computes MLE of h2 using expectation-maximization
% Input arguments:
% alphahat: GWAS sumstats (m x 1);
% P: LD precision matrix (m x m sparse);
% nn: GWAS sample size (scalar);
% sigmasqSupport: possible values for tau (k x 1);
% sigmasqPrior: prior probability of
% each tau value; reps: number of steps to take
% Ouput arguments
% betaExpectation: expected value of beta given the data

mm = cellfun(@length,alphaHat);
noAnnot = size(annot{1},2);
noBlocks = length(annot);
annot_cat = vertcat(annot{:}) == 1;
annotSum = sum(annot_cat)';
if nargin < 6
    betaVar = zeros(noAnnot,1);
    for ii=1:noAnnot
        betaVar(ii) = 1/nn;
    end
end
betaVarSum = betaVar.*annotSum;
betaVarSum_blocks = zeros(noBlocks,noAnnot);
for ii=1:length(P_cells)
    betaVarSum_blocks(ii,:) = betaVar'.*sum(annot{ii});
end


if nargin < 7
    convergence_tol = 0.001;
end
if nargin < 8
    approx_threshold = 0.25;
end

update_every_block = true;
running_weighted_avg = betaVar;

% dampener = 0.5;
% stepsize = 0.2;

mm_cum = [0; cumsum(mm)];
betaVariance = zeros(mm_cum(end),1);
betaVariance_old = betaVariance;
betaExpectation = betaVariance;
denominator_inv = cell(noBlocks,1);
denominator_inv_sq = denominator_inv;
sigmasq_old = denominator_inv;
diff = 0;
converged = false;
h2 = 0;
for rep = 1:reps
    tic;
    for block = 1:noBlocks
        
        idcs = mm_cum(block)+1:mm_cum(block+1);
        %(annot{block} * tau) .* P{block} + nn * speye(mm(block));
        sigmasq = annot{block} * betaVar;
        % cov_Qtau(beta|alphaHat,tauExpectation) == P/denominator
        if rep > 1
            diff = max(abs((sigmasq - sigmasq_old{block})./sigmasq));
        end
        
        
        if rep == 1 || diff > approx_threshold
            denominator =  P_cells{block} + nn * speye(mm(block)).*sigmasq;
            denominator_inv{block} = sparseinv(denominator);
            betaVariance(idcs) = ...
                sigmasq .* sum(P_cells{block}.*denominator_inv{block},1)';
            sigmasq_old{block} = sigmasq;
            betaVariance_old(idcs) =...
                betaVariance(idcs);
            denominator_inv_sq{block} = sum(denominator_inv{block}.^2)';
        else
            betaVariance(idcs) = ...
                betaVariance_old(idcs) .* sigmasq./sigmasq_old{block} - ...
                (sigmasq - sigmasq_old{block}) .* denominator_inv_sq{block} .* sigmasq;
            if any(betaVariance(idcs) < 0)
                warning('Negative variance estimates produced in approximate E step');
            end
        end
        
        % E_Qtau(beta|alphaHat,tauExpectation) == (P/denominator) * alphaHat
        betaExpectation(idcs) = ...
            nn * P_cells{block} * (((annot{block} * (1./betaVar)) .* P_cells{block} + nn * speye(mm(block))) \ alphaHat{block});
        
        if update_every_block
            for ii=1:noAnnot
                annot_idcs = idcs(annot{block}(:,ii)==1);
                if any(annot_idcs)
                    betaVarSum(ii) = betaVarSum(ii) - betaVarSum_blocks(block,ii);
                    betaVarSum_blocks(block,ii) = (sum(betaExpectation(annot_idcs).^2) + ...
                        sum(betaVariance(annot_idcs)) );
                    betaVarSum(ii) = betaVarSum(ii) + betaVarSum_blocks(block,ii);
                    
                    running_weighted_avg(ii) = running_weighted_avg(ii) * weighted_avg_factor + ...
                        (1 - weighted_avg_factor) * betaVarSum_blocks(block,ii) / length(annot_idcs);
                    
                    betaVar(ii) = (betaVarSum(ii) + upweight_factor * ...
                        running_weighted_avg(ii) * length(annot_idcs)) / ...
                        (annotSum(ii) + upweight_factor * length(annot_idcs));
                end
            end
%                         disp(betaVar)
            
        end
        
    end
    update_every_block = 1;%rep < 10;
    if ~update_every_block
        for ii=1:noAnnot
            annot_idcs = annot_cat(:,ii) == 1;
            if any(annot_idcs)
                betaVar(ii) = (mean(betaExpectation(annot_idcs).^2) + ...
                    mean(betaVariance(annot_idcs)) );
            end
        end
    end
    % E_Qbeta(log P(tau|beta)) == const + log prior + 1/2*log tau
    %     - 1/2 * tau * E(beta.^2)
    
    toc
    h2_old = h2;
    h2 = sum(annot_cat .* betaVar');
    
    disp([rep h2 ])
    if ~any(abs(h2-h2_old)./h2 > convergence_tol)
        converged = true;
        break;
    end
    
    upweight_factor = upweight_factor * upweight_factor_decay;
end
if ~converged
    warning('EM did not converge in %d iterations',reps);
end



end

