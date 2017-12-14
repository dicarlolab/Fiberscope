function x=fitGaussian2D(Z,opt)
MdataSize = (size(Z,1)-1); % Size of nxn data matrix
% parameters are: [Amplitude, x0, sigmax, y0, sigmay, angel(in rad)]
[maxZ,ind]=max(Z(:));
[yyy,xxx]=ind2sub(size(Z),ind);

x0 = [maxZ,xxx-size(Z,2)/2,2,yyy-size(Z,1)/2,2]; %Inital guess parameters
% x = [2,2.2,7,3.4,4.5,+0.02*2*pi]; %centroid parameters



%% ---Generate centroid to be fitted--------------------------------------
[X,Y] = meshgrid(-MdataSize/2:MdataSize/2);
xdata = zeros(size(X,1),size(Y,2),2);
xdata(:,:,1) = X;
xdata(:,:,2) = Y;
[Xhr,Yhr] = meshgrid(linspace(-MdataSize/2,MdataSize/2,300)); % generate high res grid for plot
xdatahr = zeros(300,300,2);
xdatahr(:,:,1) = Xhr;
xdatahr(:,:,2) = Yhr;
%---Generate noisy centroid---------------------
% Z = D2GaussFunctionRot(x,xdata);
% Z = Z + noise*(rand(size(X,1),size(Y,2))-0.5);

%% --- Fit---------------------
if ~exist('opt','var')
    opt=optimset('MaxFunEvals',4000,'MaxIter',1500,'TolFun',1e-12);
end
% define lower and upper bounds [Amp,xo,wx,yo,wy,fi]
lb = [0,-MdataSize/2,0,-MdataSize/2,0];
ub = [realmax('double'),MdataSize/2,(MdataSize/2)^2,MdataSize/2,(MdataSize/2)^2];
[x,resnorm,residual,exitflag] = lsqcurvefit(@D2GaussFunction,x0,xdata,Z,lb,ub,opt);

% figure(1)
% C = del2(Z);
% mesh(X,Y,Z,C) %plot data
% hold on
% surface(Xhr,Yhr,D2GaussFunctionRot(x,xdatahr),'EdgeColor','none') %plot fit
% axis([-MdataSize/2-0.5 MdataSize/2+0.5 -MdataSize/2-0.5 MdataSize/2+0.5 -noise noise+x(1)])
% alpha(0.2)  
% hold off

