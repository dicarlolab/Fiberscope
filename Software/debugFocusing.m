ALPwrapper('Init');

figure(1);
clf;
rectangle('position',[1 1 1024 768],'facecolor',[0.1 0.1 0.1]);
set(gca,'xlim',[0 1025],'ylim',[0 769]);
[x,y]=ginput(2);
hold on;
plot(x,y,'r*');
xm = min(x);
ym = min(y);
rectangle('position',[xm ym abs(diff(x)), abs(diff(y))],'facecolor',[0.7 0.7 0.7]);

B = zeros(768,1024)>0;
s=1;

B(1:s,:)=1;
B(768-s+1:768,:)=1;

B(:,1:s)=1;
B(:,768-s+1:768)=1;

B(:,1:s)=1;
B(:,1024-s+1:1024)=1;


% B(768/2-5:768/2+5,1024/2-5:1024/2+5)=1;
%% Horizontal Sweep
B=zeros(768,1024, 1024,'uint8');
W=25;
s=10;
for k=1:1024
    Tmp = zeros(768,1024)>0;
    Tmp(:,min(1024,k:k+W)) = true;
    
% 
% Tmp(1:s,:)=1;
% Tmp(768-s+1:768,:)=1;
% 
% Tmp(:,1:s)=1;
% Tmp(:,768-s+1:768)=1;
% 
% Tmp(:,1:s)=1;
% Tmp(:,1024-s+1:1024)=1;
% 
%     
    
   B(:, :,k) = Tmp;
end

id = ALPwrapper('UploadPatternSequence',B);
res=ALPwrapper('PlayUploadedSequence',id,300, 0);

ALPwrapper('StopSequence');
ALPwrapper('ReleaseSequence',id);
%% Grid
width=40;
phase = 0;
pat1D=mod(phase+[0:1024-1],2*width) >= width;
pad1=repmat(pat1D,768,1);

id = ALPwrapper('UploadPatternSequence',pad1);
res=ALPwrapper('PlayUploadedSequence',id,1, 1);

ALPwrapper('StopSequence');
ALPwrapper('ReleaseSequence',id);

%% Single Vertical stripe

B=zeros(768,1024, 1,'uint8');
W=40;
s=1024/2;
B(:,s-W:s+W) = true;

s=s+4*W;
B(:,s-W:s+W) = true;


id = ALPwrapper('UploadPatternSequence',B);
res=ALPwrapper('PlayUploadedSequence',id,1, 1);

ALPwrapper('StopSequence');
ALPwrapper('ReleaseSequence',id);
%% Single Horizontal stripe

B=zeros(768,1024, 1,'uint8');
W=10;

s=430;
% B(s-W:s+W,:) = true;
B(:,s-W:s+W) = true;


% B(s-W:s+W,1024/2-200:1024/2+200) = true;
 
%   B(230,:)=true;
%   B(236,:)=true;
% 
% s=396;
% B(s,:)=true;

%  
%  s=s+100;
%  B(s-W:s+W,:) = true;


id = ALPwrapper('UploadPatternSequence',B);
res=ALPwrapper('PlayUploadedSequence',id,1, 1);

ALPwrapper('StopSequence');
ALPwrapper('ReleaseSequence',id);
%% Cross

B=zeros(768,1024, 1,'uint8');
s=3;
B(:,1024/2-s:1024/2+s) = true;
B(768/2-s:768/2+s,:) = true;

id = ALPwrapper('UploadPatternSequence',B);
res=ALPwrapper('PlayUploadedSequence',id,1, 1);

ALPwrapper('StopSequence');
ALPwrapper('ReleaseSequence',id);
%% Centered box


B=zeros(768,1024)>0;
W = 44;
yrange = min(768,max(1,768/2-W:768/2+W));
xrange = min(1024,max(1,1024/2-W:1024/2+W));
B(yrange, xrange) = 1;
id = ALPwrapper('UploadPatternSequence',B);
res=ALPwrapper('PlayUploadedSequence',id,1, 1);
ALPwrapper('ReleaseSequence',id);



%% full screen

ALPwrapper('Init');
%% Full screen

B=ones(768,1024)>0;
id = ALPwrapper('UploadPatternSequence',B);
res=ALPwrapper('PlayUploadedSequence',id,1, 1);
ALPwrapper('ReleaseSequence',id);
%% zero mask
B=zeros(768,1024)>0;
id = ALPwrapper('UploadPatternSequence',B);
res=ALPwrapper('PlayUploadedSequence',id,1, 1);
ALPwrapper('ReleaseSequence',id);


%%

ALPwrapper('Release');


%%

h=PTwrapper('InitWithResolutionOffset',64*10,64*7,640,480)
h=PTwrapper('GetGain')
h=PTwrapper('GetExposure') * 1000

h=PTwrapper('SoftwareTrigger');
I=PTwrapper('GetImageBuffer');

figure(11);
clf;
imagesc(I)

PTwrapper('Release');
clear mex


%% Characterize input-output
ISwrapper('Init');

GridInterval = 10:1:40;
phase = 0;
orientation = 52/180*pi;
i=5;
dutyCycle = 1;;
Speed = 80;
ISwrapper('SetExposure',1/2000);
ISwrapper('SetGain',0);

I=ISwrapper('GetImageBuffer');
N = 10;
clear GridI
for a=1:length(GridInterval)
    for b=1:length(dutyCycle)
        fprintf('%d %d\n',a,b);
        ALPuploadAndPlay(fnBuildGridWithOrientation(GridInterval(a),phase,orientation,dutyCycle(b)), Speed, N);
        while ISwrapper('GetBufferSize') < N, end
        I=ISwrapper('GetImageBuffer');
        GridI{a,b} = mean(I,3);
  %      figure(11);clf;imagesc(mean(I,3));myColorbar();impixelinfo
    end
end

save('GridInputOutput','GridI','GridInterval','dutyCycle');

innerCircle = LP(GridI{GridInterval == 10, dutyCycle == 1},5)>60;
K=fspecial('gaussian',[1 50],2);
%%
clear Profile
for k=1:1:length(GridInterval)
M=sum(GridI{k, dutyCycle == 1},1)./sum(innerCircle,1);
Profile(k,:)=M(120:420);
sortedValues = sort(Profile(k,:));
lowValues = mean(sortedValues(1:50));
highValues = mean(sortedValues(end-10:end));
contrast(k)=highValues./lowValues;
end
figure;
plot(GridInterval,contrast)
xlabel('Grid Interval');
ylabel('Contrast');

figure(2);
clf;hold on;
plot(Profile(GridInterval==30,:),'c')
plot(Profile(GridInterval==20,:))
plot(Profile(GridInterval==15,:),'r')
legend('Grid = 30','Grid = 20','Grid = 15');
figure(3);
clf;
subplot(2,2,1);
imagesc(GridI{GridInterval==15,1})
title('Grid = 15');
subplot(2,2,2);
imagesc(GridI{GridInterval==20,1})
title('Grid = 20');
subplot(2,2,3);
imagesc(GridI{GridInterval==25,1})
title('Grid = 25');

figure(4);
clf;hold on;
plot(Profile(GridInterval==25,:),'c')

impixelinfo

imagesc(LP(GridI{GridInterval==25,1},15))



%%
Hcam=PTwrapper('InitWithResolutionOffset',704,256,640,480); 
ALPwrapper('Init');

I=PTwrapper('GetImageBuffer');

PTwrapper('GetBufferSize')

ALPuploadAndPlay(ones(768,1024)>0,1,1);
ALPuploadAndPlay(zeros(768,1024)>0,1,1);
ALPuploadAndPlay(zeros(768,1024)>0,1,1);
ALPuploadAndPlay(ones(768,1024)>0,1,1);
ALPuploadAndPlay(ones(768,1024)>0,1,1);
ALPuploadAndPlay(zeros(768,1024)>0,1,1);

[J]=PTwrapper('PokeLastImageTuple',3);

whos J
figure(1);
clf;
imagesc(J(:,:,1))
figure(2);
clf;
imagesc(J(:,:,2))
figure(3);
clf;
imagesc(J(:,:,3))