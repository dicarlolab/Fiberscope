function movieZ(testSequence, keepAspect,rep,rng)
if ~exist('keepAspect','var')
    keepAspect = false;
end
if ~exist('rep','var')
    rep = false;
end
if (keepAspect)
    xlim=get(gca,'xlim');
    ylim=get(gca,'ylim');
end
if ~exist('rng','var')
    rng = [];
end
fig=gca;
while (1)
    for k=1:2:size(testSequence,3)
        imagesc(testSequence(:,:,k),rng)
        if (keepAspect)
            set(gca,'xlim',xlim,'ylim',ylim);
        end
        title(num2str(k))
        drawnow
    end
    if (~rep)
        break
    end
    if (~ishandle(fig))
        break;
    end
        
end