e1=h5read('E:\Sessions\session72.hdf5','/calibrations/calibration1/enhancemnentFactor');
e2=h5read('E:\Sessions\session73.hdf5','/calibrations/calibration1/enhancemnentFactor');
e3=h5read('E:\Sessions\session79.hdf5','/calibrations/calibration1/enhancemnentFactor');
e4=h5read('E:\Sessions\session80.hdf5','/calibrations/calibration1/enhancemnentFactor');
e5=h5read('E:\Sessions\session81.hdf5','/calibrations/calibration1/enhancemnentFactor');
e6=h5read('E:\Sessions\session82.hdf5','/calibrations/calibration1/enhancemnentFactor');
e7=h5read('E:\Sessions\session83.hdf5','/calibrations/calibration1/enhancemnentFactor');
e8=h5read('E:\Sessions\session84.hdf5','/calibrations/calibration1/enhancemnentFactor');
e9=h5read('E:\Sessions\session87.hdf5','/calibrations/calibration1/enhancemnentFactor');
e10=h5read('E:\Sessions\session204.hdf5','/calibrations/calibration1/enhancemnentFactor');

figure(1);
clf;
plot(e1)
hold on;
plot(e2,'r');
plot(e3,'g');
plot(e4,'c');
plot(e5,'k');
plot(e6,'m');
plot(e7,'y');
plot(e8,'k','LineWidth',2);
% plot(e9,'r','LineWidth',2);
legend('64x64 8 mirrors','32x32 16 mirrors','64x64, 6 mirrors','64x64, 10 mirrors','64x64, 11 mirrors','64x64 12 mirrors','32x32 24 mirrors','16x16 48 mirrors');
set(gca,'xlim',[0 3000]);
xlabel('Spot');
ylabel('Enhancement');

figure(2);
clf; hold on;
histogram(e1,'facecolor','b');
histogram(e2,'facecolor','r');
histogram(e3,'facecolor','g');
histogram(e4,'facecolor','c');
histogram(e5,'facecolor','k');
histogram(e6,'facecolor','m');
histogram(e7,'facecolor','y');
% histogram(e9,'facecolor','r');
% histogram(e10,'facecolor','r');
legend('64x64 8 mirrors','32x32 16 mirrors','64x64, 6 mirrors','64x64, 10 mirrors','64x64, 11 mirrors','64x64 12 mirrors','32x32 24 mirrors');
xlabel('Enhancement');
ylabel('# spots');

figure(3);
histogram(e9,'facecolor','b');
xlabel('Enhancement');
ylabel('# spots');
