function Out=ToGray(A,range)

V=max(0,min(1,(A-range(1))/  (range(2)-range(1))));
J=gray(256);
Out = zeros([size(A),3]);
Out(:,:,1) =interp1(0:255,J(:,1),255*V);
Out(:,:,2) =interp1(0:255,J(:,2),255*V);
Out(:,:,3) =interp1(0:255,J(:,3),255*V);

