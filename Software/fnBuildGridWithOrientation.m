function grid=fnBuildGridWithOrientation(width, phase, orientation, dutycycle)
% orientation 0 = vertical
[XX,YY]=meshgrid(1:1024,1:768);
R = [cos(orientation) sin(orientation)
     -sin(orientation) cos(orientation)];
Z=R*[XX(:), YY(:)]';
grid = reshape(mod(Z(1,:)+phase*width, 2*width) >= dutycycle*width, size(XX));
% figure(1);clf; grid=fnBuildGridWithOrientation(40, 0, 20/180*pi);imagesc(grid)
% 
% 
% 
% grid=repmat( (floor(phase*width) + mod([0:1024-1],2*width)) >= width,768,1);
