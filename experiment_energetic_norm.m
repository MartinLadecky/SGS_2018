%function [A_0,st,t,Nbf]=Hom_solver(N)
%% HOMOGENIZATION PROBLEM
%  sol PDE -div(A(x)grad(u))=div(A(x)E))
%  then homogenized A_0E=int(A(x)(E+grad(u)))dx/(volume of omega)
%% Input
% N   [1]    -number of points in sample
%% Output
% A_0 [2,2] -Homogenized material parameters
% st  [1]   -Number of iteration steps
% t   [1]   -Time
%% BEGIN
clc;clear;

tic
E_0=[1 0;0 1];
A_0=zeros(2,2);

loop1=1;
counter=1;
steps = 250;
for loop=[10]%(4:1:10)%%[8]%(1:1:12)%[8]%(1:1:12)%[1]%(5:1:12)%[1,5,10,11]%,20,21,22
N_1=2*(loop^2)+1%2*(loop^2)+1% number of points in x_1-1

N_2=N_1; % number of points in x_2

%% Mesh parameters
h_1=2*pi/(N_1); % step in x_2
h_2=2*pi/(N_2); % step in x_2

%% Coordinates
x=zeros(N_2,N_1,2);
[x(:,:,1),x(:,:,2)]=meshgrid(-pi+h_1/2:h_1:pi-h_1/2,-pi+h_2/2:h_2:pi-h_2/2);

%% Material coeficient matrix

 Pixels = imread('structure_3.png');

 pixa=round(linspace(1,size(Pixels,2),N_1));
 piya=round(linspace(1,size(Pixels,1),N_2));
 
  
  Min_eig = 100000;
 Max_eig= 0;
 A=zeros(N_2,N_1,2,2);
  C_ref=zeros(N_2,N_1,2,2); 
  for i=1:N_2
     for j=1:N_1    
          A(i,j,:,:)=a_matrix_img(Pixels(piya(i),pixa(j)));%a_matrix(x(i,j,:));%
         pom = zeros(2);
         pom(1,1) = A(i,j,1,1); pom(1,2) = A(i,j,1,2);
         pom(2,1) = A(i,j,2,1); pom(2,2) = A(i,j,2,2);        
         p = eig(pom);
         min_eig = min(p);
         max_eig = max(p);
         if (min_eig<Min_eig) 
             Min_eig=min_eig; 
         end
         if (max_eig>Max_eig)
             Max_eig=max_eig;
         end       
     end       
  end
 Max_kappa = Max_eig/Min_eig;
 [Min_eig,Max_eig,Max_kappa]
 if Min_eig<0
     return
 end
 

%% Material ananlysis
d=[mean(mean(A(:,:,1,1))) mean(mean(A(:,:,1,2)))*0;...
   mean(mean(A(:,:,2,1)))*0 mean(mean(A(:,:,2,2)))];
for i=1:N_2
     for j=1:N_1    
          C_ref(i,j,:,:)=d;
     end
end

%% Derivatives
G=G_clasic(N_1,N_2);
G_n=G_matrix(N_1,N_2);
G_m=G_mean(N_1,N_2,d);

%% Preconditioning
[M_m] = M_mean(N_1,N_2,d);

M_fGn_const= -(d(1,1).*(G_n(:,:,1).^2)+d(2,2).*(G_n(:,:,2).^2)...
                   +2*d(1,2).*(G_n(:,:,1).*(G_n(:,:,2))));  
               
M_fGn_const((end+1)/2,(end+1)/2)=1;

M_fG_const= -(d(1,1).*(G(:,:,1).^2)+d(2,2).*(G(:,:,2).^2)...
                   +2*d(1,2).*(G(:,:,1).*(G(:,:,2))));  
               
M_fG_const((end+1)/2,(end+1)/2)=1;

%% Conditions:
tau=0.25
toler = 1e-6;
c_000=zeros(N_2,N_1);

%c_000=c_000-mean(mean(c_000));



%% Projection based solver
c_0 = c_000;

disp('Projection based solver')
for k=1:1
    E=E_0(:,k); 
    tic;
    [Cp,st,norm_evolp, estimp, delayp, sol_normp,e_norm_error_p]=CGP_projection_left(A,G,c_0,E,steps,toler,M_fG_const,d,tau);
    sol_normp
    Tp(k,counter) = toc;
    Sp(k,counter) = st;
    A_p(:,k)=Hom_parameter_grad(Cp,A,G,E) % Compute homogenized parameter
    Ap(counter)=A_p(1,1);
end

%% SOLVER with constant preconditionig from left grad error measure
c_0=c_000;
disp('SOLVER with constant preconditionig from left hand side ::: grad error measure')
for k=1:1
    E=E_0(:,k);
    tic;
    [C,st,norm_evolg, estimg, delayg, sol_normg,e_norm_error_g]=CGP_solver_left_grad(A,G,c_0,E,steps,toler,M_fG_const,tau);% with preconditioning
    sol_normg
    Tg(k,counter)=toc;
    Sg(k,counter) = st;
    A_g(:,k)=Hom_parameter(C,A,G,E)% Compute homogenized parameter
    Ag(counter)=A_g(1,1);
    
end

    %grad_proj=fftshift(ifft2(ifftshift(Cp)));
    %grad_disp=fftshift(ifft2(ifftshift(G.*C))); %G.*(C./M_fG_const)
%     grad_proj_mean=mean(mean(grad_proj))
%     grad_disp_mean=mean(mean(grad_disp))

%% SOLVER with preconditioner incorporated into Grad operator G_m
disp('SOLVER with preconditioner incorporated into Grad operator G_m')
c_0 = c_000;
for k=1:1
    E=E_0(:,k); 
    tic;
    [C,st,norm_evol1]=CG_solver(A,G_m,c_0,E,steps,toler,M_m);
    T1(k,counter) = toc;
    S1(k,counter) = st;
    A_1(:,k)=Hom_parameter(C,A,G,E) % Compute homogenized parameter
    A1(counter)=A_1(1,1);
end

%% SOLVER with symetric preconditionig M and G
disp('SOLVER with symetric preconditionig M and G')
c_0 = c_000;
for k=1:1
    E=E_0(:,k); 
    tic;
    [C,st,norm_evol2]=CG_solver_symPrec(A,G,c_0,E,steps,toler,M_m);

    T2(k,counter) = toc;
    S2(k,counter) = st;
    A_2(:,k)=Hom_parameter(C,A,G,E) % Compute homogenized parameter
    A2(counter)=A_2(1,1);
end

%% SOLVER with constant preconditionig from left hand side
c_0=c_000;
disp('SOLVER with constant preconditionig from left hand side')
%toler = 1e-6;
for k=1:1
    E=E_0(:,k);
    tic;
    [C,st,norm_evol3, estim3, delay3]=CGP_solver_left(A,G,c_0,E,steps,toler,M_fG_const,tau);% with preconditioning
    T3(k,counter)=toc;
    S3(k,counter) = st;
    A_3(:,k)=Hom_parameter(C,A,G,E)% Compute homogenized parameter
    A3(counter)=A_3(1,1);
    
end




% error 
  NoP(counter)=N_1*N_2;
  counter=counter+1;
end
%% 

%save('experiment_data/sol_10_10.mat','C');
% save('experiment_data/exp2/S1.mat','S1');
% save('experiment_data/exp2/S2.mat','S2');
% save('experiment_data/exp2/S3.mat','S3');
% save('experiment_data/exp2/T1.mat','T1');
% save('experiment_data/exp2/T2.mat','T2');
% save('experiment_data/exp2/T3.mat','T3'); 

%% Plot estimates
rel_estim3=estim3./estim3(1);
rel_estimg=estimg./estimg(1);
rel_estimp=estimp./estimp(1);

 figure 
 hold on
  plot((1:numel(estim3)),abs(rel_estim3),'.')
  plot((1:numel(estim3)),abs(rel_estim3./(1-tau)),'.') 
  
 plot((1:numel(estimg)),abs(rel_estimg),'--x')
  plot((1:numel(estimg)),abs(rel_estimg./(1-tau)),'--x')
  
  plot((1:numel(estimp)),abs(rel_estimp),'--o')
  plot((1:numel(estimp)),abs(rel_estimp./(1-tau)),'--o')
  
set(gca, 'XScale', 'linear', 'YScale', 'log');
legend('rel estim3 lower','rel estim3 upper','rel estimg lower','rel estimg upper','rel estimp lower','rel estimp upper')
%% Plot residuals
 figure 
 hold on
 plot((1:S1(1,end)) ,norm_evol1,'x')
 plot((1:S2(1,end)),norm_evol2,'o')
 plot((1:S3(1,end)),norm_evol3,'^')
 
  plot((1:Sp(1,end)),norm_evolp,'-.*')
  plot((1:Sg(1,end)),norm_evolg,'-.^')
  
  
  plot((1:numel(estim3)),abs(rel_estim3),'--r')
  plot((1:numel(estim3)),abs(rel_estim3./(1-tau)),'--b')
  
set(gca, 'XScale', 'linear', 'YScale', 'log');
legend('in G','Symetric','Left','proj','grad_norm','estim3')

%% Plot solution norm
%  figure 
%  hold on
% % plot((1:Sp(1,end)+1),abs(sol_normp-sol_normg),'-.*')
%  % plot((1:Sg(1,end)),sol_normg,'-.^')
%  %plot((1:Sp(1,end)+1),abs(norm_evolp-norm_evolg),'-.*')
%   
% set(gca, 'XScale', 'linear', 'YScale', 'log');
% legend('sol_norm','res_ norm')

%% Plot error energetic norm

 figure 
 hold on
 plot((1:Sp(1,end)),real(e_norm_error_p)/real(e_norm_error_p(1)),'-.*')
 plot((1:Sp(1,end)),real(e_norm_error_g)/real(e_norm_error_g(1)),'-.o')
 plot((1:Sp(1,end)),abs(real(e_norm_error_g-e_norm_error_p)),'-.')
  
set(gca, 'XScale', 'linear', 'YScale', 'log');
legend('e_norm_error_projection','e_norm_error_left prec')


close all

 %% Plot A function