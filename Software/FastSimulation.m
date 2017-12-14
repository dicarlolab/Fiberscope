% minimal simulation...
border=4;
nm=16;
N=nm;
NN  = (nm+border)^2;
M = 50;
fprintf('generating a random matrix of size %d x %d x %d x %d\n',M,M,nm+border,nm+border);
TM=random('Normal',0,1/2,M*M,NN)+1i*random('Normal',0,1/2,M*M,NN);


A = 1/N;
Nb = N+border;
Hm2 = walsh(N*N);
%phase = [0, pi/2, -pi/2];
phase = [0, pi/2, pi];
PhaseSteps = length(phase);

% Generate the sampling input patterns
numSamplePatterns = N*N*PhaseSteps;
DMD_Phases = zeros(Nb*Nb,N*N,PhaseSteps);
DMD_Phases_noBorder = zeros(N*N,N*N,PhaseSteps);
% Build phase basis
for cnt=1:N*N
   BasisTmp = reshape(Hm2(:,cnt),N,N);
    Basis = (BasisTmp == 1)*pi;
    % This is the reference phase. Now shift it.
    for ip = 1:PhaseSteps
        DMD_Phases_noBorder(:,cnt,ip)=exp(1i* (Basis(:)+phase(ip)));
        Mask=centerit(Basis+phase(ip), N+border,0);
        DMD_Phases(:,cnt,ip)=exp(1i*(Mask(:)));
    end
end
SamplePhases = reshape(DMD_Phases,Nb*Nb,N*N*PhaseSteps);
Eout = A*TM*SamplePhases;
% Read images...
I = reshape(abs(Eout).^2, M,M,N*N,PhaseSteps);
%%
J =I(1:2:end,1:2:end,:,:); % sub-sample the image. Make things faster...
newSize = size(J);
J=reshape(J,newSize(1)*newSize(2), newSize(3),newSize(4));
%K_obs = (2*J(:,:,1) - J(:,:,3)-J(:,:,2))./3 + 1i*(J(:,:,3) - J(:,:,2))./3;
K_obs = J(:,:,1)-J(:,:,2) - 1i*(J(:,:,3)-J(:,:,2));
Kinv=conj(K_obs');
for ii=2:newSize(1)-1
    for jj=2:newSize(2)-1
        Etarget              = zeros(newSize(1:2));
        Etarget(ii,jj)=1;
        
        Ein_pre   = (Kinv)*Etarget(:);%./abs(conj(K_obs')*Etarget');
        Ein_phase =wrapToPi (angle(Ein_pre));
        WeightedInputToGenerateTarget = reshape(DMD_Phases_noBorder(:,:,1) * exp(1i*Ein_phase(:)),N,N);
        Ein=wrapTo2Pi(angle(WeightedInputToGenerateTarget));
        temp=exp(1i*(centerit(Ein,N+border,0)));
        GeneratedSpeckle = reshape(abs(A*TM*temp(:)).^2,M,M);
        figure(4);clf;imagesc(GeneratedSpeckle)
        drawnow
    end
end