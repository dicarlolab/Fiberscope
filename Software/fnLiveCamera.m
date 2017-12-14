function fnLiveCamera(N)
% ISwrapper('TriggerON');
%ISwrapper('SetExposure',1/200.0); 

%ISwrapper('SetGain',20); 
figure(100);clf;
fr=1;
t=cputime;
fps = 0;
if ~exist('N','var')
    N = Inf;
end
m=1;
while (m<N)
    ISwrapper('SoftwareTrigger');
    I=ISwrapper('GetImageBuffer');
    for k=1:size(I,3)
        imagesc(I(:,:,k),[0 4096]);
        Tmp=get(gca,'CurrentPoint');
        if Tmp(1,2) > 1 && round(Tmp(1,1)) > 1 && Tmp(1,2) < size(I,1) && round(Tmp(1,1)) < size(I,2)
            val=I(round(Tmp(1,2)),round(Tmp(1,1)),k);
        else
        val = NaN;
        end
        title(sprintf('%d: %d %d %d',m,round(Tmp(1,1)),round(Tmp(1,2)),val));

        m=m+1;
        drawnow
    end
    fr=fr+1;
    if cputime-t > 1
        fps = fr;
        fr = 1;
        t = cputime;
    end
    %title(num2str(fps));
    
end