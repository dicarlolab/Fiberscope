pos=h5read('E:\Sessions\session157.hdf5','/calibrations/calibration1/sweepTestPositions');
rad=h5read('E:\Sessions\session157.hdf5','/calibrations/calibration1/radius');
distFromCenter = sqrt((pos(:,1)-rad).^2+(pos(:,2)-rad).^2);

sessions = [157,158,159,160,163,164,165,166];
numReps = 1:8;

clear enhancement
for k=1:8
    enhancement(k,:)=h5read(sprintf('E:/Sessions/session%d.hdf5', sessions(k)),'/calibrations/calibration1/enhancemnentFactor');
end

% plot as a function from fiber center...
radinterval = 0:5:rad+5;
clear m s
for k=1:length(radinterval)-1
    ind=find(distFromCenter >= radinterval(k) & distFromCenter < radinterval(k+1));
    m(:,k) = mean(enhancement(:,ind),2);
    s(:,k) = std(enhancement(:,ind),[],2);
end

figure(10);imagesc(sort(enhancement,2,'descend'));myColorbar();

col=lines(8);
figure(1);
clf;hold on;
clear h
c=1;
for k=1:8
    h(c)=errorbar(c/3+radinterval(1:9),m(k,:),s(k,:),'color',col(k,:));
    plot(c/3+radinterval(1:9), m(k,:),'o','color',col(k,:));
    c=c+1;
end
xlabel('Distance from fiber center (~um)');
ylabel('Enhancement');
set(gca,'xticklabel',{'0-5','5-10','10-15','15-20','20-25','25-30','30-35','35-40','40-45','45-50','50-55'});
 set(gca,'xlim',[-2 42])
legend(h,{'1 Rep','2 Rep','3 Rep','4 Rep','5 Rep','6 Rep','7 Rep','8 Rep'});

set(gca,'xlim',[0 1200]);
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
legend('1 Rep','2 Rep','3 Rep','4 Rep','5 Rep','6 Rep','7 Rep','8 Rep');
xlabel('Enhancement');
ylabel('# spots');

figure(3);
histogram(e9,'facecolor','b');
xlabel('Enhancement');
ylabel('# spots');
