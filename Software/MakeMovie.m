function MakeMovie(strctRun, range, test,samplePoints)
if ~exist('test','var')
    test = false;
end
if ~exist('samplePoints','var')
    samplePoints = [];
end

if (isempty(range))
    v=[];
    s=[];
    for k=1:size(strctRun.upsampledData,3)
        A=strctRun.upsampledData(:,:,k);
        v=[v;mean(A(strctRun.circleMask))];
        s=[s;std(A(strctRun.circleMask))];
    end
    M=mean(v(10:end-10));
    S=mean(s(10:end-10));
    range  =  + [mean(M)-3*mean(S), mean(M)+3*mean(S)];
end

i1=find(strctRun.sessionFile == '\',1,'last');
i2=find(strctRun.sessionFile == '.',1,'first');
sessionIndex=strctRun.sessionFile(i1+1:i2-1);
colordef black
hFig=figure(100);
clf;
set(hFig,'position',[ 1081         150         413         810]);
if (~test)
    v = VideoWriter(sprintf('%s-Run-%d.mp4',sessionIndex, strctRun.scanIndex));
    open(v);
end

motorPos=interp1(strctRun.motorPositionUm(2:end,1),strctRun.motorPositionUm(2:end,2),1:size(strctRun.upsampledData,3));

t0=45;
nPoints= size(samplePoints,1);
nFrames = size(strctRun.upsampledData,3);
sampleData = zeros(nPoints,nFrames);
if nPoints > 0
for k=1:nFrames
    sampleData(:,k)=interp2(strctRun.upsampledData(:,:,k),samplePoints(:,1),samplePoints(:,2));
end
end
dF=sampleData-repmat(sampleData(:,t0),1, nFrames);
col = [ 255,255,51;
        51,153,204;
      ];
    
for k=1:size(strctRun.upsampledData,3)
    subplot(2,1,1);cla;
    I=strctRun.upsampledData(:,:,k);
    I(~strctRun.circleMask) = NaN;
    if isempty(range)
        imagesc(I);
    else
        imagesc(I,range);
    end
    hold on;
    for j=1:nPoints
        plot(samplePoints(j,1),samplePoints(j,2),'o','markersize',21,'color',col(j,:)/255);
    end
    
    if (strctRun.pmtFrameTime(k)) < 60
        min=0;
        sec = strctRun.pmtFrameTime(k);
    else
        min = floor(strctRun.pmtFrameTime(k)/60);
        sec = strctRun.pmtFrameTime(k) - min*60;
    end
    text(2,7,sprintf('%02d:%02d',round(min),round(sec)),'color','y','fontsize',16);
    colormap gray
    axis off
    %title(sprintf('%s-Run-%d',sessionIndex, strctRun.scanIndex,k));
    drawnow
    subplot(2,1,2);
    cla;
    if nPoints > 0
    plot(strctRun.pmtFrameTime, dF')
    %plot(motorPos);
    hold on;
    
    plot(strctRun.pmtFrameTime([k k]),[-1000 1000],'w');
    set(gca,'xlim',strctRun.pmtFrameTime(k) + [-10,10]);
    set(gca,'ylim',[-200,300]);%[0.9*nanmin(motorPos) 1.1*nanmax(motorPos)]);
    xlabel('Time (sec)');
    ylabel('dF');
    else
    %     plot(strctRun.pmtFrameTime, dF')
    plot(strctRun.pmtFrameTime,motorPos);
    hold on;
    
    plot(strctRun.pmtFrameTime([k k]),[-3000 3000],'w');
    set(gca,'xlim',strctRun.pmtFrameTime(k) + [-10,10]);
   
%         set(gca,'ylim',[0.9*nanmin(motorPos) 1.1*nanmax(motorPos)]);
   
   
    xlabel('Time (sec)');
    ylabel('Depth (um)');
    end
    drawnow
%     tic
%     while toc < 0.05, end;
    if (~test)
        frm = getframe(hFig);
        writeVideo(v, frm.cdata);
    end
end
if (~test)
close(v);
end
