function basis = fnBuildWalshBasisRotated(n, ang)
% Generate a rotated 2D walsh basis 
B=fnBuildWalshBasis(n);
Bpad = repmat(B,[3 3]);
[X,Y]=meshgrid(1:n,1:n);
R=[cos(ang), -sin(ang);
   sin(ang), cos(ang)];

P=R*[X(:)-n/2,Y(:)-n/2]';
% 
% figure(10);
% clf; hold on;
% plot(X(:),Y(:),'b.');
% plot(n/2+P(1,:),n/2+P(2,:),'r*');
% axis equal

basis = zeros(size(B));
for k=1:size(B,3)
    A=reshape(interp2(Bpad(:,:,k), P(1,:)+n/2+n, P(2,:)+n/2+n,'bilinear'),n,n);
     A(A>=0) = 1;
     A(A<0) = -1;
     basis(:,:,k) = A;
end
% 
%     figure(11);
%     clf;
%     imagesc(Bpad(:,:,k));
%     hold on;
%     plot(P(1,:)+n/2+n, P(2,:)+n/2+n,'g*');
%      
%     figure(12);
%     clf;
%     imagesc(A)    