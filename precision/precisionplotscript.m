
common = allele_freq>.01;
Rr=inv(omegaEst);
Rrc=Rr(common,common);
Rc=corr(X(:,common));
ind=triu(ones(sum(common)))==0;
f=figure;
subplot(2,2,1);scatter(Rc(ind),Rrc(ind),1);hold on; plot([-1,1],[-1,1]); xlabel('Sample covariance'); ylabel('Regularized covariance')
title('Pairwise LD between common SNPs')
common=find(common,200,'first');
empty=repmat({''},1,length(common));
subplot(2,2,3);imagesc(Rr(common,common));colormap(bluewhitered(256));caxis([-1 1]);set(gca,'XTick',[],'YTick',[]);title('Regularized covariance')
subplot(2,2,4);imagesc(corr(X(:,common)));colormap(bluewhitered(256));caxis([-1 1]);set(gca,'XTick',[],'YTick',[]);title('Sample covariance')
subplot(2,2,2);imagesc(A(common,common)+0);colormap(bluewhitered(256));caxis([-1 1]);set(gca,'XTick',[],'YTick',[]);title('Graphical model')