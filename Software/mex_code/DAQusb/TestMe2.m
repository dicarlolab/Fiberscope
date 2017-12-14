addpath('C:\Users\shayo\Dropbox (MIT)\Code\Waveform Reshaping code\MEX\x64');
A=fnDAQusb('Init');

A=fnDAQusb('ReadAnalog',0,0);

res = fnDAQusb('Init',0);
res = fnDAQusb('InitScan',31*10000);

% % res = fnDAQusb('Init',0);
% % res = fnDAQusb('Release',0);

%4991/31
9982/31
9982+31
19995/31

19964
res = fnDAQusb('StopAndResetBuffer',0);

while (1)
    [A,B,C]=fnDAQusb('GetStatus',0);
    fprintf('%d %d\n',B,C);
end


H=ALPwrapper('Init');
Seq = false(768,1024,50);
offID=ALPwrapper('UploadPatternSequence',Seq);

Seq1 = false(768,1024,1);
Seq1ID=ALPwrapper('UploadPatternSequence',Seq1);

Seq2 = false(768,1024,2);
Seq2ID=ALPwrapper('UploadPatternSequence',Seq2);

ALPwrapper('PlayUploadedSequence',offID,80,false);
ALPwrapper('PlayUploadedSequence',Seq1ID,100,false);



while (1)
    Buf=fnDAQusb('GetBuffer',0);
    [A,B,C]=fnDAQusb('GetStatus',0);
    fprintf('%d\n',B);
    figure(1);
    clf;
    plot(Buf(1:B))
    drawnow
end