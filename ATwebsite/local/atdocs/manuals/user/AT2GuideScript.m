%Script for Guide to AT 2.0
close all; clear all; %refresh your Matlab session

%%%%% Section 2: Creation of Elements and Lattices  %%%%%%
%First we create a quadrupole element
QF=atquadrupole('QF',0.5,1.2,'QuadMPoleFringePass');

disp(QF); %Let's have a look at this element to understand AT elements.

% Now we create the other elements need for a FODO lattice
Dr=atdrift('Dr',0.5);
HalfDr=atdrift('Dr',0.25);
QD=atquadrupole('QD',0.5,-1.2,'QuadMPoleFringePass');
Bend=atsbend('Bend',1,2*pi/40,'PassMethod','BndMPoleSymplectic4Pass','Energy',3e9);

%Put these elements together into a cell array to make a FODO cell.
FODOcell=[{HalfDr};{Bend};{Dr};{QF};{Dr};{Bend};{Dr};{QD};{HalfDr}];

%Now repeat 20 times to get the full ring.
FODO=repmat(FODOcell,20,1);

%%%%% Section 3: Lattice Querying and Manipulation  %%%%%%
QFIndices = findcells(FODOcell,'FamName','QF');
disp(QFIndices);
QuadIndices = findcells(FODO,'Class','Quadrupole');
disp(QuadIndices);
%for more information on findcells:
help findcells;

%now we use get getcellstruct and setcellstruct
Kvals=getcellstruct(FODO,'PolynomB',QuadIndices,2);
Kvalserr=Kvals+0.2*(rand(length(Kvals),1)-0.5);
FODOerr=setcellstruct(FODO,'PolynomB',QuadIndices,Kvalserr,2);

quadspos=findspos(FODO,QuadIndices);
plot(quadspos,Kvals,'*r',quadspos,Kvalserr,'*b');
xlabel('s (m)');
ylabel('Kval (1/m)');
legend('FODO','FODOerr');
 export_fig('quadplot.pdf','-transparent');

%%%%% Section 4: Tracking  %%%%%%
nturns=200;
Z01=[.001;0;0;0;0;0];
Z02=[.002;0;0;0;0;0];
Z03=[.003;0;0;0;0;0];
Z1=ringpass(FODO,Z01,nturns);
Z2=ringpass(FODO,Z02,nturns);
Z3=ringpass(FODO,Z03,nturns);
plot(Z1(1,:),Z1(2,:),'.r',Z2(1,:),Z2(2,:),'.b',Z3(1,:),Z3(2,:),'.k')
xlabel('x (m)');
ylabel('xp (rad)');
legend('1 mm','2 mm','3 mm');
 export_fig('trackPlot.pdf','-transparent');
 %now with multiple initial conditions passed to ringpass
 Z0=[.001;0;0;0;0;0]*(1:3);
 Z200=ringpass(FODO,Z0,nturns);
 %examine Z200:
 whos Z200
 
 
 ZZ1=Z200(:,1:3:3*nturns);
 ZZ2=Z200(:,2:3:3*nturns);
 ZZ3=Z200(:,3:3:3*nturns);
 figure
 plot(ZZ1(1,:),ZZ1(2,:),'.r',ZZ2(1,:),ZZ2(2,:),'.b',ZZ3(1,:),ZZ3(2,:),'.k')
xlabel('x (m)');
ylabel('xp (rad)');
legend('1 mm','2 mm','3 mm');
%and one more approach, using the reshape command
ZZ200=reshape(Z200,6,3,nturns);
ZZZ1=ZZ200(:,1,:);
ZZZ2=ZZ200(:,2,:);
ZZZ3=ZZ200(:,3,:);
 figure
 plot(ZZZ1(1,:),ZZZ1(2,:),'.r',ZZZ2(1,:),ZZZ2(2,:),'.b',ZZZ3(1,:),ZZZ3(2,:),'.k')
xlabel('x (m)');
ylabel('xp (rad)');
legend('1 mm','2 mm','3 mm');

%%%%% Section 5: Computation of beam parameters  %%%%%%

%compute linear optics parameters for FODO lattice
[param,t,c]=atlinopt(FODO,0,1);
t,c

%Now we see the use of atfittune
FODO2=atfittune(FODO,[0.15,0.75],'QF','QD');
[param2,t2,c2]=atlinopt(FODO2,0,1);
t2
%call atfittune again to get a better result
FODO2=atfittune(FODO2,[0.15,0.75],'QF','QD');
[param2,t2,c2]=atlinopt(FODO2,0,1); t2

%Next we add Sextupoles for chromaticity correction
SF=atsextupole('SF',0.1,1);
SD=atsextupole('SD',0.1,-1);
p2Dr=atdrift('Dr',0.2);

FODOcellSext=[{HalfDr};{Bend};{p2Dr};{SF};{p2Dr};{QF};{Dr};{Bend};{p2Dr};{SD};{p2Dr};{QD};{HalfDr}];
FODOSext=repmat(FODOcellSext,20,1);

%Now set the sextupole values to fit the chromaticity
FODOSext=atfittune(FODOSext,[0.15,0.75],'QF','QD');
FODOSext=atfittune(FODOSext,[0.15,0.75],'QF','QD');
FODOSext=atfitchrom(FODOSext,[0.5 0.5],'SF','SD');
FODOSext=atfitchrom(FODOSext,[0.5 0.5],'SF','SD');

[paramS,tS,cS]=atlinopt(FODOSext,0,1);tS,cS

%Now compute linear lattice parameters at all points in the lattice
[paramAll,t2,c2]=atlinopt([FODOcellSext;FODOcellSext],0,1:length([FODOcellSext;FODOcellSext])+1);
paramAll

%Now, let's plot the beta functions around the ring.
beta=cat(1,paramAll.beta);
betax=beta(:,1);
betay=beta(:,2);
spos=cat(1,paramAll.SPos);
figure
plot(spos,betax,'-r',spos,betay,'-b');
xlabel('s (m)');
ylabel('beta (m)');
legend('betax','betay');
export_fig('FODOBetaplot.pdf','-transparent');

%now plot using atplot
figure
atplot([FODOcellSext;FODOcellSext]);
export_fig('FODOatplot.pdf','-transparent');

%Now add RF cavity
RFC=atrfcavity('RFCav');

FODOSextRF=[{RFC};FODOSext];
FODOSextRF=atsetcavity(FODOSextRF,5e5,0,100);

RFC=atrfcavity('RFCav');

FODOSextRF=[{RFC};FODOSext];
FODOSextRF=atsetcavity(FODOSextRF,5e5,0,100);
[BEAMDATA,PARAMS]=atx(FODOSextRF);
disp(PARAMS)