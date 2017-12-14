dir = [1,2];
dir=dir/norm(dir);
N=1000;
r = 1*rand(1,N);
n = randn(2,N)*0.01;
x =  dir(1) *r + n(1,:);
y =  dir(2) *r + n(2,:);

   figure(2);
   clf;
hold on;
plot(dir(1),dir(2),'ro');
w = [0.5,0.5];
alpha =0.01;
for i=1:N
   in = [x(i),y(i)];
   out = in* w';
   dw = alpha * (in * out - out^2*w);
   w=w+dw;
%    w=w/sum(w);
   plot(w(1),w(2),'k.');
   title(num2str(i));
    drawnow
end
 plot(w(1),w(2),'r*');