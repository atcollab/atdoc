Z0=[.001;0;0;0;0;0];
Z1=ringpass(ring,Z0,100);
plot(Z1(1,:),Z1(2,:),'.r');
xlabel('x (m)');
ylabel('xp (rad)');
export_fig('trackPlot.pdf','-transparent');