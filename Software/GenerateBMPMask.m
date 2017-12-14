maskfile = 'C:\Users\shayo\Dropbox (MIT)\Code\Github\FiberImaging\Code\Masks\SFN.bmp';
%maskfile = 'C:\Users\shayo\Dropbox (MIT)\Code\Github\FiberImaging\Code\Masks\FiberScope.bmp';

I=~imread(maskfile);
ind=find(I(:)>0);
quan = 2;
ind=ind(1:quan:end);
fprintf('%d number of spots\n',length(ind));
[i,j]=ind2sub(size(I),ind);

holograms = zeros(768,128, length(ind),'uint8');
for k=1:length(ind)
    holograms(:,:,k)= handles.calibration.generateHolorgramSpot(j(k),i(k));
end
ALPID=0;
id = ALPwrapper('UploadPatternSequence',ALPID,holograms);
res=ALPwrapper('PlayUploadedSequence',ALPID,id, 22000, 0);
ALPwrapper('ReleaseSequence',ALPID,id);

ALPwrapper('StopSequence',ALPID);
