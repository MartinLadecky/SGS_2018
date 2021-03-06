function [c_1,st,norm_evol, estim, delay,norm_sol,e_norm_error] = solver_PCG_left_grad_norm_Cref(A,G,c_0,E,steps,toler,M_f,tau)
    %% input
    % A   [N_bf2,N_bf1,2,2] -matrix of material parameters in every point of grid
    % G_n [N_bf2,N_bf1,2]   -matrix of coeficients of 1st derivative
    % c_0 [N_bf2,N_bf1]     -initial solution
    % E   [2,1]             -vector [0;1] or [1;0]
    % toler [1]             -relative tolerance
    % steps [1]             -max number of steps
    %% Output
    % c_0 [N_bf2,N_bf1]     -vector of solution
    % st  [1]               -number of stepts
    %% 
    % toler           % relative toleranceF
    % steps           % -max number of steps
    %norm_evol=0;
    M_0 = LHS_freq(A,c_0,G); % System matrix * initial solution(x_0=c_0)
    b_0 = RHS_freq(A,E,G);  % Right hand side vector

    
    
    r_0 = b_0-M_0 ;% x_0=0
    %nr0 =norm(r_0,'fro');

    
    z_0 = r_0./M_f; % solve lin system rM_0=M_f^(-1)*r_0: rM_0 is idagonal matrix
    
    grad_z_0=G.*(z_0);
    nr0 =sqrt(scalar_product_grad(grad_z_0,grad_z_0));
    
    % this is just for comparison
    %grad_z_0=G.*(z_0) % Gradient
    %FGFz_0=fftshift(ifft2(ifftshift(grad_z_0))); % Gradient in real space
    %nz0_grad =sqrt(scalar_product_grad(FGFz_0,FGFz_0))
    %
    
    p_0 = z_0;
    k=1;
    d=0;

    C_precise=load('experiment_data/sol_10_10.mat');
    add_one=0;
    for st = 1:steps
        Ap_0 = LHS_freq(A,p_0,G);
       % DMKP=G.*Ap_0./M_f;
%         grad_Ap_0=G.*(Ap_0./M_f)%new
        %FAp_0=fftshift(ifft2(ifftshift(grad_MAp_0)))
%         disp('Mean grad_MAp_0')
%         mean(mean(fftshift(ifft2(ifftshift(grad_Ap_0)))))
        
%         z_0r_0= sum(sum((z_0.')'.*r_0));
%         p_0Ap_0=sum(sum((p_0.')'.*Ap_0));
%         
        
        %r_0r_0_mod= sum(sum((z_0.')'.*GGz))
        
        Gz=G.*z_0; 
        z_0r_0=scalar_product_grad(Gz,Gz);
        
        
        Gpo=G.*p_0; 
        DMKp_0=G.*(Ap_0./M_f);
        %DDMKP_=G.*G.*Ap_0./M_f;
        %DDMKP=DDMKP_(:,:,1)+DDMKP_(:,:,2); 
        %p_0Ap_0_mod=sum(sum((p_0.')'.*DDMKP))
        p_0Ap_0=scalar_product_grad(Gpo,DMKp_0);
        
        alfa_0=z_0r_0/p_0Ap_0 ;% new
        % alfa_0 = z_0r_0/p_0Ap_0; original 
        

        c_1 = c_0 + alfa_0.*p_0;
        % c_1 = c_0 + alfa_0.*p_0; original 
        grad_Mc_1=G.*(c_1);
        norm_sol(st)=sqrt(scalar_product_grad(grad_Mc_1,grad_Mc_1));
        
        %norm_sol(st)=sqrt(scalar_product_grad_energy(grad_Mc_1,grad_Mc_1,A));
        %e_norm_error(st)=sqrt(scalar_product_grad_energy(grad_Mc_1-G.*C_precise.C,grad_Mc_1-G.*C_precise.C,A));

        %G.*(c_1)
        % disp('Mean c1')
       %  mean(mean(fftshift(ifft2(ifftshift(G.*c_1)))))
%         disp('grad c1')
%         G.*(c_1./M_f)
%         disp('Mean grad c1')
%         mean(mean(fftshift(ifft2(ifftshift(G.*c_1)))))
         

        r_1 = r_0-alfa_0*Ap_0;
        % r_1 = r_0-alfa_0*Ap_0; original
        
          
        z_1=r_1./M_f;
        %z_1_mod=r_1_mod./M_f;
        
        grad_Mz_1=G.*z_1;%new
        nz1=sqrt(scalar_product_grad(grad_Mz_1,grad_Mz_1));%new
        norm_evol(st)=nz1/nr0;
            if ( norm_evol(st)<toler)  
                %if add_one==1
                %c_1 = c_0; 
                break; 
                %end
                %add_one=1;
            end  
            
        %z_1r_1=real(sum(sum((z_1.')'.*r_1)));
        %beta_1 =z_1r_1/z_0r_0;
        %p_1 = z_1 + beta_1*p_0; 
        
        
        Gz_1=G.*z_1; 
        z_1r_1=scalar_product_grad(Gz_1,Gz_1);
        
        beta_1=z_1r_1/z_0r_0;
        p_1 = z_1 + beta_1*p_0;
        
        
           
       
        
        %error estimates
        Delta(st)=real(alfa_0*z_1r_1);
        curve(st)=0;
        curve=curve+Delta(st);
        if st >1
            S=findS(curve,Delta,k);
            num = S*Delta(st);
            den = sum(Delta(k:st-1));
            
            while (d>= 0) && (num/den<= tau)
                delay(k)=d;
                estim(k)=den;
                k=k+1;
                d=d-1;
                den=sum(Delta(k:st-1));
            end
            d=d+1;
        end
        %% 
        p_0 = p_1;
        r_0 = r_1;
        z_0 = z_1; 
        c_0 = c_1;
    end

end


function [S]=findS(curve,Delta,k)
    ind=find((curve(k)./curve) <= 1e-4,1,'last');
    if isempty(ind)
       ind = 1 ;
    end
    S = max(curve(ind:end-1)./Delta(ind:end-1));
end
