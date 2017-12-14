function [t,h]=LeeHologram(desiredPhase,fcarrier )
% Lee method for generating amplitude pattern that simulates a phase
% distribution
% t(x,y) = 0.5 * [1+cos(2*pi*(x-y)*alpha - phase(x,y))
% alpha is the carrier frequency
% h(x,y)  = 1 for t(x,y) > 0.5

[x,y]=meshgrid(1:size(desiredPhase,2),1:size(desiredPhase,1));
% desiredPhase = zeros(size(x));
% desiredPhase(50:100,50:100) = pi/2;
% desiredPhase(150:200,150:200) = pi/4;
% fcarrier = 1/20;
t = 0.5 * (1 + cos(2*pi*(x-y)*fcarrier - desiredPhase));
% F=fftshift(fft2(t));
h=t>0.5;
% figure(1);
% subplot(2,1,1);
% imagesc(t)
% subplot(2,1,2);
% imagesc(t>0.5);
% 
