%Comparing undrained cyclic results to Seiji's results

clear all

Analysis_case = 'undrained_cyclic';

%0.0689, 0.0806, 0.1339
my_csr = 0.0689;

%0.106,0.124, 0.206
seiji_csr = 0.106; 
file_csr = num2str(seiji_csr*1000);

%opensees frequency 
period      = .1;

numcycles = 43;

consol = 500;
loadsteps = numcycles*period/0.01;
endofloading = consol + loadsteps + 1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Loading OpenSEES files
DISP_1      = load(['output/dispx.out']);
DISP_2      = load(['output/dispy.out']);
ACC_1       = load(['output/accx.out']);
ACC_2       = load(['output/accy.out']);
STRESS    = load(['output/stress9.out']);
STRAIN    = load(['output/strain9.out']);
PWP      = load(['output/pwp.out']);
BACKBONE  = load(['output/backbone.out']);

%time
ostime  = PWP(:,1);
oscycle = ostime/period;
% # of steps in "consolidation pattern"
consol_step = 500;
total_step  = size(PWP,1);

%loading the data from the output files into arrays
disp_1 = DISP_1(:,2:end);
disp_2 = DISP_2(:,2:end);
acc_1 = ACC_1(:,2:end);
acc_2 = ACC_2(:,2:end);

% Stresses  compression:+   tension:-
%Note: I found that the stresses are already effective. no need to subtract
%PWP
s_11  = -STRESS(:,2);
s_22  = -STRESS(:,3);
s_33  = -STRESS(:,4);
s_12  = STRESS(:,5);
eta   = STRESS(:,6);  % defined in the manual - not used

% Strains   Upward (dilation):-   Downward (contraction):+
e_11  = -STRAIN(:,2);
e_22  = -STRAIN(:,3);
gama_12 = STRAIN(:,4);
e_33  = zeros(size(e_11));       % plain strain
e_v   = e_11 + e_22 + e_33;      % e_33 is zero
gama_oct = 2/3*sqrt((e_11-e_22).^2+(e_22-e_33).^2+(e_11-e_33).^2+6*(gama_12/2).^2); % I assumed that in the Octahedral strain formulation e_12 = 1/2*gama_12 (I think this is correct)

%octahedral shear stress
tau_oct  = 1/3*sqrt((s_11-s_22).^2 + (s_11-s_33).^2 + (s_22-s_33).^2 + 6*s_12.^2); 
%deviatoric effective stress
q     = 3/sqrt(2)*tau_oct; 
%averaging the pwp among the four nodes
pwp   = (PWP(:,2)+PWP(:,3)+PWP(:,4)+PWP(:,5))/4;
%sigma prime mean
p     = (s_11 + s_22 + s_33)/3;
%sigma total (sigma prime + pwp)
p_tot = p + pwp;

% Ru
p1 = max(p,0.001); %max sigma prime mean
p2 = p(consol_step); %sigma prime mean at consol
p3 = s_22(consol_step); %vertical effective stress at consol
ru_1 = pwp./p1;
ru_2 = pwp/p2;
ru_3 = pwp/p3;

ru_3_end = ru_3(endofloading)
defo_end = DISP_2(end,4) - DISP_2(500,4)
strain_end = e_v(end) - e_v(500)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Loading Seiji's file    
filename = 'Seiji_0106.xlsx';
seiji_data = xlsread(filename);
seiji_freq = 0.1; %cycles/sec
seiji_cycle     = seiji_data(:,1);
seiji_time      = seiji_cycle/seiji_freq;
seiji_shear     = seiji_data(:,2); % shear strain in percent
seiji_shear     = seiji_shear/100; % convert to decimal
seiji_cyclic    = seiji_data(:,3); % cyclic stress kN/m2
seiji_axial     = seiji_data(:,4); % axial strain in percent
seiji_epwp      = seiji_data(:,5); % delta u kN/m2
seiji_ru        = seiji_data(:,6); % ru
seiji_CSR       = seiji_data(:,7); % CSR during the test
seiji_sigmad    = seiji_data(:,9); % deviator stress kN/m2
seiji_sigmaa    = seiji_data(:,10); %axial stress
seiji_p         = seiji_data(:,11); %mean effective stress kN/m2

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%locating the NumCycles to 1.5, 3, and 7.5% double amplitude shear strains
%in the openSEES data
os_T_r = 0;
os_T_1 = consol_step+1;
os_T_3 = consol_step+1;
os_T_7 = consol_step+1;

os_T_r = find(ru_3>0.95,1);
if any(os_T_r) == 0
    os_T_r = consol_step+1;
end
os_N_r = oscycle(os_T_r)

%finding peak to peak strain values
j = 1;
slopea = gama_12(2:length(gama_12));
slopeb = gama_12(1:length(gama_12)-1);
slope = slopeb - slopea;
for i = consol_step+1:total_step-1;
    if slope(i) == 0
        peaks(j,1) = gama_12(i);
        peaks(j,2) = i;
        j = j+1;
    elseif (sign(slope(i-1)) == 1) && (sign(slope(i)) == -1)
        peaks(j,1) = gama_12(i);
        peaks(j,2) = i;
        j = j+1;
    elseif (sign(slope(i-1)) == -1) && (sign(slope(i)) == 1)
        peaks(j,1) = gama_12(i);
        peaks(j,2) = i;
        j = j+1;
    end
end




for i = length(peaks):-1:2
    diff = abs(peaks(i,1) - peaks(i-1,1));
    if diff > 0.015
        os_T_1 = round(0.5*(peaks(i,2) + peaks(i-1,2)));
    end
    if diff > 0.03
        os_T_3 = round(0.5*(peaks(i,2) + peaks(i-1,2)));
    end
    if diff > 0.075
        os_T_7 = round(0.5*(peaks(i,2) + peaks(i-1,2)));
    end
end

os_N_1 = oscycle(os_T_1)
os_N_3 = oscycle(os_T_3)
os_N_7 = oscycle(os_T_7)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%locating the NumCycles to 1.5, 3, and 7.5% double amplitude shear strains
%in Seiji's data
sk_T_r = 0;
sk_T_1 = 0;
sk_T_3 = 0;
sk_T_7 = 0;
clear slopea;
clear slopeb;
clear slope;
clear peaks;

sk_T_r = find(seiji_ru >0.95,1);
sk_N_r = seiji_cycle(sk_T_r)

%finding peak to peak strain values
j = 1;
slopea = seiji_shear(2:length(seiji_shear));
slopeb = seiji_shear(1:length(seiji_shear)-1);
slope = slopeb - slopea;
for i = 2:length(slope)-1;
    if slope(i) == 0
        peaks(j,1) = seiji_shear(i);
        peaks(j,2) = i;
        j = j+1;
    elseif (sign(slope(i-1)) == 1) && (sign(slope(i)) == -1)
        peaks(j,1) = seiji_shear(i);
        peaks(j,2) = i;
        j = j+1;
    elseif (sign(slope(i-1)) == -1) && (sign(slope(i)) == 1)
        peaks(j,1) = seiji_shear(i);
        peaks(j,2) = i;
        j = j+1;
    end
end

for i = length(peaks):-1:2
    diff = abs(peaks(i,1) - peaks(i-1,1));
    if diff > 0.015
        sk_T_1 = round(0.5*(peaks(i,2) + peaks(i-1,2)));
    end
    if diff > 0.03
        sk_T_3 = round(0.5*(peaks(i,2) + peaks(i-1,2)));
    end
    if diff > 0.075
        sk_T_7 = round(0.5*(peaks(i,2) + peaks(i-1,2)));
    end
end

sk_N_1 = seiji_cycle(sk_T_1)
sk_N_3 = seiji_cycle(sk_T_3)
sk_N_7 = seiji_cycle(sk_T_7)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%make figures

figure(1)
plot(oscycle(consol_step+1:end),ru_3(consol_step+1:end),'red');hold on; grid on;
plot(seiji_cycle,seiji_ru,'black');
xlabel('No. of cycles');ylabel('ru');ylim([0,1.0]);
legend('OpenSEES ru_3 = pwp/\sigma''_{vc}','Seiji''s Data',4);
plot(os_N_1,ru_3(os_T_1),'g.','MarkerSize',15);
plot(os_N_3,ru_3(os_T_3),'r.','MarkerSize',15);
plot(os_N_7,ru_3(os_T_7),'k.','MarkerSize',15);
plot(os_N_r,ru_3(os_T_r),'m.','MarkerSize',15);
plot(sk_N_1,seiji_ru(sk_T_1),'go','MarkerSize',10);
plot(sk_N_3,seiji_ru(sk_T_3),'ro','MarkerSize',10);
plot(sk_N_7,seiji_ru(sk_T_7),'ko','MarkerSize',10);
plot(sk_N_r,seiji_ru(sk_T_r),'mo','MarkerSize',10);

figure(2)
plot(oscycle(consol_step+1:end),gama_12(consol_step+1:end),'red');hold on;grid on;
plot(seiji_cycle,seiji_shear,'black');
legend('OpenSEES', 'Seiji''s Data');
plot(os_N_1,gama_12(os_T_1),'g.','MarkerSize',15);
plot(os_N_3,gama_12(os_T_3),'r.','MarkerSize',15);
plot(os_N_7,gama_12(os_T_7),'k.','MarkerSize',15);
plot(os_N_r,gama_12(os_T_r),'m.','MarkerSize',15);
plot(sk_N_1,seiji_shear(sk_T_1),'go','MarkerSize',10);
plot(sk_N_3,seiji_shear(sk_T_3),'ro','MarkerSize',10);
plot(sk_N_7,seiji_shear(sk_T_7),'ko','MarkerSize',10);
plot(sk_N_r,seiji_shear(sk_T_r),'mo','MarkerSize',10);
xlabel('No. of cycles');
ylabel('\gamma_{12}');

figure(3)
plot(gama_12,s_12/s_22(consol_step),'red');grid on; hold on;
plot(seiji_shear,seiji_CSR,'black');
legend('OpenSEES', 'Seiji''s Data');
xlabel('\gamma_{12}');
ylabel('CSR = (\sigma_{12}/\sigma''_{vc})')
plot(gama_12(os_T_1),s_12(os_T_1)/s_22(consol_step),'g.','MarkerSize',15);
plot(gama_12(os_T_3),s_12(os_T_3)/s_22(consol_step),'r.','MarkerSize',15);
plot(gama_12(os_T_7),s_12(os_T_7)/s_22(consol_step),'k.','MarkerSize',15);
plot(gama_12(os_T_r),s_12(os_T_r)/s_22(consol_step),'m.','MarkerSize',15);
plot(seiji_shear(sk_T_1),seiji_CSR(sk_T_1),'go','MarkerSize',10);
plot(seiji_shear(sk_T_3),seiji_CSR(sk_T_3),'ro','MarkerSize',10);
plot(seiji_shear(sk_T_7),seiji_CSR(sk_T_7),'ko','MarkerSize',10);
plot(seiji_shear(sk_T_r),seiji_CSR(sk_T_r),'mo','MarkerSize',10);

