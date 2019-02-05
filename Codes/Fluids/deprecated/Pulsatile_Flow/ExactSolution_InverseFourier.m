clear all

% % % Input
omega0 = 2.13;
nu = 1;
R = 2;
alpha = sqrt(omega0/nu)*R;
alphaVec = linspace(0,2*alpha,100);
r = linspace(0,1,100); % non-dimensional!: "r/R", bound between 0 and 1.
t = linspace(0,2*pi/omega0,90);


% % % Function Declarations
A = @(r,alpha) real(1-besselj(0,alpha.*(1i)^(3/2).*r)./besselj(0,alpha.*(1i)^(3/2)));
B = @(r,alpha) -imag(besselj(0,alpha.*(1i)^(3/2).*r)./besselj(0,alpha.*(1i)^(3/2)));
Asin_p_Bcos = @(r,t,alpha,omega0) A(r,alpha).*sin(omega0*t)+B(r,alpha).*cos(omega0*t);

expiwt_t_Bessels = @(r,t,alpha,omega0) -1i/(2*omega0)*( ...
    exp(1i*omega0*t).*(1-besselj(0,alpha.*(1i)^(3/2).*r)./besselj(0,alpha.*(1i)^(3/2))) ...
    - ...
    exp(-1i*omega0*t).*(1-besselj(0,alpha.*(1i)^(5/2).*r)./besselj(0,alpha.*(1i)^(5/2))) ...
    );

% syms w
% invFourier_method = @(r,t,rho,mu,omega0) ifourier(1i/rho*fourier(cos(omega0*t),t,w).* ...
%     (1-besselj(0,sqrt(rho*w/mu)*R*(1i)^(3/2)*r)/besselj(0,sqrt(rho*w/mu)*R*(1i)^(3/2)))/w,w,t);

% % % Study A

[rgrid,alphagrid] = meshgrid(r,alphaVec);
figure(1)
mesh(r,alphaVec,A(rgrid,alphagrid))
title('A(r,\alpha)')
xlabel('r/R')
ylabel('\alpha')
zlabel('A')

% % % Study B

[rgrid,alphagrid] = meshgrid(r,alphaVec);
figure(2)
mesh(r,alphaVec,B(rgrid,alphagrid))
title('B(r,\alpha)')
xlabel('r/R')
ylabel('\alpha')
zlabel('B')

% % % Study Asin+Bcos
[rgrid,tgrid] = meshgrid(r,t);
figure(10)
mesh(r,t,Asin_p_Bcos(rgrid,tgrid,alpha,omega0)/omega0)
title('Asin+Bcos method')
xlabel('r/R')
ylabel('t')
zlabel('u(r,t)\rho/-|dP/dZ|_{max}')

% % % Study expiwt_t_Bessels
figure(11)
mesh(r,t,expiwt_t_Bessels(rgrid,tgrid,alpha,omega0))
title('complex version pre-Asin+Bcos method')
xlabel('r/R')
ylabel('t')
zlabel('u(r,t)\rho/-|dP/dZ|_{max}')

% % % Study invFourier_method
tmpMatrix = zeros(length(t),length(r));
for i = 1:1:length(t) % The function uses symbolics which does not support matrices.
    tmpMatrix(i,:) = inverseFourier_SolutionScript(r,t(i),R,nu,omega0);
end
figure(12)
mesh(r,t,-real(tmpMatrix))
title('Solution through Matlab''s inverse Fourier function.')
xlabel('r/R')
ylabel('t')
zlabel('\Re{\{u(r,t)\rho/-|dP/dZ|_{max}\}}')

figure(13)
mesh(r,t,-imag(tmpMatrix))
title('Solution through Matlab''s inverse Fourier function.')
xlabel('r/R')
ylabel('t')
zlabel('\Im{\{u(r,t)\rho/-|dP/dZ|_{max}\}}')

% % % Study Asin+Bcos / expiwt_t_Bessels
[rgrid,tgrid] = meshgrid(r,t);
figure(14)
mesh(r,t,Asin_p_Bcos(rgrid,tgrid,alpha,omega0)/omega0./expiwt_t_Bessels(rgrid,tgrid,alpha,omega0)-1)
title('Asin+Bcos method / expiwt\_t\_Bessels method - 1')
xlabel('r/R')
ylabel('t')
zlabel('Should be 0.')

% % % Study Asin+Bcos / inverseFourier
[rgrid,tgrid] = meshgrid(r,t);
figure(15)
mesh(r,t,Asin_p_Bcos(rgrid,tgrid,alpha,omega0)/omega0./-real(tmpMatrix)-1)
title('Asin+Bcos method / inverseFourier method - 1')
xlabel('r/R')
ylabel('t')
zlabel('Should be 0.')
