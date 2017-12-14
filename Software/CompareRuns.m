strFolder = 'E:\100um_GradedIndex_Experiment20WirePassing\';

strctExpA = load(sprintf('%sExp%04d.mat',strFolder,4));
strctExpB = load(sprintf('%sExp%04d.mat',strFolder,11));
figure(3);clf;
for k=1:20:size(strctExpA.Qr,3)
    subplot(1,3,1);
    imagesc(strctExpA.Qr(:,:,k),[0 1000])
    subplot(1,3,2);
    imagesc(strctExpB.Qr(:,:,k),[0 1000])
    subplot(1,3,3);
    imagesc(abs(double(strctExpA.Qr(:,:,k))-double(strctExpB.Qr(:,:,k))),[0 400])    
    drawnow
end

% sqrt((200-166)^2+(197-205).^2)*0.3
figure(2);clf;
for k=1:20:size(strctExpB.Qr,3)
    imagesc(strctExpB.Qr(:,:,k),[0 1000])
    drawnow
end
impixelinfo