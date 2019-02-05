% Quick hack script to plot the observed gradient for several particle
% radii.
% The data is copied by hand into Matlab, since it consists
% of only 10ish values.






%%% Normal

figure()
h1 = plot(blin,gradData.a1em6,'b:','LineWidth',2);
hold on
h2 = plot(blin,gradData.a2em6,'k-');
h3 = plot(blin,gradData.a3em6,'k-');
h4 = plot(blin,gradData.a4em6,'k-');
h5 = plot(blin,gradData.a5em6,'k-');
h6 = plot(blin,gradData.a6em6,'k-');
h7 = plot(blin,gradData.a7em6,'k-');
h8 = plot(blin,gradData.a8em6,'k-');
h9 = plot(blin,gradData.a9em6,'k-');
h10 = plot(blin,gradData.a10em6,'g:','LineWidth',2);
h11 = plot(blin,gradData.a11em6,'k-');
h12 = plot(blin,gradData.a12em6,'k-');
h13 = plot(blin,gradData.a13em6,'k-');
h14 = plot(blin,gradData.a14em6,'k-');
h15 = plot(blin,gradData.a15em6,'k-');
h16 = plot(blin,gradData.a16em6,'k-');
h17 = plot(blin,gradData.a17em6,'k-');
h18 = plot(blin,gradData.a18em6,'k-');
h19 = plot(blin,gradData.a19em6,'k-');
h20 = plot(blin,gradData.a20em6,'y:','LineWidth',2);
hmean = plot(blin,gradData.amean,'r-','LineWidth',3);
hold off
title('Effect of the particle radius on observed gradient')
set(gca, 'Xdir', 'reverse')
xlabel(blabel)
ylabel('Mean Intensity')
legend([h1 h10 h20 hmean], {'a=1{\mu}m','a=10{\mu}m','a=20{\mu}m','<a>'},'Location','best')


%%% Mean normalised

figure()
h1 = plot(blin,gradData.a1em6/mean(gradData.a1em6),'b:','LineWidth',2);
hold on
h2 = plot(blin,gradData.a2em6/mean(gradData.a2em6),'k:');
h3 = plot(blin,gradData.a3em6/mean(gradData.a3em6),'k:');
h4 = plot(blin,gradData.a4em6/mean(gradData.a4em6),'k:');
h5 = plot(blin,gradData.a5em6/mean(gradData.a5em6),'k:');
h6 = plot(blin,gradData.a6em6/mean(gradData.a6em6),'k:');
h7 = plot(blin,gradData.a7em6/mean(gradData.a7em6),'k:');
h8 = plot(blin,gradData.a8em6/mean(gradData.a8em6),'k:');
h9 = plot(blin,gradData.a9em6/mean(gradData.a9em6),'k:');
h10 = plot(blin,gradData.a10em6/mean(gradData.a10em6),'g:','LineWidth',2);
h11 = plot(blin,gradData.a11em6/mean(gradData.a11em6),'k:');
h12 = plot(blin,gradData.a12em6/mean(gradData.a12em6),'k:');
h13 = plot(blin,gradData.a13em6/mean(gradData.a13em6),'k:');
h14 = plot(blin,gradData.a14em6/mean(gradData.a14em6),'k:');
h15 = plot(blin,gradData.a15em6/mean(gradData.a15em6),'k:');
h16 = plot(blin,gradData.a16em6/mean(gradData.a16em6),'k:');
h17 = plot(blin,gradData.a17em6/mean(gradData.a17em6),'k:');
h18 = plot(blin,gradData.a18em6/mean(gradData.a18em6),'k:');
h19 = plot(blin,gradData.a19em6/mean(gradData.a19em6),'k:');
h20 = plot(blin,gradData.a20em6/mean(gradData.a20em6),'y:','LineWidth',2);
hmean = plot(blin,gradData.amean/mean(gradData.amean),'r-','LineWidth',3);
hold off
title('Effect of the particle radius on observed gradient')
set(gca, 'Xdir', 'reverse')
xlabel(blabel)
ylabel('Mean Intensity (normalised)')
legend([h1 h10 h20 hmean], {'a=1{\mu}m','a=10{\mu}m','a=20{\mu}m','<a>'},'Location','best')

