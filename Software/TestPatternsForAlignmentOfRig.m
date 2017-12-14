strDropBoxFolder = 'C:\Users\shayo\Dropbox';

cd([strDropBoxFolder,'\Code\Waveform Reshaping code\MEX\x64']);
addpath([strDropBoxFolder,'\Code\Waveform Reshaping code\ALP\ALPwrapper']);
addpath([strDropBoxFolder,'\Code\Waveform Reshaping code\Camera\ISwrapper']);

H=ALPwrapper('Init');
if (H)
    fprintf('Initialized DMD Successfuly\n');
else
    fprintf('Failed to initialize DMD!\n');
end
%%
% setup a dummy phase to measure exposure times...
[~,L]=LeeHologram(zeros(DMDheight,DMDwidth), selectedCarrier);
zeroID=ALPwrapper('UploadPatternSequence',L);
res=ALPwrapper('PlayUploadedSequence',zeroID,1, false);
ALPwrapper('StopSequence'); % Block. Wait for sequence to end.

P1=zeros(768,1024)>0;
P1(1:768,1:768)=true;
p1=ALPwrapper('UploadPatternSequence',P1);

P2=ones(768,1024)>0;
P2(1:768,769:end)=true;
p2=ALPwrapper('UploadPatternSequence',P2);

while(1)
r=ALPwrapper('PlayUploadedSequence',p1,1, false);
tic; while toc < 0.2; end;
ALPwrapper('PlayUploadedSequence',p2,1, false);
tic; while toc < 0.2; end;
end
