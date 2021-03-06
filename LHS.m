function [Mv] = LHS(A,v,G_n)
% transformace Fx a derivace G*F
% grad(c)
c=fftshift(fft2(ifftshift(v)));

GFx=G_n.*c; 
%iF[grad(c)]
FGFx=fftshift(ifft2(ifftshift(GFx)));
%A(x)(iF[grad(c)])
AFGFx=cat(3,A(:,:,1,1).*FGFx(:,:,1)+A(:,:,1,2).*FGFx(:,:,2),...
            A(:,:,2,1).*FGFx(:,:,1)+A(:,:,2,2).*FGFx(:,:,2));
%div(F[A(x)(iF[grad(c)])])
GAFGFx=G_n.*fftshift(fft2(ifftshift(AFGFx)));
Mc=GAFGFx(:,:,1)+GAFGFx(:,:,2); 
Mv=fftshift(ifft2(ifftshift(Mc)));
end