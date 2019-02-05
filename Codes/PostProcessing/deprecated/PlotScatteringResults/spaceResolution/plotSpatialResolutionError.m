% Quick hack script to plot the space resolution error.
% The data is copied by hand into Matlab, since it consists
% of only 10ish values.


N = [
    257
    129
    65
    33
    17
    9
    5
    3
    2
]; % Number of spatial grid points in one direction. High value = fine mesh.

% N     C               C_gc            C_interpolated      C_interpolated_gc
% 257   1.07412263048   0.997780347784  0.785887067078      0.705956805443
% 129   1.07040128001   0.987265931578  0.77673934045       0.69784249589
% 65    1.08323480274   0.987961286973  0.795621305175      0.699579659163
% 33    1.09634702557   0.958148133525  0.802427967168      0.68231044196
% 17    1.06261412372   0.908388322781  0.790352625807      0.637280290953
% 9     1.10563038115   0.823266599257  0.902151791378      0.598496204997
% 5     0.89301513759   0.581336281831  0.660139215474      0.403995818748
% 3     1.03215321539   0.61636297666   0.742987188203      0.390611151383
% 2     0.853162172912  0.60623066298   0.632691008105      0.433236152176

% CT = [
%     0.705956805443
%     0.69784249589
%     0.699579659163
%     0.68231044196
%     0.637280290953
%     0.598496204997
%     0.403995818748
%     0.390611151383
%     0.433236152176
% ]; % Speckle contrast: C(T) for "smallViewAngle" = 6 degrees case

CT = [
    0.996838098224
    0.995471781554
    0.989074385814
    0.957463162448
    1.03918701151
    1.01748445191
    0.932295054476
    0.896232312278
    0.89617340749
]; % Speckle contrast: C(T) for "view0.10deg" case
asymValue=1;

CT_C1 = CT/CT(1); % Speckle contrast ratio: CT/C1

Ninv = 1./N;



%%% Relative Speckle Contrast, C/C1

% lin fit
P = polyfit(Ninv(1:6),CT_C1(1:6),1);
CT_C1_fit = P(1)*Ninv+P(2);
CT_C1_limit = P(1)*0+P(2);

figure()
plot(N,CT_C1,'k.-')
hold on
plot([0,max(N)],[CT_C1_limit CT_C1_limit],'r--')
hold off
xlabel('N')
ylabel('C/C_1')
title('Effect of the used spatial resolution')

figure()
plot(Ninv,CT_C1,'k.-')
hold on
plot(Ninv,CT_C1_fit,'r-')
hold off
xlabel('1/N')
ylabel('C/C_1')
title('Effect of the used spatial resolution')


%%% Speckle Contrast, C

% lin fit
P = polyfit(Ninv(1:6),CT(1:6),1);
CT_fit = P(1)*Ninv+P(2);
CT_limit = P(1)*0+P(2)

figure()
plot(N,CT,'k.-')
hold on
if(exist('asymValue','var'))
    plot([0,max(N)],[asymValue asymValue],'r--')
else
    plot([0,max(N)],[CT_limit CT_limit],'r--')
end
hold off
xlabel('N')
ylabel('C')
title('Effect of the used spatial resolution')

figure()
plot(Ninv,CT,'k.-')
hold on
plot(Ninv,CT_fit,'r-')
hold off
xlabel('1/N')
ylabel('C')
title('Effect of the used spatial resolution')

%%% Error in Speckle Contrast, C/C_extrapolated

figure()
if(exist('asymValue','var'))
    plot(N,CT/asymValue,'k.-')
else
    plot(N,CT/CT_limit,'k.-')
end
hold on
plot([0,max(N)],[1 1],'r--')
hold off
xlabel('N')
ylabel('C/C(\infty)')
title('Effect of the used spatial resolution')


clear asymValue
