function flaviaWriter()
% creates GiD post-processing results file from OpenSees data

fid = fopen('freeFieldEffective.flavia.res','w');

fprintf(2,'* %s\n','Creating flavia.res from FEA. THIS MAY TAKE A FEW MINUTES ...')

fprintf(fid,'GiD Post Results File 1.0 \n\n');

%----------------------DISPLACEMENT-----------------------------------

% node pointer
nodePtr = load('nodesInfo.dat');

% displacement data files
% gdisp = load('Gdisplacement.out');
pdisp = load('displacement.out');

% adjust times on gravity analysis
% gdisp(:,1) = disp(:,1);

% combine into a single array
% disp = [gdisp;pdisp];
disp = pdisp;

% transformation to GiD format
time = disp(:,1);
disp(:,1) = [];
% clear gdisp pdisp
clear pdisp

[nStep,nDisp] = size(disp);
nNode = nDisp/2;

for k = 1:nStep
    fprintf(fid,'Result "a.  Nodal Displacements" "Loading_Analysis"\t%12.5g Vector OnNodes\n', time(k));
		fprintf(fid,'ComponentNames "X-Displacement"  "Y-Displacement"\n');
		fprintf(fid,'Values\n');

    u = reshape(disp(k,:), 2, nNode);
    for j = 1:nNode
        fprintf(fid, '%d \t %-12.8e %-12.8e\n', nodePtr(j), u(:,j));
    end
    fprintf(fid,'End Values \n');
	fprintf(fid,' \n');
end

clear disp

fprintf(2,'* %s\n','Done with displacements ...') 

%----------------------PORE PRESSURE----------------------------------

% pore pressure data files
% gpwp = load('GporePressure.out');
ppwp = load('porePressure.out');

% adjust time on gravity analysis
% gpwp(:,1) = gpwp(:,1);

% combine into single array
% pwp = [gpwp;ppwp];
pwp = ppwp;
% clear gpwp ppwp
clear ppwp;

% transformation to GiD format
time = pwp(:,1);
pwp(:,1) = [];

for k = 1:nStep
    fprintf(fid,'Result "a.  Nodal PorePressures" "Loading_Analysis"\t%12.5g Scalar OnNodes\n', time(k));
		fprintf(fid,'ComponentNames "Pore Pressure"\n');
		fprintf(fid,'Values\n');

    for j = 1:nNode
        fprintf(fid, '%d \t %-12.8e\n', nodePtr(j), pwp(k,j));
    end
    fprintf(fid,'End Values \n');
	fprintf(fid,' \n');
end

fprintf(2,'* %s\n','Done with porePressures ...')

%----------------------PORE PRESSURE RATIO----------------------------

% load elemental data from center gaussPt
stress = load('Gstress.out');
stress(:,1) = [];
stress = stress(1,:)';
[m,n] = size(stress);
nElem = m/5;
sig = reshape(stress, 5, nElem);
clear stress

% write stress as 6x1 tensor representation
sten = zeros(6,nElem);
for k = 1:nElem
	for j = 1:4
		sten(j,k) = sig(j,k);
	end
end
clear sig
% trace of stress
I1 = zeros(nElem,1);
for k = 1:nElem
	I1(k) = sum(sten(1:3,k),1);
end
% mean stress
mStress = -I1/3;
clear I1

% average stresses at nodal depths
P = zeros(nElem-1,1);
sigV = P;
for k = 1:(nElem-1)
	P(k) = (mStress(k)+mStress(k+1))/2;
    sigV(k) = (sten(2,k)+sten(2,k+1))/2;
end

% location of mean stress values
vInfo = sort(unique(nodePtr(:,3)),'ascend');
% vertical element size
vsize = vInfo(1)-vInfo(2);

% extrapolate first and last points
f = mStress(1) - ((mStress(2)-mStress(1))/vsize)*(vsize/2);
l = mStress(end) + ((mStress(end)-mStress(end-1))/vsize)*(vsize/2);
P = [f;P;l];
f = sten(2,1) - ((sten(2,2)-sten(2,1))/vsize)*(vsize/2);
l = sten(2,end) - ((sten(2,end) - sten(2,end-1))/vsize)*(vsize/2);
sigV = [f;sigV;l];
clear mStress

% excess pore pressure
for k = 1:nStep
	exPwp(k,:) = abs(pwp(k,:) - pwp(1,:));
end

id1 = abs(exPwp)<1e-6;
exPwp(id1) = 0.0;

% compute pore pressure ratio
ru = zeros(nStep,nNode);
ru2 = ru;
for k = 1:nNode
    for j = 1:length(P)
        if (nodePtr(k,3)==vInfo(j))
            ru(:,k) = exPwp(:,k)/abs(P(j));
            ru2(:,k) = exPwp(:,k)/abs(sigV(j));
            break
        end
    end
end

clear P exPwp

% transformation to GiD format
for k = 1:nStep
    fprintf(fid,'Result "a.  PorePressureRatio (mean stress)" "Loading_Analysis"\t%12.5g Scalar OnNodes\n', time(k));
		fprintf(fid,'ComponentNames "Pore Pressure Ratio (mean stress)"\n');
		fprintf(fid,'Values\n');

    for j = 1:nNode
        fprintf(fid, '%d \t %-12.8e\n', nodePtr(j), ru(k,j));
    end
    fprintf(fid,'End Values \n');
	fprintf(fid,' \n');
end

for k = 1:nStep
    fprintf(fid,'Result "a.  PorePressureRatio (vertical stress)" "Loading_Analysis"\t%12.5g Scalar OnNodes\n', time(k));
		fprintf(fid,'ComponentNames "Pore Pressure Ratio (vertical stress)"\n');
		fprintf(fid,'Values\n');

    for j = 1:nNode
        fprintf(fid, '%d \t %-12.8e\n', nodePtr(j), ru2(k,j));
    end
    fprintf(fid,'End Values \n');
	fprintf(fid,' \n');
end


fprintf(2,'* %s\n','Done with porePressureRatio ...')

%------------------------STRESS---------------------------------------

% load and combine data
% gstress = load('Gstress.out');
% gstress(:,1) = [];
pstress = load('stress.out');
pstress(:,1) = [];
% stress = [gstress;pstress];
stress = pstress;

clear pstress
% clear gstress pstress

[nStep,nStress] = size(stress);
nElem = nStress/5;

for k = 1:nStep
    fprintf(fid,'GaussPoints "stress" ElemType Quadrilateral\n');
	fprintf(fid,'Number of Gauss Points: 1\n');
	fprintf(fid,'Natural Coordinate: Internal\n');
	fprintf(fid,'End Gausspoints\n\n');
	fprintf(fid,'Result "Gauss Point Stress" "Loading_Analysis"\t%12.5g', time(k));
    fprintf(fid,'\tPlainDeformationMatrix OnGaussPoints "stress"\n');
	fprintf(fid,'Values\n');

    gp = reshape(stress(k,:), 5, nElem);
    

    for j = 1:nElem
        fprintf(fid,'%6.0f  ', j);
        fprintf(fid,'%12.6g %12.6g %12.6g\n', gp(1,j), gp(2,j), gp(4,j));
	end
	fprintf(fid,'End Values \n');
	fprintf(fid,'\n');
end

clear stress gp

fprintf(2,'* %s\n','Done with stress ...')

%------------------------STRAIN---------------------------------------

% load and combine data
% gstrain = load('Gstrain.out');
% gstrain(:,1) = [];
pstrain = load('strain.out');
pstrain(:,1) = [];
% strain = [gstrain;pstrain];
strain = pstrain;


% clear gstrain pstrain
clear pstrain

[nStep,nstrain] = size(strain);
nElem = nstrain/3;

for k = 1:nStep
    fprintf(fid,'GaussPoints "strain" ElemType Quadrilateral\n');
	fprintf(fid,'Number of Gauss Points: 1\n');
	fprintf(fid,'Natural Coordinate: Internal\n');
	fprintf(fid,'End Gausspoints\n\n');
	fprintf(fid,'Result "Gauss Point Strain" "Loading_Analysis"\t%12.5g', time(k));
    fprintf(fid,'\tPlainDeformationMatrix OnGaussPoints "strain"\n');
	fprintf(fid,'Values\n');

    gp = reshape(strain(k,:), 3, nElem);
    

    for j = 1:nElem
        fprintf(fid,'%6.0f  ', j);
        fprintf(fid,'%12.6g %12.6g %12.6g\n', gp(1,j), gp(2,j), gp(3,j));
	end
	fprintf(fid,'End Values \n');
	fprintf(fid,'\n');
end

clear strain gp

fprintf(2,'* %s\n','Done with strain ...')

fclose(fid);

return
