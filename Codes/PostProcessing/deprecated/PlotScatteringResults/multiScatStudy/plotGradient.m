% Quick hack script to plot the observed gradient for several particle
% radii.
% The data is copied by hand into Matlab, since it consists
% of only 10ish values.






%%% Normal

figure()
h1 = plot(blin,gradData.p1,'k:');
hold on
h300 = plot(blin,gradData.p300,'k-');
hold off
title('Effect of the scattering order on observed gradient')
set(gca, 'Xdir', 'reverse')
xlabel(blabel)
ylabel('Mean Intensity')
legend([h1 h300], {'p=1','p=300'},'Location','best')


%%% Difference



figure()
plot(blin,(gradData.p300-gradData.p1)/mean(gradData.p300),'k-');
title('Effect of the scattering order on observed gradient')
set(gca, 'Xdir', 'reverse')
xlabel(blabel)
ylabel('Mean Intensity Difference Ratio')




