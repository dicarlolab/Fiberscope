function myColorbar()
pos = get(gca,'position');
colorbar('location','manual','position',[pos(1)+pos(3)+.01 pos(2) .03 pos(4)]);
impixelinfo;