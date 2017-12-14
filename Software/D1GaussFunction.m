function F = D1GaussFunction(x,xdata)
% amplitude, center, std
 F = x(1)*exp(   -((xdata-x(2)).^2/(2*x(3)^2)));