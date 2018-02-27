%tracking script
CreateSimpleFODO

Z0=[.001;0;0;0;0;0]*1:15;
Z50=ringpass(ring,Z0,50);
plot(Z50(1,:),Z50(2,:),'.')