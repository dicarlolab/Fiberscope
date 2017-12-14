% Simulation:
n=1.3;
d=50;
NAmax = 0.29;
waveLength = 473*1e-3;

waveLength/(2*NAmax)

xrange = [-100:100];
zrange = [0:200];
[X,Z]=meshgrid(xrange, zrange);

bestRes = 0.61*waveLength/NAmax;
T=atan2(Z, (X+d/2) ) - atan2(Z, abs(X-d/2));
ExitAngle = atan2(Z,abs(X-d/2));

figure(2);
imagesc(xrange,zrange,ExitAngle)

NA=min( NAmax, n*sin(T/2));
res = 0.61*waveLength./NA;
figure(2);
clf;
subplot(1,2,1);
imagesc(xrange,zrange,NA);
title('NA, position specific');
myColorbar();
subplot(1,2,2);
imagesc(xrange,zrange,res,[bestRes 3])
myColorbar();
title('Reoslution limit (um)');
colormap jet

figure(3);clf;
plot(res(25,:))