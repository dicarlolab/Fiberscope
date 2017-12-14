function [x0,y0,res]=reWriteCameraParams(x0,y0,res)
x0=floor(min(1280,max(0,round(x0)))/64)*64;
y0=floor(min(1200,max(0,round(y0)))/64)*64;

hFile = fopen('GetCameraParams.m','wb');
fprintf(hFile,'function [X,Y,Res]=GetCameraParams()\n');
fprintf(hFile,'X=%d;\n',x0);
fprintf(hFile,'Y=%d;\n',y0);
fprintf(hFile,'Res = %d;\n',res);
fclose(hFile);
rehash
clear GetCameraParams