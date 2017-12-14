function [X,Y,Res1,Res2]=GetCameraParams()
%[X,Y]=GetFiberPosition();

X=700;
Y=446; 
X=round(X/16)*16;
Y=round(Y/2)*2;
Res1 = 128;
Res2 = 128;
% 
% X=round(0/64)*64;
% Y=round(0/64)*64;
% Res1 = 1920;
% Res2 = 1200;
