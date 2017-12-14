function x=fitGaussian1D(Z)
W=(length(Z)-1)/2;
xdata = -W:W;
x0 = [max(Z(:)), 0, 5];
opt=optimset('MaxFunEvals',4000,'MaxIter',1500);
% define lower and upper bounds [Amp,xo,wx,yo,wy,fi]
lb = [min(Z(:)), -W, 0];
ub = [max(Z(:)),  W, W];
[x,resnorm,residual,exitflag] = lsqcurvefit(@D1GaussFunction,x0,xdata,Z(:)',lb,ub,opt);

