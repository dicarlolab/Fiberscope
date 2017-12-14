MotorControllerWrapper('Release');

MotoSpeedUmSec = 10;
MotorControllerWrapper('Init');
MotorControllerWrapper('SetSpeed',MotoSpeedUmSec);
% % MotorControllerWrapper('SetStepSize',5);
SingleStepUm = 0.9/4/360*500;
% NumSteps = 400/SingleStepUm;
% 
% for k=1:10
%     PosUm = MotorControllerWrapper('GetPositionMicrons');
%     Pos = MotorControllerWrapper('GetPositionSteps');
%     fprintf('Iteration %d. Position: %.4f, %d\n',k,PosUm,Pos);
%     MotorControllerWrapper('SetRelativePositionSteps',NumSteps);
%     MotorControllerWrapper('SetRelativePositionSteps',-NumSteps);
% end
% 
% 
% 

MotorControllerWrapper('SetRelativePositionSteps', -8600);


afStep=20:25:1000;
for k=1:40
MotorControllerWrapper('SetRelativePositionSteps', afStep(k));
WaitSecs(2);
MotorControllerWrapper('SetRelativePositionSteps', -afStep(k));
WaitSecs(2);
end
  
% MotorControllerWrapper('SetRelativePositionSteps',1600);
% 
% MotorControllerWrapper('SetRelativePositionSteps',-1614);
% MotorControllerWrapper('SetRelativePositionSteps',14);

MotorControllerWrapper('SetSpeed',200);

MotorControllerWrapper('ResetPosition')
%MotorControllerWrapper('SetAbsolutePositionSteps',0);

while (1)
step0=-200;
smallstep = 25;
MotorControllerWrapper('SetRelativePositionSteps', step0);
for k=1:abs(step0/smallstep )
    MotorControllerWrapper('SetRelativePositionSteps', smallstep );
end
end

for k=1:20
    MotorControllerWrapper('SetRelativePositionSteps', -400);
    MotorControllerWrapper('SetRelativePositionSteps', 400);
end

MotorControllerWrapper('SetAbsolutePositionSteps',0);


Q0=fnGrab(80,80,zeroID);
q0 = mean(Q0,3);
pos0 = -500;
step=50;
MotorControllerWrapper('SetRelativePositionSteps', pos0);
clear J;
clear motorpos D J
motorpos(1) = pos0;
for k=1:2*abs(pos0)/step
    Q=fnGrab(10,80,zeroID);
    motorpos(1+k)=motorpos(k)+step;
    MotorControllerWrapper('SetRelativePositionSteps', step);
    WaitSecs(2);
    J(:,:,k)=mean(Q,3);
    A=J(:,:,k);
    D(k)=mean( abs(double(A(:))-double(q0(:))));
end
motorpos=motorpos(2:end);

figure(11);
clf;
plot(motorpos,D);
figure(12);
for k=1:size(J,3)
    imagesc(J(:,:,k));
    title(num2str(k));
    drawnow
end;
%%
  Q2=fnGrab(80,80,zeroID);
  MotorControllerWrapper('SetRelativePositionSteps', 410);
Q3=fnGrab(80,80,zeroID);

mean(mean(abs(mean(Q1,3)-mean(Q2,3))))
mean(mean(abs(mean(Q1,3)-mean(Q3,3))))

figure(1);
imagesc(mean(Q1,3));
figure(2);
imagesc(mean(Q2,3));
figure(3);
imagesc(mean(Q3,3));

A0=ones(1,8)*-100;
% A = [ones(1,20)*+50, ones(1,20)*-50];
% motorIncrement=[0,A0,repmat(A,1,10)];

motorIncrement = [0, 0,0,0,0,-100,0,0,0,0,0,0,0,0,0,0,0,100,0,0,0,0,0,0,0,0,0,0,0];


   
motorPos = cumsum(motorIncrement);

ISwrapper('Init');

ISwrapper('SetExposure',1/4000.0);
numIterations = length(motorIncrement);
I = zeros(480,640,numIterations,'uint16');
Q=ISwrapper('GetImageBuffer');
for iter=1:numIterations
    if abs(motorIncrement(iter)) > 0
        MotorControllerWrapper('SetRelativePositionSteps', motorIncrement(iter));
    end
    
    MotorControllerWrapper('SetRelativePositionSteps', 400);
    fprintf('Starting to grab...\n');
    Q=fnGrab(500,80,zeroID);
    
    figure(2);
    clf;
    clear Di
    for k=1:size(Q,3)-1, 
        subplot(1,2,1);
        imagesc(Q(:,:,k));
        A=double(Q(:,:,k));
        B=double(Q(:,:,end));
        %Di(k)=corr(A(:),B(:));
        Di(k)=mean(A(:)-B(:));
        title(num2str(k));
        subplot(1,2,2);
        plot(Di);
        drawnow
    end;
    
    figure(1);
    clf;
    imagesc(Q);
    title(sprintf('iter %d, motor position: %.2f\n',iter,motorPos(iter)));
    drawnow
end

figure(11);
clf;
J=double(I(:,:,end))-double(I(:,:,1));
imagesc(J)

