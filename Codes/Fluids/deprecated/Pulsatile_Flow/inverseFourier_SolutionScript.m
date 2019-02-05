function y = inverseFourier_SolutionScript(rIn,tIn,Rin,nuIn,omega0In)

syms r w t
syms invFourier_method(r,t)

invFourier_method(r,t) = ifourier(1i*fourier(cos(omega0In*t),t,w).* ...
    (1-besselj(0,sqrt(w/nuIn)*Rin*(1i)^(3/2)*r)/besselj(0,sqrt(w/nuIn)*Rin*(1i)^(3/2)))/w,w,t);

y = invFourier_method(rIn,tIn);
end