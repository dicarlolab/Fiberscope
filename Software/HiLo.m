function Ihilo=HiLo(epiImage, gridImage, eta, gaussianWidth,Method)
% Jerome Mertz HiLo algorithm for rejection of out of focus light
% eta is the weighting factor between low and high frequencies
% gaussianWidth is a blurring that should get rid of the sine wave modulation
if (Method == 1)
% Method 1 (as described in JBO letters 2009)
R = gridImage./epiImage; %  = 1 + C * M * Sin(Kg*x+phase)
Rf=fftshift(fft2(R));
[XX,YY]=meshgrid(1:size(R,2),1:size(R,1));
SSB = XX> size(R,2)/2;
Rplus = (ifft2(Rf .* SSB)); 
C = sqrt(Rplus.*conj(Rplus)); % estimate of C from R
Ilp = LP(C .* epiImage, gaussianWidth); % get rid of sine modulations
Ihp = epiImage - LP(epiImage,gaussianWidth);
Ihilo = eta*Ilp + Ihp;
elseif (Method == 2)
% Method 1 (as described in JBO letters 2009)
R = gridImage./epiImage; %  = 1 + C * M * Sin(Kg*x+phase)
Rf=fftshift(fft2(R));
[XX,YY]=meshgrid(1:size(R,2),1:size(R,1));
SSB = XX> size(R,2)/2;
Rplus = (ifft2(Rf .* SSB)); 
C = 1-sqrt(Rplus.*conj(Rplus)); % estimate of C from R
Ilp = LP(C .* epiImage, gaussianWidth); % get rid of sine modulations
Ihp = epiImage - LP(epiImage,gaussianWidth);
Ihilo = eta*Ilp + Ihp;

else
% Method 3 (as described in JBO 2012)
Iu=epiImage./LP(epiImage, gaussianWidth);
Is=gridImage./LP(gridImage, gaussianWidth);
C=abs(Is-Iu); 
Ilow = LP(C .* epiImage,gaussianWidth);
Ihigh = epiImage - LP(epiImage,gaussianWidth); 
%Ihigh = HP(epiImage, gaussianWidth);
Ihilo = eta*Ilow + Ihigh;
end
% figure(1);
% clf;
% imagesc(Iu,[0.8 1.2]);myColorbar()
% imagesc(Is,[0.8 1.2]);myColorbar()
% imagesc(Ilow)
% imagesc(Ihigh)
% eta=105;Ihilo = eta*Ilow + Ihigh; imagesc(Ihilo);
% % 
% gaussianWidth = 8;
% % 
if 0
figure(1);
clf;
imagesc(R)
figure(2);
clf;
imagesc(log10((abs(Rf ))))
figure(3);
clf;
imagesc(C); myColorbar(); % close to 1 means unmodulated.
figure(6);clf;imagesc((1-C).*epiImage)
figure(4);
clf;
imagesc(Ilp)
figure(5);
clf;
imagesc(Ihp)
figure(6); clf;eta=0.7; Ihilo = eta*Ilp + Ihp;imagesc(Ihilo);
figure(7);clf;imagesc(epiImage); 

end