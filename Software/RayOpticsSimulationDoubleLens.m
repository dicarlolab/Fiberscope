u1 = 100;
u2 = 100;
f1 = 50;

FS1 = [1 u1; 0 1];
L1 = [1 0 ; -1/f1 1];   
FS2 = [1 u2; 0 1];


FS2 * L1 * FS1 * [1;0]   


f1=100;
f2 = 200;
D = 800;
Si1 = 3*f1;

So1=((f1*Si1)/(Si1-f1)) ;
Si2 = D-So1;
So2=((f2*Si2)/(Si2-f2)) ;
M1 = -So1/Si1;
M2 = -So2/Si2;
[Si1, So1, So2,M1,M2,M1*M2 ]


figure(10);
clf;hold on;
plot([0 0],[0 1],'b','LineWidth',2);
plot([u1 u1],[-2 2],'r','LineWidth',2);
plot([-50 300],[0 0],'k');
set(gca,'xlim',[-50 300]);
set(gca,'ylim',[-2 2]);


M = 1/3;
D =465;
So=D*M/(1+M)
Si=D-So
So/Si
Si+So
f=1/(1/Si+1/So)



1/(1/80-1/2000)