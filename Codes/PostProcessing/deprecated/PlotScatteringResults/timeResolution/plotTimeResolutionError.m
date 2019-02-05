% Quick hack script to plot the time resolution error.
% The data is copied by hand into Matlab, since it consists
% of only 10ish values.


N = [
    1
    2
    4
    5
    10
    20
    25
    50
    100
]; % t=n*T has been used. So N=1 = coarse, N="max" = fine.

CT = [
    0.885096944881
    0.909582855364
    0.921789856976
    0.924783986926
    0.929801715084
    0.932480759426
    0.933370833096
    0.934504136698
    0.935052825503
]; % Speckle contrast: C(T)

CT_C1 = CT/CT(1); % Speckle contrast ratio: CT/C1
MAE_1 = [
    NaN
    NaN
    NaN
    NaN
    NaN
    NaN
    NaN
    NaN
    NaN
]; % MAE  divided by the mean data, relative to T=1
RMSE_1 = [
    NaN
    NaN
    NaN
    NaN
    NaN
    NaN
    NaN
    NaN
    NaN
]; % RMSE divided by the mean data, relative to T=1


Ninv = 100./N;


figure()
plot(N,MAE_1,'k-')
hold on
plot(N,RMSE_1,'k--')
hold off
xlabel('N')
ylabel('error w.r.t. T=1\mu ms')
title('Effect of the used time resolution')
legend('MAE(I)/<I>','RMSE(I)/<I>','location','best')

figure()
loglog(N,MAE_1,'k-')
hold on
loglog(N,RMSE_1,'k--')
hold off
xlabel('N')
ylabel('error w.r.t. T=1\mu ms')
title('Effect of the used time resolution')
legend('MAE(I)/<I>','RMSE(I)/<I>','location','best')

%%% 1/T
figure()
semilogx(Ninv,MAE_1,'k-')
hold on
semilogx(Ninv,RMSE_1,'k--')
hold off
xlabel('T=100/N [\mu ms^{-1}]')
ylabel('error w.r.t. T=1\mu ms')
title('Effect of the used time resolution')
legend('MAE(I)/<I>','RMSE(I)/<I>','location','best')

%%% Relative Speckle Contrast, C/C1

% lin fit
P = polyfit(Ninv,CT_C1,1);
CT_C1_fit = P(1)*Ninv+P(2);
CT_C1_limit = P(1)*0+P(2);

figure()
plot(N,CT_C1,'k.-')
hold on
plot([0,max(N)],[CT_C1_limit CT_C1_limit],'r--')
hold off
xlabel('N')
ylabel('C(N)/C_1')
title('Effect of the used time resolution')

figure()
plot(Ninv,CT_C1,'k.-')
hold on
plot(Ninv,CT_C1_fit,'r-')
hold off
xlabel('T=100/N [\mu ms^{-1}]')
ylabel('C(T)/C_1')
title('Effect of the used time resolution')


%%% Speckle Contrast, C

% lin fit
P = polyfit(Ninv,CT,1);
CT_fit = P(1)*Ninv+P(2);
CT_limit = P(1)*0+P(2)

figure()
plot(N,CT,'k.-')
hold on
plot([0,max(N)],[CT_limit CT_limit],'r--')
hold off
xlabel('N')
ylabel('C(N)')
title('Effect of the used time resolution')

figure()
plot(Ninv,CT,'k.-')
hold on
plot(Ninv,CT_fit,'r-')
hold off
xlabel('T=100/N [\mu ms^{-1}]')
ylabel('C(T)')
title('Effect of the used time resolution')

%%% Error in Speckle Contrast, C/C_extrapolated

figure()
plot(N,CT/CT_limit,'k.-')
hold on
plot([0,max(N)],[1 1],'r--')
hold off
xlabel('N')
ylabel('C(N)/C(\infty)')
title('Effect of the used time resolution')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% CT_Cmax = [
%     0.996890965419
%     0.997867471111
%     0.998106547974
%     0.999395657164
%     0.998967640096
%     0.999473101265
%     0.999793347336
%     1
%     ]; % Speckle contrast relation: C(T)/C(Tmax)
% MAE_max = [
%     1.75727684325
%     1.64678955304
%     1.54279846272
%     1.35108021754
%     1.26300916505
%     1.02414455869
%     0.638320266284
%     0
% ]; % MAE  divided by the mean data, relative to T=Tmax
% RMSE_max = [
%     2.54689344268
%     2.38664280916
%     2.23591795772
%     1.95786809731
%     1.83037741944
%     1.48419897604
%     0.925010260351
%     0
% ]; % RMSE divided by the mean data, relative to T=Tmax

% figure()
% plot(T,MAE_max,'k-')
% hold on
% plot(T,RMSE_max,'k--')
% hold off
% xlabel('T [\mu s]')
% ylabel('error w.r.t. T=30\mu s')
% title('Effect of the used time resolution')
% legend('MAE(I)/<I>','RMSE(I)/<I>','location','best')

% figure()
% plot(T,CT_Cmax,'k-')
% xlabel('T [\mu s]')
% ylabel('C(T)/C(T_{max})')
% title('Effect of the used time resolution')



