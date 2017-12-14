function ALPuploadAndPlay(ALPID,B, rate, cnt,blk)
if ~exist('blk','var')
    blk= true;
end
numPatterns = size(B,3);
maxPatternsInDMD = 40000;
if numPatterns<=maxPatternsInDMD
    % easy. just upload and play.
    id = ALPwrapper('UploadPatternSequence',ALPID,B);
    res=ALPwrapper('PlayUploadedSequence',ALPID,id, rate, cnt);
    if (blk)
        ALPwrapper('WaitForSequenceCompletion',ALPID);
    end
    ALPwrapper('ReleaseSequence',ALPID,id);    
else
    ind = 1:40000:size(B,3);
    if ind(end) ~= size(B,3) || size(B,3) == 1
        ind(end+1) = size(B,3)+1;
    end
    for kk=1:cnt
        for k=1:length(ind)-1
            id = ALPwrapper('UploadPatternSequence',ALPID,B(:,:,ind(k):ind(k+1)-1));
            res=ALPwrapper('PlayUploadedSequence',ALPID,id, rate, 1);
            if (blk)
                ALPwrapper('WaitForSequenceCompletion',ALPID);
            end
            ALPwrapper('ReleaseSequence',ALPID,id);
        end
    end

end
