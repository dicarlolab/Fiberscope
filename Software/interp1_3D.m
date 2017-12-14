function Ai=interp1_3D(A, xi)
B=reshape(A, size(A,1)*size(A,2),size(A,3));
Ai=reshape(interp1(1:size(A,3),B', xi)', size(A,1),size(A,2),length(xi));
