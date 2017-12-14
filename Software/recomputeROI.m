function roi=recomputeROI(roi, numDepthPlanes)
% given roi structure with:
% roi.boundingbox and roi.subsampling
% returns spot indices.

X = roi.boundingbox(1):roi.subsampling:roi.boundingbox(3);
Y = roi.boundingbox(2):roi.subsampling:roi.boundingbox(4);
[XX,YY]=meshgrid(X,Y);
roi.subsampledSize = [length(Y),length(X)];
% inside
inside = sqrt((XX-(roi.radius+1)).^2+(YY-(roi.radius+1)).^2) <= roi.radius;
roi.numSpots = sum(inside(:));
roi.maxRate = (roi.maxDMDrate / (roi.numSpots*numDepthPlanes));
roi.Mask(:) = 0;
ind = sub2ind(size(roi.Mask),YY(inside),XX(inside));
roi.Mask(ind) = 255;
if roi.maxRate < roi.selectedRate
    roi.selectedRate = roi.maxRate;
end
roi.selectedSpots = find(roi.Mask(:));
roi.numDepthPlanes = numDepthPlanes;
% 
X = roi.boundingbox(1):roi.boundingbox(3);
Y = roi.boundingbox(2):roi.boundingbox(4);
[XX,YY]=meshgrid(X,Y);
roi.InnerDisk = sqrt((XX-(roi.radius+1)).^2+(YY-(roi.radius+1)).^2) <= roi.radius;
roi.offsetX = mod(roi.boundingbox(1)-(floor(((roi.boundingbox(1)))/roi.subsampling)*roi.subsampling+1),roi.subsampling);
roi.offsetY = mod( roi.boundingbox(2)-(floor((roi.boundingbox(2))/roi.subsampling)*roi.subsampling+1),roi.subsampling);
