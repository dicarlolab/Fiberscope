% minimal simulation...
border=4;
nm=16;
N=nm;
NN  = (nm+border)^2;
M = 30;
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
I = zeros(M,M,N*N,3);
E_out = zeros(M*M,N*N);
for cnt=1:N*N
   BasisTmp = reshape(Hm2(:,cnt),N,N);
    Basis = (BasisTmp == 1)*pi;
    % This is the reference phase. Now shift it.
    for ip = 1:PhaseSteps
        DMD_Phases_noBorder(:,cnt,ip)=exp(1i* (Basis(:)+phase(ip)));
        Mask=centerit(Basis+phase(ip), N+border,0);
        DMD_Phases(:,cnt,ip)=exp(1i*(Mask(:)));
        I(:,:, cnt,ip) = reshape(abs(A*TM*DMD_Phases(:,cnt,ip)).^2,M,M);
    end 
    E_out(:,cnt) = A*TM*DMD_Phases(:,cnt,1);
end
Ein = DMD_Phases(:,:,1);
%%
J =I;%(1:2:end,1:2:end,:,:); % sub-sample the image. Make things faster...
newSize = size(J);
%K_obs = (2*J(:,:,1) - J(:,:,3)-J(:,:,2))./3 + 1i*(J(:,:,3) - J(:,:,2))./3;
K_obs = reshape(J(:,:,:,1)-J(:,:,:,2) - 1i*(J(:,:,:,3)-J(:,:,:,2)),M*M,N*N);



Kinv=conj(K_obs');
for ii=2:newSize(1)-1
    for jj=2:newSize(2)-1
        Etarget              = zeros(newSize(1:2));
        Etarget(ii,jj)=1;
        Ein_pre   = (Kinv)*Etarget(:);%./abs(conj(K_obs')*Etarget');
        WeightedInputToGenerateTarget = reshape(DMD_Phases_noBorder(:,:,1) * Ein_pre,N,N);
        tmp = centerit(WeightedInputToGenerateTarget ./ abs(WeightedInputToGenerateTarget).^2,N+border,0);
        %Ein=wrapTo2Pi(angle(WeightedInputToGenerateTarget));
        %temp=exp(1i*(centerit(Ein,N+border,0)));
        GeneratedSpeckle = reshape(abs(A*TM*tmp(:)).^2,M,M);
        figure(4);clf;imagesc(GeneratedSpeckle)
        drawnow
    end
end