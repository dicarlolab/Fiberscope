% fig = figure;
% %  code to populate the figure
% plot(1:10);
set(gcf,'color','black');
% save original values for InvertHardcopy, PaperPosition,PaperPositionMode, and PaperSize
ih=get(gcf,'invertHardCopy');
pp=get(gcf,'PaperPosition');
ppm=get(gcf,'PaperPositionMode');
ps=get(gcf,'PaperSize');
% tell print to leave the background color alone, and to "match screen size" when generating the output
set(gcf, 'InvertHardcopy', 'off', 'PaperPositionMode', 'auto');
ppos = get(gcf, 'PaperPosition'); 
% when pdf is put on clipboard, make it "tight" around the figure content
set(gcf, 'PaperSize', ppos(3:4)); 
print(gcf, '-dpdf', '-clipboard');
% restore original values of InvertHardcopy, PaperPosition, PaperPositionMode, and PaperSize 
set(gcf,'invertHardCopy',ih);
set(gcf,'paperPosition',pp);
set(gcf,'paperPositionMode',ppm);
set(gcf,'PaperSize',ps);

