function Q=fnGrab(K,Rate,zeroID)
Q=ISwrapper('GetImageBuffer');
for k=1:K
    %res=ALPwrapper('PlayUploadedSequence',zeroID,Rate, false);
    ISwrapper('SoftwareTrigger');
    WaitSecs(1.0/(Rate-10));
end
WaitSecs(0.2);
Q=ISwrapper('GetImageBuffer');    
