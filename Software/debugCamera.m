ALPwrapper('Init');

B=ones(768,1024)>0;

id = ALPwrapper('UploadPatternSequence',B);

res=ALPwrapper('PlayUploadedSequence',id,1, 1);

ALPwrapper('ReleaseSequence',id);
ALPwrapper('Release');


Ham=PTwrapper('InitWithResolutionOffset',0,0,1920,1200);
g=PTwrapper('GetGain');
e=PTwrapper('GetExposure');
PTwrapper('SetExposure',1/30);
fprintf('Gain : %.2f, Exp : %.2f ms\n',g,1/e);
PTwrapper('SoftwareTrigger');
WaitSecs(1);
I=PTwrapper('GetImageBuffer');

PTwrapper('Release');

size(I)
figure(11);
clf;
imagesc(I(:,:,end));
% zoom in...

T=round([get(gca,'xlim'), get(gca,'ylim')]/64)*64
[T(2)-T(1),T(4)-T(3)]



Ham=PTwrapper('InitWithResolutionOffset',640,256,640,480);
g=PTwrapper('GetGain');
e=PTwrapper('GetExposure');


width = 15 ; % grid size in pixels
phase = 0;               pat1D_1=mod(phase+[0:1024-1],width) >= width/2;pad1=repmat(pat1D_1,768,1);
phase = floor(width/3);  pat1D_2=mod(phase+[0:1024-1],width) >= width/2;pad2=repmat(pat1D_2,768,1);
phase = floor(2*width/3);pat1D_3=mod(phase+[0:1024-1],width) >= width/2;pad3=repmat(pat1D_3,768,1);
pat_phaseShift=reshape([pad1,pad2,pad3],768,1024,3);

id = ALPwrapper('UploadPatternSequence',pat_phaseShift(:,:,1));
res=ALPwrapper('PlayUploadedSequence',id,1, 1);
ALPwrapper('ReleaseSequence',id);

Tmp = zeros(768,1024)>0;
k=500;
W = 15;
Tmp(:,min(1024,k:k+W)) = true;
id = ALPwrapper('UploadPatternSequence',Tmp);
res=ALPwrapper('PlayUploadedSequence',id,1, 1);
ALPwrapper('ReleaseSequence',id);


e=PTwrapper('SetExposure',1/50);

fprintf('Gain : %.2f, Exp : %.2f ms\n',g,1/e);
PTwrapper('SoftwareTrigger');
WaitSecs(1);
I=PTwrapper('GetImageBuffer');
size(I)

figure(12);
clf;
imagesc(I,[300 500]);



PTwrapper('Release');



