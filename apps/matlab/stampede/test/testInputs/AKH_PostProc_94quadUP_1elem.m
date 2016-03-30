%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Post processor for 9-4quadUP element                  %
% By: Arash Khosravifar    January 2009                 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% clc
clear all
% close all

% Type of analysis. Options:
% undrained_cyclic
% undrained_monotonic
% drained_cyclic
% drained_monotonic
Analysis_case = 'undrained_cyclic';


% Loading files
AKH_ElemDriver_disp1_94quadUP      = load(['output\dispx.out']);
AKH_ElemDriver_disp2_94quadUP      = load(['output\dispy.out']);
AKH_ElemDriver_acc1_94quadUP       = load(['output\accx.out']);
AKH_ElemDriver_acc2_94quadUP       = load(['output\accy.out']);
AKH_ElemDriver_stress_94quadUP    = load(['output\stress9.out']);
AKH_ElemDriver_strain_94quadUP    = load(['output\strain9.out']);
AKH_ElemDriver_pwp_94quadUP       = load(['output\pwp.out']);
AKH_ElemDriver_backbone_94quadUP  = load(['output\backbone.out']);

%loading the data from the output files into arrays
% Displacements
Disp_1 = AKH_ElemDriver_disp1_94quadUP(:,2:end);
Disp_2 = AKH_ElemDriver_disp2_94quadUP(:,2:end);
Acc_1 = AKH_ElemDriver_acc1_94quadUP(:,2:end);
Acc_2 = AKH_ElemDriver_acc2_94quadUP(:,2:end);
% Stresses  compression:+   tension:-
s_11  = -AKH_ElemDriver_stress_94quadUP(:,2);
s_22  = -AKH_ElemDriver_stress_94quadUP(:,3);
s_33  = -AKH_ElemDriver_stress_94quadUP(:,4);
s_12  = AKH_ElemDriver_stress_94quadUP(:,5);
eta   = AKH_ElemDriver_stress_94quadUP(:,6);  % defined in the manual - not used


%octahedral shear stress
tau_oct  = 1/3*sqrt((s_11-s_22).^2 + (s_11-s_33).^2 + (s_22-s_33).^2 + 6*s_12.^2); 

%deviatoric effective stress
q     = 3/sqrt(2)*tau_oct; %1/3*sign(s_12).*sqrt((s_11-s_22).^2 + (s_11-s_33).^2 + (s_22-s_33).^2 + 6*s_12.^2);

%averaging the pwp among the four nodes
pwp   = (AKH_ElemDriver_pwp_94quadUP(:,2)+AKH_ElemDriver_pwp_94quadUP(:,3)+AKH_ElemDriver_pwp_94quadUP(:,4)+AKH_ElemDriver_pwp_94quadUP(:,5))/4;

%sigma prime mean
p     = (s_11 + s_22 + s_33)/3;

%sigma total (sigma prime + pwp)
p_tot = p + pwp;

%time
time  = AKH_ElemDriver_pwp_94quadUP(:,1);

%Note: I found that the stresses are salready effective. no need to subtract
%PWP

% Strains   Upward (dilation):-   Downward (contraction):+
e_11  = -AKH_ElemDriver_strain_94quadUP(:,2);
e_22  = -AKH_ElemDriver_strain_94quadUP(:,3);
gama_12 = AKH_ElemDriver_strain_94quadUP(:,4);
e_33  = zeros(size(e_11));                % plain strain
e_v   = e_11 + e_22 + e_33;      % e_33 is zero
gama_oct = 2/3*sqrt((e_11-e_22).^2+(e_22-e_33).^2+(e_11-e_33).^2+6*(gama_12/2).^2); % I assumed that in the Octahedral strain formulation e_12 = 1/2*gama_12 (I think this is correct)

Greg = s_12./gama_12;
Vs = sqrt(Greg/1.99);
Vs = Vs(501)


% CSL line - not sure where this is used RLH
cs1 = 0.9;
cs2 = 0.02;
cs3 = 0.0;
void_i = 0.76;     % initial void ratio
void = void_i - e_22*(1+void_i);

% # of steps in "consolidation pattern"
consol_step = 500;
total_step  = size(gama_12,1);

% Ru
p1 = max(p,0.001);
p2 = p(consol_step);
p3 = s_22(consol_step);
ru_1 = pwp./p1;
ru_2 = pwp/p2;
ru_3 = pwp/p3;

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(Analysis_case,'drained_cyclic') == 1
    period      = 10;
    cycle       = time/period;

    % G/Gmax
    NoStepsCycle  = 2000;
    NoCycleEach   = 2;
    corr_steps = [consol_step+NoStepsCycle/4:NoStepsCycle*NoCycleEach : consol_step+9*NoStepsCycle*NoCycleEach];
    G_sec = s_12(corr_steps)./gama_12(corr_steps);      %Secant stiffness
    G_max = s_12(consol_step+1)/gama_12(consol_step+1);              %Secant stiffness at the first load incr.
    G_max_oct = tau_oct(consol_step+1)/gama_oct(consol_step+1);      
    % Note that the Gmax,r assigned for the material by the user is not the
    % conventional Gmax (s_12/gama_12), but it is the OCTAHEDRAL one
    % (tau_oct/gama_oct)

    % EPRI 1993
    GratioEPRI6 =  [1,0.98,0.919,0.751,0.519,0.271,0.121,0.045,0.024];  % EPRI1993 for 0-6m corresponding to strain=[0.000003,0.00001,0.00003,0.0001,0.0003,0.001,0.003,0.01,0.03]
    GratioEPRI76 = [1,0.999,0.982,0.9,0.752,0.502,0.282,0.124,0.07];    % EPRI1993 for 36-76m
    gama_EPRI  =  [0.000003,0.00001,0.00003,0.0001,0.0003,0.001,0.003,0.01,0.03];
    gama_EPRI_oct = 2/3*sqrt((e_11(500)-e_22(500)).^2+(e_22(500)-e_33(500)).^2+(e_11(500)-e_33(500)).^2+6*(gama_EPRI/2).^2);

    % Use backbone record
    backbone = AKH_ElemDriver_backbone_94quadUP(1,:)';
    gama_backbone_100_oct = backbone(5:4:end);
    G_backbone_100 = backbone(6:4:end);
    gama_backbone_1600_oct = backbone(7:4:end);
    G_backbone_1600 = backbone(8:4:end);

    % Xi
    for ii = 1:length(corr_steps)
        hysteresis = trapz(gama_12(corr_steps(ii):corr_steps(ii)+NoStepsCycle),s_12(corr_steps(ii):corr_steps(ii)+NoStepsCycle));
        triangle   = 1/2*gama_12(corr_steps(ii))*s_12(corr_steps(ii));
        Xi(ii)     = hysteresis/(4*pi*triangle)*100;    %(%)
    end
    XiEPRI6 =  [0.791,1.27,2.28,4.26,7.75,14.74,22.03,27.12,30.21];     % (%) EPRI1993 for 0-6m corresponding to strain=[0.000003,0.00001,0.00003,0.0001,0.0003,0.001,0.003,0.01,0.03]
    XiEPRI76 = [0.591,0.88,1.271,2.46,4.551,8.34,14.13,21.22,25.31];    % (%) EPRI1993 for 36-76m
    
	% Plots
    figure
    semilogx(gama_12(corr_steps),G_sec/G_max,'-ob','LineWidth',2);
    hold on; grid on;
    semilogx(gama_EPRI,GratioEPRI6,'--r','LineWidth',2);
    semilogx(gama_EPRI,GratioEPRI76,'--r','LineWidth',2);
    xlabel('\gamma_{12}');
    ylabel('G_{sec}/G_{max}');
    legend('PDMY02 - \sigma_{vo}=100 KPa','EPRI1993 0-6m','EPRI1993 36-76m')

    % G/Gmax backbone
    figure
    semilogx(gama_backbone_100_oct,G_backbone_100/G_backbone_100(1),'-og','LineWidth',2);
    hold on;grid on;
    semilogx(gama_backbone_1600_oct,G_backbone_1600/G_backbone_1600(1),'-or','LineWidth',2);
    semilogx(gama_EPRI_oct,GratioEPRI6,'--r','LineWidth',2);
    semilogx(gama_EPRI_oct,GratioEPRI76,'--r','LineWidth',2);
    legend('100 kPa','1600 kPa','EPRI1993 0-6m','EPRI1993 36-76m');
    xlabel('\gamma_{oct}');
    ylabel('G_{sec}/G_{max}');

    % Just for the sake of checking the G/Gmax curve made by OpenSees
    phi = 25.4;
    m = 2*sqrt(3)*sin(phi/180*3.1416)/(3-sin(phi/180*3.1416));
    gama_max_r = 0.1;
    G_max_r = 46.9e3;
    Pr = 100;
    gama_r = m*Pr*gama_max_r/(gama_max_r*G_max_r-m*Pr);
    Calculated_G_backbone_ratio = 1./(1+gama_backbone_100_oct/gama_r*(Pr/100)^0.5);
    semilogx(gama_backbone_100_oct,Calculated_G_backbone_ratio,'-*k','LineWidth',2);


    % Xi
    figure
    semilogx(gama_12(corr_steps),Xi,'-ob','LineWidth',2);
    hold on; grid on;
    semilogx(gama_12(corr_steps),XiEPRI6,'--r','LineWidth',2);
    semilogx(gama_12(corr_steps),XiEPRI76,'--r','LineWidth',2);
    xlabel('\gamma_{12}');
    ylabel('Equivalent damping ratio (%)');
    legend('PDMY02 - \sigma_{vo}=100 KPa','EPRI1993 0-6m','EPRI1993 36-76m')
    
    figure
    subplot(3,2,1);
    xplot_2(gama_12,s_12/s_22(consol_step),'\gamma_{12}','CSR = (\sigma_{12}/\sigma''_{vc})','blue');
    title(['CSR = ',num2str(max(abs(s_12))/s_22(consol_step),2),'   and   \sigma''_{vc} = ',num2str(s_22(consol_step)),' kPa']);

    subplot(3,2,2);
    xplot_2(s_22/s_22(consol_step),s_12/s_22(consol_step),'vertical effective stress ratio (\sigma''_{v}/\sigma''_{vc})','CSR = (\sigma_{12}/\sigma''_{vc})','blue');
    xlim([min(0,min(s_22/s_22(consol_step))),max(s_22)/s_22(consol_step)]);
    title(['CSR = ',num2str(max(abs(s_12))/s_22(consol_step),2),'   and   \sigma''_{vc} = ',num2str(s_22(consol_step)),' kPa']);

    subplot(3,2,3);
    plot(cycle(consol_step+1:end),ru_1(consol_step+1:end),'blue');hold on;grid on;
    plot(cycle(consol_step+1:end),ru_2(consol_step+1:end),'red');
    plot(cycle(consol_step+1:end),ru_3(consol_step+1:end),'green');
    xlabel('No. of cycles');ylabel('ru');ylim([0,1.5]);
    legend('ru_1 = pwp/p''','ru_2 = pwp/p''_{c}','ru_3 = pwp/\sigma''_{vc}',4);

    subplot(3,2,4);
    xplot_2(p(consol_step:end)/p(consol_step),q(consol_step:end),'mean effective stress ratio (p''/p''_c)','q (kPa)','blue');hold on;
    xlim([min(0,min(p/p(consol_step))),max(p/p(consol_step))]);
    title(['p''_{c} = ',num2str(p(consol_step),2),' kPa']);

    subplot(3,2,5);
    plot(pwp);grid on;ylabel('PWP (kPa)');xlabel('Time');

    subplot(3,2,6);
    xplot_2(cycle(consol_step+1:end),gama_12(consol_step+1:end),'No. of cycles','\gamma_{12}','blue');

end;    % (end of drained_cyclic)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(Analysis_case,'undrained_cyclic') == 1
    period      = 5;
    cycle       = time/period;

    % find "Liquefaction Triggering" time
    gama_consol = gama_12(consol_step);
    
    T_r = find(ru_3>0.95,1);
    if any(T_r) == 0
        T_r = consol_step+1;
    end
    N_r = cycle(T_r)
    
%finding peak to peak strain values    
jj = 1;
gama12minus = gama_12(2:length(gama_12));
gama12 = gama_12(1:length(gama_12)-1);
slope = gama12 - gama12minus;
for ii = consol_step+1:total_step-1;
    if slope(ii) == 0
        peaks(jj, 1) = gama_12(ii);
        peaks(jj, 2) = ii;
        jj = jj+1;
    elseif (sign(slope(ii-1)) == 1) && (sign(slope(ii)) == -1)
        peaks(jj, 1) = gama_12(ii);
        peaks(jj, 2) = ii;
        jj = jj+1;
    elseif (sign(slope(ii-1)) == -1) && (sign(slope(ii)) == 1)
        peaks(jj, 1) = gama_12(ii);
        peaks(jj, 2) = ii;
        jj = jj+1;
    end    
end

T_1 = consol_step+1;
T_3 = consol_step+1;
T_7 = consol_step+1;


for ii = length(peaks):-1:2
    diff = abs(peaks(ii,1) - peaks(ii-1,1));
    if diff > 0.01
        T_1 = round(0.5*(peaks(ii,2) + peaks(ii-1,2)));
    end
    if diff > 0.03
        T_3 = round(0.5*(peaks(ii,2) + peaks(ii-1,2)));
    end
    if diff > 0.07
        T_7 = round(0.5*(peaks(ii,2) + peaks(ii-1,2)));
    end    
end

N_1 = cycle(T_1)
N_3 = cycle(T_3)
N_7 = cycle(T_7)
r_plot(:,1) = cycle(consol_step+1:end);
r_plot(:,2) = ru_3(consol_step+1:end);
r_plot(:,3) = gama_12(consol_step+1:end);


% G/Gmax calculations
backbone = AKH_ElemDriver_backbone_94quadUP(1,:)';
gama_backbone = backbone(5:4:end);
G_backbone = backbone(6:4:end);
ggmax = G_backbone/G_backbone(1);


% gama_max = 0.1;
% G_r = 6e4;
% Pr = 101;
% P = 100; %confinement from the backbone curve file
% phi = 0;
% d = 0;
% phirad = phi*3.1416/180;
% c = 37;
% tf = (2*sqrt(2)*sin(phirad)/(3-sin(phirad)))*Pr + (2*sqrt(2)/3)*c;
% gama_r = gama_max/(G_r*gama_max/tf - 1);
% calculated_ggmax = 1./(1 + gama_backbone/gama_r*(Pr/P)^d);
% 
% data_gsec = s_12(consol_step+1:end)./gama_12(consol_step+1:end);
% data_ggmax = data_gsec./G_r;
% data_gama = gama_12(consol_step+1:end);

 
% G/Gmax backbone
figure
semilogx(gama_backbone,ggmax,'-og','LineWidth',2);
hold on;grid on;
% semilogx(gama_backbone,calculated_ggmax,'-*b','LineWidth',2);
% semilogx(data_gama(1:25),data_ggmax(1:25),'-k','LineWidth',2);
% legend('Backbone file','Calculated curve','Data curve');
legend('Backbone file');
xlabel('\gamma_{oct}');
ylabel('G_{sec}/G_{max}');

% Plotting
figure
subplot(3,2,1);
plot(gama_12,s_12/s_22(consol_step));grid on; hold on;
xlabel('\gamma_{12}');
ylabel('CSR = (\sigma_{12}/\sigma''_{vc})')
plot(gama_12(T_1),s_12(T_1)/s_22(consol_step),'g.','MarkerSize',15);
plot(gama_12(T_3),s_12(T_3)/s_22(consol_step),'r.','MarkerSize',15);
plot(gama_12(T_7),s_12(T_7)/s_22(consol_step),'k.','MarkerSize',15);
plot(gama_12(T_r),s_12(T_r)/s_22(consol_step),'m.','MarkerSize',15);
title(['CSR = ',num2str(max(abs(s_12))/s_22(consol_step),2),'   and   \sigma''_{vc} = ',num2str(s_22(consol_step)),' kPa']);
%xlim([-0.1,0.1]);

subplot(3,2,2);
plot(s_22/s_22(consol_step),s_12/s_22(consol_step));grid on; hold on;
xlabel('vertical effective stress ratio (\sigma''_{v}/\sigma''_{vc})');
ylabel('CSR = (\sigma_{12}/\sigma''_{vc})');
plot(s_22(T_1)/s_22(consol_step),s_12(T_1)/s_22(consol_step),'g.','MarkerSize',15);
plot(s_22(T_3)/s_22(consol_step),s_12(T_3)/s_22(consol_step),'r.','MarkerSize',15);
plot(s_22(T_r)/s_22(consol_step),s_12(T_r)/s_22(consol_step),'m.','MarkerSize',15);
%xlim([min(0,min(s_22/s_22(consol_step))),max(s_22)/s_22(consol_step)]);
xlim([0,max(s_22)/s_22(consol_step)]);
title(['CSR = ',num2str(max(abs(s_12))/s_22(consol_step),2),'   and   \sigma''_{vc} = ',num2str(s_22(consol_step)),' kPa']);

subplot(3,2,3);
plot(cycle(consol_step+1:end),ru_1(consol_step+1:end),'blue');hold on;grid on;
plot(cycle(consol_step+1:end),ru_2(consol_step+1:end),'red');
plot(cycle(consol_step+1:end),ru_3(consol_step+1:end),'green');
xlabel('No. of cycles');ylabel('ru');ylim([0,1.0]);
legend('ru_1 = pwp/p''','ru_2 = pwp/p''_{c}','ru_3 = pwp/\sigma''_{vc}',4);
plot(N_1,ru_1(T_1),'g.','MarkerSize',15);
plot(N_3,ru_1(T_3),'r.','MarkerSize',15);
plot(N_7,ru_1(T_7),'k.','MarkerSize',15);
plot(N_r,ru_1(T_r),'m.','MarkerSize',15);
plot(N_1,ru_2(T_1),'g.','MarkerSize',15);
plot(N_3,ru_2(T_3),'r.','MarkerSize',15);
plot(N_7,ru_2(T_7),'k.','MarkerSize',15);
plot(N_r,ru_2(T_r),'m.','MarkerSize',15);
plot(N_1,ru_3(T_1),'g.','MarkerSize',15);
plot(N_3,ru_3(T_3),'r.','MarkerSize',15);
plot(N_7,ru_3(T_7),'k.','MarkerSize',15);
plot(N_r,ru_3(T_r),'m.','MarkerSize',15);

subplot(3,2,4);
plot(p(consol_step:end)/p(consol_step),q(consol_step:end));grid on; hold on;
ylabel('mean effective stress ratio (p''/p''_c)');
xlabel('q (kPa)');
xlim([min(p/p(consol_step)),max(p/p(consol_step))]);
plot(p(T_1)/p(consol_step),q(T_1),'g.','MarkerSize',15);
plot(p(T_3)/p(consol_step),q(T_3),'r.','MarkerSize',15);
plot(p(T_r)/p(consol_step),q(T_r),'m.','MarkerSize',15);
title(['p''_{c} = ',num2str(p(consol_step),2),' kPa']);

subplot(3,2,5);
plot(cycle(consol_step+1:end),pwp(consol_step+1:end));grid on;
ylabel('PWP (kPa)');
xlabel('No. of cycles');
hold on;
plot(cycle(T_1),pwp(T_1),'g.','MarkerSize',15);
plot(cycle(T_3),pwp(T_3),'r.','MarkerSize',15);
plot(cycle(T_r),pwp(T_r),'m.','MarkerSize',15);
ylim([-10,100]);

subplot(3,2,6);
plot(cycle(consol_step+1:end),gama_12(consol_step+1:end));grid on;
hold on;
plot(N_1,gama_12(T_1),'g.','MarkerSize',15);
plot(N_3,gama_12(T_3),'r.','MarkerSize',15);
plot(N_7,gama_12(T_7),'k.','MarkerSize',15);
plot(N_r,gama_12(T_r),'m.','MarkerSize',15);
plot(cycle(peaks(:,2)),peaks(:,1),'b.','MarkerSize',15);
xlabel('No. of cycles');
ylabel('\gamma_{12}');

end;    % (end of undrained_cyclic
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(Analysis_case,'drained_monotonic') == 1

    G_max = s_12(consol_step+1)/gama_12(consol_step+1);
    G_max_oct = tau_oct(consol_step+1)/gama_oct(consol_step+1);      
    % barayeh dele khodam
    t1=510;
    t2=521;
    radical=sqrt(2*(s_22(t1)-s_11(t1))^2+6*s_12(t1));
    p1=4*1/3*(s_22(t1)-s_11(t1))/(2*radical)*(s_22(t2)-s_22(t1))
    p2=-4/3*(s_22(t1)-s_11(t1))/(2*radical)*(s_11(t2)-s_11(t1))
    p3=4*s_12(t1)/(2*radical)*(s_12(t2)-s_12(t1))
    d_tau_oct=p1+p2+p3
    tau_oct(t2)-tau_oct(t1)
    
    radicalE=sqrt(2*(e_22(t1))^2+3/2*(gama_12(t1))^2);
    e1=2/3*(4*e_22(t1))/(2*radicalE)*(e_22(t2)-e_22(t1))
    e2=2/3*(3*gama_12(t1))/(2*radicalE)*(gama_12(t2)-gama_12(t1))
    d_gama_oct=e1+e2
    gama_oct(t2)-gama_oct(t1)
    
    d_tau_oct/d_gama_oct
    G_max_oct
    
    figure
    subplot(1,2,1);hold on; grid on;
    plot(gama_12(consol_step+1:end),s_12(consol_step+1:end));
    plot(gama_oct(consol_step+1:end),tau_oct(consol_step+1:end),'r');
    legend('\sigma_{12} vs \gamma_{12}','\tau_{oct} vs \gamma_{oct}',4);
    xlabel('\gamma_{12} and \gamma_{oct}');ylabel('\sigma_{12} and \tau_{oct}');
    ylim([0,60]);
    title(['\sigma''_{vc} (kPa) = ',num2str(s_22(consol_step))]);

    subplot(1,2,2);grid on;hold on
    plot(p(consol_step+1:end),tau_oct(consol_step+1:end),'r');
    plot(s_22(consol_step+1:end),s_12(consol_step+1:end),'b')
    ylim([0,60]);
   
    slope_oct = tau_oct(end)/p(end);
    Phi_oct_back_calculated = asin(3*slope_oct/(2*sqrt(2)+slope_oct))/3.1416*180;
    slope_conventional = s_12(end)/s_22(end);
    Phi_conventional_back_calculated = atan(slope_conventional)/3.1416*180;

    plot([0,max(p)*1.2],[0,(max(p)*1.2)*slope_oct],'--r')
    plot([0,max(s_22)*1.2],[0,(max(s_22)*1.2)*slope_conventional],'--b')
    xlabel('\sigma''_{v} and p'' (kPa)');ylabel('\sigma_{12} and \tau_{oct}');
    xlim([0,max(p)*1.2]);
    legend(['\phi_{oct} = ',num2str(Phi_oct_back_calculated)],['\phi_{DSS} = ',num2str(Phi_conventional_back_calculated)],2)

end;    % (end of drained_monotonic)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(Analysis_case,'undrained_monotonic') == 1
    figure
    subplot(2,2,1);plot(gama_12(consol_step+1:end),s_12(consol_step+1:end));
    grid on;
    xlabel('\gamma_{12}');
    ylabel('\sigma_{12} (kPa)');
    
    subplot(2,2,2);plot(s_22(consol_step+1:end),s_12(consol_step+1:end));
    grid on; hold on;
    xlim([0,max(s_22)])
    plot([0,s_22(end)],[0,s_12(end)],'r')
    xlabel('\sigma''_{v} (kPa)');
    ylabel('\sigma_{12} (kPa)');
    slope_conventional = s_12(end)/s_22(end);
    Phi_conventional_back_calculated = atan(slope_conventional)/3.1416*180;
    legend(['\phi_{DSS} = ',num2str(Phi_conventional_back_calculated)],2)

    subplot(2,2,3);plot(gama_12,pwp);grid on;
    xlabel('\gamma_{12}')
    ylabel('pwp (kPa)')
    subplot(2,2,4)
    plot(gama_12,e_v-e_v(consol_step)); grid on;
    set(gca,'YDir','rev');
    xlabel('\gamma_{12}')
    ylabel('Vomuletric strain \epsilon_v - \epsilon_o');

end;    % (end of undrained_monotonic')
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
