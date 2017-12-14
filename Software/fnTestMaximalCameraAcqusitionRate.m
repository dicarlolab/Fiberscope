function rate=fnTestMaximalCameraAcqusitionRate()
% max frame rate camera is speced at: 
ISwrapper('SetExposure',1.0/1000.0); 
maxFPS = 120;
randomSequence = zeros(768,1024, maxFPS,'uint8')>0;
testSeqID=ALPwrapper('UploadPatternSequence',randomSequence);

rate = maxFPS;
successCount = 0;
while (1)
    fprintf('Testing rate %d\n',rate);
    I=ISwrapper('GetImageBuffer'); %clear buffer
    ALPwrapper('PlayUploadedSequence',testSeqID, rate,false); % Play sequence at 100 Hz
    ALPwrapper('StopSequence'); % Block. Wait for sequence to end.
    % wait a bit, then check.
    tic
    while toc < 0.1
    end
    % check how many frames were captured...
    N=ISwrapper('GetBufferSize');
    fprintf('%d / %d triggers detected. \n',N, maxFPS);
    if N == maxFPS
        fprintf('Successfuly recorded all triggers!\n');
        successCount = successCount + 1;
        if (successCount > 2)
            break;
        end
        continue;
    else
        fprintf('Failed. Only %d triggers were detected. \n',N);
    end
    rate = rate - 5;
end

ALPwrapper('ReleaseSequence',testSeqID);
fprintf('Suggested rate:  %d Hz!\n', rate);
