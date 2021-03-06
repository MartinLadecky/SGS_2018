function [c_1,st,norm_evol, estim, norm_sol,e_norm_error] = solver_PCG_left_grad_norm(A,G,c_0,E,steps,toler,M_f,tau)
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

    norm_sol(1)=sqrt(scalar_product(c_0,c_0));
    
    r_0 = b_0-M_0 ;% x_0=0
    %nr0 =norm(r_0,'fro');

    
    z_0 = r_0./M_f; % solve lin system rM_0=M_f^(-1)*r_0: rM_0 is idagonal matrix
    
    grad_z_0=G.*(z_0);
    nr0 =sqrt(scalar_product_grad(grad_z_0,grad_z_0));
    
    norm_evol(1)=nr0/nr0;
    p_0 = z_0;
    k=1;
    d=0;

    C_precise=load('experiment_data/sol_10_10.mat');
    add_one=0;
       estim=0;
    for st = 1:steps
        Ap_0 = LHS_freq(A,p_0,G);

        z_0r_0= sum(sum((z_0.')'.*r_0));
        p_0Ap_0=sum(sum((p_0.')'.*Ap_0));
        
        alfa_0=z_0r_0/p_0Ap_0 ;% new

        c_1 = c_0 + alfa_0.*p_0;

            grad_Mc_1=G.*(c_1);
            norm_sol(st+1)=sqrt(scalar_product_grad_energy(grad_Mc_1,grad_Mc_1,A));

        r_1 = r_0-alfa_0*Ap_0;
 
        z_1=r_1./M_f;
        
        grad_Mz_1=G.*z_1;%new
        nz1=sqrt(scalar_product_grad(grad_Mz_1,grad_Mz_1));%new
        norm_evol(st+1)=nz1/nr0;
            if ( norm_evol(st+1)<toler)  
                %if add_one==1
                %c_1 = c_0; 
                break; 
                %end
                %add_one=1;
            end  
            
        z_1r_1=scalar_product(z_1,r_1);
        
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
