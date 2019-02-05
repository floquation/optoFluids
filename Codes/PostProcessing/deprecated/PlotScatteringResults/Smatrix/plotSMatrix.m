% Quick hack script to plot the amplitude scattering matrix, [S]

% IMPORT SMATRIX MANUALLY INTO A Nx9 MATRIX with 'NaN' WHERE '+' and 'i'
% ARE AT.
% THIS GIVES THE MATRIX: 'Smatrix'

% Polar plot settings:
Smagn_cutoff=100; % Change radial axis to this value

%%%%%%%%%%%%%%%%%%%%%%
% DO NOT TOUCH BELOW %
%%%%%%%%%%%%%%%%%%%%%%

% Throw away NaN data
S=[Smatrix(:,1) Smatrix(:,2) Smatrix(:,4) Smatrix(:,6) Smatrix(:,8)];


%%%%%
% Plot the data represented in several difference way:
%%%
S1magn = sqrt(S(:,2).^2+S(:,3).^2);
S2magn = sqrt(S(:,4).^2+S(:,5).^2);

figure() % S1
plot(S(:,1),S(:,2),'b--')
hold on
plot(S(:,1),S(:,3),'r:')
plot(S(:,1),S1magn,'k-')
hold off
xlabel('\theta_s')
ylabel('S1')
title('Amplitude Scattering Matrix Element S1')
legend('real','imag','magn')

figure() % S2
plot(S(:,1),S(:,4),'b--')
hold on
plot(S(:,1),S(:,5),'r:')
plot(S(:,1),S2magn,'k-')
hold off
xlabel('\theta_s')
ylabel('S2')
title('Amplitude Scattering Matrix Element S2')
legend('real','imag','magn')


figure() % mag(S1) and mag(S2)
plot(S(:,1),S1magn,'r--')
hold on
plot(S(:,1),S2magn,'b:')
plot(S(:,1),sqrt(S1magn.^2+S2magn.^2),'k-')
hold off
% plot(S(:,1),max(S1magn,S2magn),'k-')
hold off
xlabel('\theta_s')
ylabel('[S]')
title('Amplitude Scattering Matrix (Magnitude)')
legend('S1','S2','(S1^2+S2^2)^{1/2}')
axis([0 180 0 100])

figure() % mag(S1) and mag(S2) zoomed around 90 degrees
plot(S(:,1),S1magn,'r--')
hold on
plot(S(:,1),S2magn,'b:')
plot(S(:,1),sqrt(S1magn.^2+S2magn.^2),'k-')
hold off
% plot(S(:,1),max(S1magn,S2magn),'k-')
hold off
xlabel('\theta_s')
ylabel('[S]')
title('Amplitude Scattering Matrix (Magnitude)')
legend('S1','S2','(S1^2+S2^2)^{1/2}')
axis([85 95 0 25])

% plot(S(57:end,1),S1magn(57:end),'r--')
% hold on
% plot(S(57:end,1),S2magn(57:end),'k-')
% hold off

Smagn=sqrt(S1magn.^2+S2magn.^2);
% Smagn<=Smagn_cutoff;

angleDouble = [S(:,1); 180+S(2:end-1,1)]/180*pi;
figure() % mag(S1) and mag(S2) in a polar plot
P = polar(angleDouble, Smagn_cutoff * ones(size(angleDouble)));
hold on
% polar(angleDouble,[S1magn; flipud(S1magn(2:end-1))],'r--')
% polar(angleDouble,[S2magn; flipud(S2magn(2:end-1))],'b:')
polar(angleDouble,[Smagn; flipud(Smagn(2:end-1))],'k-')
set(P, 'Visible', 'off')
hold off
% plot(S(:,1),max(S1magn,S2magn),'k-')
hold off
% xlabel('x')
% ylabel('y')
title('Amplitude Scattering Matrix (Magnitude)')
% legend('S1','S2','(S1^2+S2^2)^{1/2}','location','best')


