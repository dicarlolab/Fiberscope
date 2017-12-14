addpath(genpath('C:\Users\shayo\Dropbox (MIT)\Code\Github\Planner'));
E=MRIread('C:\Users\shayo\Dropbox (MIT)\Data\Retinotopy\ecc.nii');
P=MRIread('C:\Users\shayo\Dropbox (MIT)\Data\Retinotopy\polar.nii');

% fit best sine wave?
%t=(squeeze(E.vol(75,33,24,:)));

t=(squeeze(E.vol(75,33,24,:)));
t= (t-mean(t));

%% Fourier method
Fs = 0.5;
n = 2^nextpow2(length(t));
f = Fs*(0:(n/2))/n;
F = fft(t,n);

figure(11);
clf;
plot(abs(F(1:n/2+1)));
hold on;
plot(17, abs(F(17)),'ro');
bestPhase = angle(F(17));
bestAmplitude = sqrt(abs(F(17)))/2;
TT = 0:2:32*2*9;

figure(11);
clf;
plot(bestAmplitude*sin(2*pi* (1/(32*2))* TT -bestPhase ));
hold on;
plot(t)



%% correlation method
t=t-mean(t);
x = 0:32*9- 1;
f = 1;
y1= sin(2*pi*f*x/32);
y2= cos(2*pi*f*x/32);
r1 = corr(y1',t);
r2 = corr(y2',t);
phase_offset=atan2(r2,r1);
best_corr = sqrt(r1^2+r2^2);
plot(x,t,x, 10*sin(2*pi*f*x/32+phase_offset));
phase_offset/pi*180

%% Eccentricity Full volume...
Sz = size(E.vol);
VolReshaped = reshape(E.vol, prod(Sz(1:3)),Sz(4));
numVoxels = size(VolReshaped,1);

x = 0:32*9- 1;
f = 1;
y1= sin(2*pi*f*x/32);
y2= cos(2*pi*f*x/32);
phase_offset = zeros(1,numVoxels);
best_corr = zeros(1,numVoxels);
for k=1:numVoxels
    t=VolReshaped(k,:);
    t=t-mean(t);
    r1 = corr(y1',t');
    r2 = corr(y2',t');
    phase_offset(k)=atan2(r2,r1);
    best_corr(k) = sqrt(r1^2+r2^2);
end

Ecc = reshape(phase_offset, Sz(1:3));
EccScore = reshape(best_corr, Sz(1:3));
save('Eccentricity','Ecc','EccScore');
%% Seed

SeedPoint = [56,75,16];

EccValue = Ecc(SeedPoint(2),SeedPoint(1),SeedPoint(3));
PolarValue = Polar(SeedPoint(2),SeedPoint(1),SeedPoint(3));

% Find similar values....


EccScore(SeedPoint(2),SeedPoint(1),SeedPoint(3))
PolarScore(SeedPoint(2),SeedPoint(1),SeedPoint(3))

%
figure(11);
clf;
imagesc(squeeze(EccScore(73,:,:))');

%%
VolReshaped = reshape(P.vol, prod(Sz(1:3)),Sz(4));
x = 0:32*9- 1;
f = 1;
y1= sin(2*pi*f*x/32);
y2= cos(2*pi*f*x/32);
phase_offset = zeros(1,numVoxels);
best_corr = zeros(1,numVoxels);
for k=1:numVoxels
    if mod(k,1000) == 0
        fprintf('%.2f\n',k/numVoxels*100);
    end
    t=VolReshaped(k,:);
    t=t-mean(t);
    r1 = corr(y1',t');
    r2 = corr(y2',t');
    phase_offset(k)=atan2(r2,r1);
    best_corr(k) = sqrt(r1^2+r2^2);
end

Polar = reshape(phase_offset, Sz(1:3));
PolarScore = reshape(best_corr, Sz(1:3));
save('Polar','Polar','PolarScore');
%%

%%


fnVolumeViewer(Ecc/pi*180,EccScore>0.3)

TempVolume = E;
TempVolume.nframes=1;
TempVolume.vol = EccScore;
MRIwrite(TempVolume,'Test.nii');
