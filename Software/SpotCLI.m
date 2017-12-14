function SpotCLI(strctCalibration, deviceID, x,y)
[Ay,Ax]=ind2sub(strctCalibration.newSize(1:2), strctCalibration.hologramSpotPos);
% find closest point...
[~, indx]=min( sqrt ((Ax-x).^2+ (Ay-y).^2));
P=strctCalibration.holograms(:,:,indx);
ALPuploadAndPlay(deviceID,P,200,1)