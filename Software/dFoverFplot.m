function dFoverFplot(SS,BB,range1,range2)
S=mean(SS,3);
B=mean(BB,3);
figure(200);clf;
h1=subplot(2,2,1);imagesc(S,[-range1 range1]);title('Signal');
h2=subplot(2,2,2);imagesc(B,[-range1 range1]);title('Baseline');
h3=subplot(2,2,3);imagesc(S-B,[-range2 range2]);myColorbar();title('Diff');
h4=subplot(2,2,4);imagesc((S-B)./B*100,[-30 30]);myColorbar();title('dF/F');
linkaxes([h1,h2,h3,h4]);impixelinfo
