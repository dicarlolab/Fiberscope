function grid=fnBuildGrid(width, phase)
grid=repmat( (floor(phase*width) + mod([0:1024-1],2*width)) >= width,768,1);
