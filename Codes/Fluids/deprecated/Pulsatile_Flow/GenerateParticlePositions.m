function GenerateParticlePositions(dPdXmax, omega0, R, rho, nu, ...
    numParticles, t_min, t_max, t_num, outputPrefix, outputSuffix)

if(t_max==-1)
    t_max=2*pi/omega0;
end

% Particle initial positions (N,[r/R,phi,z/L])
r0 = zeros(numParticles,3);
r0(:,1) = rand(numParticles,1);
r0(:,2) = rand(numParticles,1)*2*pi;
r0(:,3) = 0; %rand(numParticles,1);

% Sample spacetime
% rVector = linspace(0,1,51); % dimensionless position "r/R", bound between 0 and 1
tVector = linspace(t_min,t_max,t_num); % at what times should the position be evaluated
% timeRes = 0.001; % MAXIMUM timestep to be taken in integrating particle positions

% /********************************************\
% | %%%%%% DO NOT TOUCH BELOW THIS LINE %%%%%% |
% | %%%%%% OR DO TOUCH... IM NOT A COP. %%%%%% |
% \********************************************/

% % % Compute some constants
alpha = sqrt(omega0/nu)*R; % Womersley number: alpha=sqrt(omega0/nu)*R

% % % Exact solution to a cosine pressure, derived via Fourier analysis:
A = @(r,alpha) real(1-besselj(0,alpha.*(1i)^(3/2).*r)./besselj(0,alpha.*(1i)^(3/2)));
B = @(r,alpha) -imag(besselj(0,alpha.*(1i)^(3/2).*r)./besselj(0,alpha.*(1i)^(3/2)));
% Asin_p_Bcos = @(r,t,alpha,omega0) A(r,alpha).*sin(omega0*t)+B(r,alpha).*cos(omega0*t);
% uFunc = @(r,t,alpha,omega0,dPdXmax,rho) Asin_p_Bcos(r,t,alpha,omega0)/(rho*omega0)*-dPdXmax;

% Since this is a very easy function of time, and the velocity only has a
% z-component without a z-dependency, inertialess particles have a very
% easy relationship for their position. No numerical integration is
% required:
mAcos_p_Bsin = @(r,t,alpha,omega0) -A(r,alpha).*cos(omega0*t)+B(r,alpha).*sin(omega0*t);
zFunc_m_z0 = @(r,t,alpha,omega0,dPdXmax,rho) ...
    (mAcos_p_Bsin(r,t,alpha,omega0)-mAcos_p_Bsin(r,zeros(size(t)),alpha,omega0))/(rho*omega0^2)*-dPdXmax;


% [rgrid,tgrid] = meshgrid(rVector,tVector);
% figure()
% mesh(rVector,tVector,zFunc_m_z0(rgrid,tgrid,alpha,omega0,dPdXmax,rho))
% title('Exact solution for inertialess particle position')
% xlabel('r/R')
% ylabel('t')
% zlabel('z(r,t)-z(r,0)')
% figure()
% mesh(rVector,tVector,uFunc(rgrid,tgrid,alpha,omega0,dPdXmax,rho))
% title('Exact solution for inertialess particle velocity')
% xlabel('r/R')
% ylabel('t')
% zlabel('u_z(r,t)')



% % % % Compute particle positions as a function of time and write it to a
% % file
% rold = r0;
% for i_t = 1:length(tVector)-1
%     % Initialise the current timestep
%     rnew = zeros(size(rold));
%     told = tVector(i_t);
%     tnew = tVector(i_t+1);
%     Dt = tnew-told;
%     
%     % Integrate particle positions to the next timestep
%     timeRes_local = min(Dt/ceil(Dt/timeRes),timeRes);
%     for i_tsub = 1:1:round(Dt/timeRes_local) % Iterate over subtimesteps to enhance space integration
%         % Init current iteration
%         tnew_sub = told_sub + timeRes_local;
%         u = uFunc(rVector,t,alpha,omega0,dPdXmax,rho);
%         
%         % Interpolate 
%         
%         % Integrate FDS
%         rnew = rold + u*timeRes_local;
%         
%         % Next iteration
%         told_sub = tnew_sub;
%     end
%     
%     % Output to file
%     
%     % Prepare for next iteration
%     rold = rnew;
% end

% % % Output particle positions using the exact solution (no numerical
% integration):
for i_t = 1:length(tVector)
    t = tVector(i_t);
    r = r0; % r and phi remain unchanged
    r(:,3) = r0(:,3) + zFunc_m_z0(r(:,1),t,alpha,omega0,dPdXmax,rho); % z changes, since uvec // zhat.
    fileID = fopen(strcat(outputPrefix,num2str(t),outputSuffix),'w');
    fprintf(fileID,'%i\n',length(r0(:,1)));
    fprintf(fileID,'(\n');
    fprintf(fileID,'(%d %d %d)\n',[r(:,1).*cos(r(:,2)),r(:,1).*sin(r(:,2)),r(:,3)]'); % write x,y,z position to file
    fprintf(fileID,')\n');
    fclose(fileID);
    clear fileID
end



end % function
%EOF