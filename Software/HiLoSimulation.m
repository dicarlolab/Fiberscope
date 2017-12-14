%load('HiLo_Test8.mat')
%load('HiLo_Test7');
load('HiLo_Test_Beads1');

% This demonstrates that a guassian kernel of 4 eliminates the cores
% figure(112);clf;
% imagesc(log10(fftshift(abs(fft2(epiImage)))))
% gaussianWidth = 4;kernel2D = fspecial('gaussian',[10*gaussianWidth 10*gaussianWidth],gaussianWidth);
% F=abs(fftshift(fft2(kernel2D, size(epiImage,1),size(epiImage,2))));
% imagesc(log10(F))
% 
% J=conv2(epiImage,kernel2D,'same');
% figure;imagesc(J)
% F=abs(fftshift(fft2( conv2(epiImage,kernel2D,'same'), size(epiImage,1),size(epiImage,2))));
% imagesc(log10(F))
% 
%%
figure(12);
clf;
imagesc(gridImage{GridIntervals==25,1},[0 4095]);
figure(13);
clf;
imagesc(epiImage,[0 4095]);
figure(14);
clf;
imagesc(epiImage-gridImage{GridIntervals==25,1},[0 4095]);

%%
myColorbar();
%%
figure(101);clf;
HiLoMethod = 3;eta=linspace(0.1, 60,9);
% HiLoMethod = 2;eta=linspace(0.1, 3,9);
coreRemovalGaussianWidth = 4.5;
modulationRemovalGaussianWidth = 15;
selectedGrid = 25;

for i=1:length(eta)
    Ihilo=HiLo(LP(epiImage,coreRemovalGaussianWidth), LP(gridImage{GridIntervals==selectedGrid,1},coreRemovalGaussianWidth), eta(i), modulationRemovalGaussianWidth,HiLoMethod);
    iLow = 1.1*mean(mean(Ihilo(300:400,500:600)));
    iHigh = max(Ihilo(:));
    subplot(3,3,i);
    imagesc(Ihilo,[iLow, iHigh]);
    title(num2str(eta(i)));
end
figure(100);
clf;
imagesc(LP(epiImage,coreRemovalGaussianWidth));
%% phase stepping reconstruction
figure(12);clf;
for k=1:length(GridIntervals)
    subplot(2,3,k);
    recon= 1/(3*sqrt(2))* sqrt( (gridImage{k,1}-gridImage{k,2}).^2 + (gridImage{k,1}-gridImage{k,3}).^2 + (gridImage{k,2}-gridImage{k,3}).^2);
    imagesc(LP(recon, 12),[0 10]);
    title(sprintf('Grid = %d',GridIntervals(k)));
end
%%
figure(20);clf;
while (1)
for k=1:size(gridImage,1)
    for j=1:3
        imagesc(gridImage{k,j},[0 4095]);
        drawnow
    end
end
end

%%

load('HiLo_Test2');
coreRemovalGaussianWidth = 4.5;
Ihilo=HiLo(LP(epiImage,coreRemovalGaussianWidth), LP(gridImage{1,3},coreRemovalGaussianWidth),...
    3, modulationRemovalGaussianWidth);

imwrite(uint16(LP(epiImage,coreRemovalGaussianWidth)),'C:\Users\shayo\Downloads\fiji-win64\Fiji.app\plugins\HiLo\Test3_Epi.tif');
imwrite(uint16(LP(gridImage{1,3},coreRemovalGaussianWidth)),'C:\Users\shayo\Downloads\fiji-win64\Fiji.app\plugins\HiLo\Test3_Grid.tif');

figure(11);
clf;
Ilp= LP(epiImage,coreRemovalGaussianWidth);
iLow = 1.1*mean(mean(Ilp(300:400,500:600)));
iHigh = max(Ilp(:));
imagesc(Ilp,[iLow iHigh]);



figure(12);
clf;
iLow = 1.1*mean(mean(Ihilo(300:400,500:600)));
iHigh = max(Ihilo(:));
imagesc(Ihilo,[iLow iHigh]);

  

%%

ALPwrapper('Release');
ALPwrapper('Init');
%%
orientation = 120/180*pi;
width=60;
phase = 0;
grid=fnBuildGridWithOrientation(width, phase, orientation);

id = ALPwrapper('UploadPatternSequence',grid);
res=ALPwrapper('PlayUploadedSequence',id,1, 1);

ALPwrapper('StopSequence');
ALPwrapper('ReleaseSequence',id);


%%
figure(12);
clf;
imagesc(LP(epiImage,3),[300 1200]);
figure(13);
clf;
Ihilo=HiLo(LP(epiImage,3), LP(gridImage,3), 1.5, gaussianWidth);
imagesc( Ihilo,[390 1900]);  
  

%%
J=im2double(rgb2gray(imread('peppers.png')));figure(11);clf;imagesc(J)
% J=epiImage;

Jf=fftshift(fft2(J));
[XX,YY]=meshgrid(1:size(J,2),1:size(J,1));
D=sqrt((XX-size(J,2)/2).^2+(YY-size(J,1)/2).^2);
Jlow = abs(ifft2(Jf.* (D < 100)));

Jflow=fftshift(fft2(Jlow));
freq=35;
M = 0.5;
modulation = sin(freq* linspace(0,2*pi,size(J,2)));
modulation(modulation < 0)=0;
Grid = M*repmat(modulation, size(J,1),1);
Jf_low_grid=fftshift(fft2(Grid.*Jlow));
SSB = XX> size(J,2)/2;
Rplus = (ifft2(Jf_low_grid .* SSB));
C = sqrt(Rplus.*conj(Rplus));
 figure(11);clf;imagesc(Grid.*Jlow,[-1 1]);colormap gray
 figure(11);clf;imagesc((log10(abs(Jf_low_grid))));colormap jet
figure(11);clf;imagesc((log10(abs(Jf_low_grid.*SSB))));colormap jet
figure(11);clf;imagesc(C);colormap gray



%%

X=fspecial('log',[1 100],5);
X=X-min(X(:));
Y=112*sin(2*pi*15* linspace(0,1,100));
Xf=fft(X);
Xyf = fft(X.*Y);
Xssb_yf = Xyf;
Xssb_yf(50:end)=0;
Tmp = ifft(Xssb_yf);
reconX=sqrt(Tmp.*conj(Tmp));

figure(1);
clf;
subplot(4,1,1);
plot(X);
subplot(4,1,2);
plot(abs(fftshift(Xf)));
subplot(4,1,3);
plot(abs(fftshift(Xyf)))
subplot(4,1,4);
plot(reconX);
