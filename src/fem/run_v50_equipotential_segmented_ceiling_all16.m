%% PAPER 1 - v5.0 EQUIPOTENTIAL SEGMENTED SURROGATE CEILING DIAGNOSTIC
%
% DO NOT RUN UNTIL THE FEM CONVERGENCE AUDIT HAS BEEN REVIEWED.
%
% DEVELOPMENT 16 ONLY. No held-out case is touched.
%
% Purpose:
% Test whether replacing the uniform-leakage line assumption of M1 by an
% equipotential thin-wire segmented model can reduce full-field inverse bias.
%
% This is a DIAGNOSTIC v5.0, not a frozen final model.
%
% Physics:
% - straight horizontal buried electrode;
% - homogeneous half-space;
% - M pulse segments along the electrode;
% - segment currents are solved from approximate equipotentiality;
% - image contribution enforces the insulating soil/air boundary;
% - total segment current sums to Iinj;
% - surface potential is the superposition of segment contributions;
% - b0 remains a profiled nuisance offset.
%
% Discretization study:
%   M = 10, 20, 40, 80
%
% A physically credible v5.0 must show a stable trend with M. A single M that
% happens to improve the development cases is NOT sufficient for freezing.

clear; clc;

fprintf('\n============================================================\n');
fprintf(' PAPER 1 - v5.0 EQUIPOTENTIAL SEGMENTED CEILING DIAGNOSTIC\n');
fprintf(' DEVELOPMENT 16 ONLY | HELD-OUT 84 UNTOUCHED\n');
fprintf('============================================================\n\n');

script_dir=fileparts(mfilename('fullpath'));
workspace_root=script_dir;

while ~exist(fullfile(workspace_root,'01_COMSOL_FEM'),'dir')
    parent=fileparts(workspace_root);
    if strcmp(parent,workspace_root)
        error('Could not locate Paper 1 workspace root.');
    end
    workspace_root=parent;
end

fem_dir=fullfile(workspace_root,'01_COMSOL_FEM','03_Sentinel16_FEM');
out_dir=fullfile(script_dir,'01_Results');

if ~exist(out_dir,'dir'), mkdir(out_dir); end

files=dir(fullfile(fem_dir,'case_*_surface_potential.csv'));
if isempty(files)
    error('No development FEM fields found: %s',fem_dir);
end

Mlist=[10 20 40 80];
sigma_fraction=0.01;
rc=0.01;

all_rows={};
rr=0;

for ii=1:numel(files)

    T=readtable(fullfile(files(ii).folder,files(ii).name));

    if height(T)~=956 || any(~isfinite(T.V_fem_V))
        fprintf(2,'Skipping invalid file: %s\n',files(ii).name);
        continue;
    end

    P=[T.x_m T.y_m];
    V=T.V_fem_V;

    c=T.case_col(1);
    Lt=T.L_true_m(1);
    phit=mod(T.phi_true_deg(1),360);
    dt=T.d_true_m(1);
    rho=T.rho_true_ohm_m(1);
    Iinj=T.Iinj_A(1);

    sigma_design=max(sigma_fraction*sqrt(mean(V.^2)),1e-9);

    fprintf('\n------------------------------------------------------------\n');
    fprintf('case %d | truth L=%.6f phi=%.6f d=%.6f\n',c,Lt,phit,dt);

    theta_prev=[];

    for im=1:numel(Mlist)

        M=Mlist(im);

        fprintf('  M=%d ...\n',M);

        [theta,b0]=fit_segmented_fullfield( ...
            P,V,rho,Iinj,rc,M,sigma_design,theta_prev);

        Vhat=segmented_surface_V(P,theta(1),theta(2),theta(3), ...
            rho,Iinj,rc,M)+b0;

        ptrue=[Lt*cosd(phit),Lt*sind(phit)];
        phat=[theta(1)*cosd(theta(2)),theta(1)*sind(theta(2))];

        eend=norm(phat-ptrue);
        eL=abs(theta(1)-Lt);
        ephi=abs(theta(2)-phit);
        ephi=min(ephi,360-ephi);
        ed=abs(theta(3)-dt);

        rmse=sqrt(mean((Vhat-V).^2));
        rmsepct=100*rmse/max(sqrt(mean(V.^2)),eps);

        [frac,~]=segment_current_fractions(theta(1),theta(3),rc,M);

        fprintf('    endpoint=%.6f m | RMSE=%.4f%% | Imax/Imean=%.3f\n', ...
            eend,rmsepct,max(frac)*M);

        rr=rr+1;
        all_rows(rr,:)={c,M,Lt,phit,dt,rho, ...
            theta(1),theta(2),theta(3),b0, ...
            eL,ephi,ed,eend,rmse,rmsepct, ...
            min(frac),max(frac),max(frac)*M};

        theta_prev=theta;
    end
end

R=cell2table(all_rows,'VariableNames',{ ...
    'case_id','M_segments','L_true_m','phi_true_deg','d_true_m','rho_ohm_m', ...
    'L_hat_m','phi_hat_deg','d_hat_m','b0_V', ...
    'L_abs_error_m','phi_abs_error_deg','d_abs_error_m','endpoint_error_m', ...
    'field_RMSE_V','field_RMSE_pct_RMS','min_current_fraction', ...
    'max_current_fraction','Imax_over_Imean'});

for k=1:width(R)
    vn=R.Properties.VariableNames{k};
    if iscell(R.(vn))
        try, R.(vn)=cell2mat(R.(vn)); catch, end
    end
end

R=sortrows(R,{'case_id','M_segments'});
writetable(R,fullfile(out_dir,'v50_segmented_fullfield_all16.csv'));

% Discretization changes M20->40 and M40->80.
conv_rows={};
cc=0;

cases=unique(R.case_id);

for c=cases.'
    Rc=R(R.case_id==c,:);

    pairs=[20 40;40 80];

    for ip=1:size(pairs,1)
        a=Rc(Rc.M_segments==pairs(ip,1),:);
        b=Rc(Rc.M_segments==pairs(ip,2),:);

        if isempty(a) || isempty(b), continue; end

        cc=cc+1;
        conv_rows(cc,:)={c,pairs(ip,1),pairs(ip,2), ...
            abs(a.endpoint_error_m-b.endpoint_error_m), ...
            abs(a.L_hat_m-b.L_hat_m), ...
            abs(a.d_hat_m-b.d_hat_m), ...
            circular_difference(a.phi_hat_deg,b.phi_hat_deg), ...
            abs(a.field_RMSE_pct_RMS-b.field_RMSE_pct_RMS)};
    end
end

C=cell2table(conv_rows,'VariableNames',{ ...
    'case_id','M_A','M_B','delta_endpoint_error_m','delta_L_hat_m', ...
    'delta_d_hat_m','delta_phi_hat_deg','delta_field_RMSE_pct_RMS'});

for k=1:width(C)
    vn=C.Properties.VariableNames{k};
    if iscell(C.(vn))
        try, C.(vn)=cell2mat(C.(vn)); catch, end
    end
end

writetable(C,fullfile(out_dir,'v50_segmented_discretization_convergence.csv'));

fprintf('\n============================================================\n');
fprintf(' v5.0 SEGMENTED DIAGNOSTIC COMPLETE\n');
fprintf(' This is NOT yet a frozen surrogate.\n');
fprintf(' Inspect M-convergence before any active-sampling experiment.\n');
fprintf('============================================================\n');

%% ================================================================
% LOCAL FUNCTIONS
% ================================================================

function [theta,b0]=fit_segmented_fullfield(P,Vobs,rho,Iinj,rc,M,sigma_design,theta_prev)

    Llo=8; Lhi=30;
    dlo=0.5; dhi=1.5;

    if isempty(theta_prev)
        ang=(0:45:315).';
        starts1=[19*ones(8,1),ang,ones(8,1)];
        starts2=[10*ones(4,1),(0:90:270).',0.7*ones(4,1)];
        starts3=[29*ones(4,1),(45:90:315).',1.3*ones(4,1)];
        starts=[starts1;starts2;starts3];
    else
        tp=theta_prev;
        starts=[ ...
            tp;
            tp(1),mod(tp(2)+10,360),tp(3);
            tp(1),mod(tp(2)-10,360),tp(3);
            min(30,tp(1)+1),tp(2),tp(3);
            max(8,tp(1)-1),tp(2),tp(3);
            tp(1),tp(2),min(1.5,tp(3)+0.10);
            tp(1),tp(2),max(0.5,tp(3)-0.10)];
    end

    obj=@(z)objective_segmented(z,P,Vobs,rho,Iinj,rc,M, ...
        sigma_design,Llo,Lhi,dlo,dhi);

    opts=optimset('Display','off','MaxFunEvals',7000,'MaxIter',3500, ...
        'TolX',1e-8,'TolFun',1e-10);

    bestf=inf;
    bestz=starts(1,:);

    for k=1:size(starts,1)
        [zk,fk]=fminsearch(obj,starts(k,:),opts);

        zc=zk;
        zc(1)=min(max(zc(1),Llo),Lhi);
        zc(2)=mod(zc(2),360);
        zc(3)=min(max(zc(3),dlo),dhi);

        fc=obj(zc);

        if fc<bestf
            bestf=fc;
            bestz=zc;
        end
    end

    theta=bestz;

    Vbase=segmented_surface_V(P,theta(1),theta(2),theta(3),rho,Iinj,rc,M);
    b0=mean(Vobs-Vbase);
end

function f=objective_segmented(z,P,Vobs,rho,Iinj,rc,M, ...
    sigma_design,Llo,Lhi,dlo,dhi)

    L=z(1);
    phi=mod(z(2),360);
    d=z(3);

    penalty=0;

    if L<Llo
        penalty=penalty+1e8*(Llo-L)^2;
    elseif L>Lhi
        penalty=penalty+1e8*(L-Lhi)^2;
    end

    if d<dlo
        penalty=penalty+1e8*(dlo-d)^2;
    elseif d>dhi
        penalty=penalty+1e8*(d-dhi)^2;
    end

    Lc=min(max(L,Llo),Lhi);
    dc=min(max(d,dlo),dhi);

    try
        Vbase=segmented_surface_V(P,Lc,phi,dc,rho,Iinj,rc,M);

        if any(~isfinite(Vbase))
            f=1e30;
            return;
        end

        b0=mean(Vobs-Vbase);
        rr=(Vbase+b0-Vobs)/sigma_design;

        f=mean(rr.^2)+penalty;

    catch
        f=1e30;
    end
end

function V=segmented_surface_V(P,L,phi_deg,d,rho,Iinj,rc,M)

    [frac,dl]=segment_current_fractions(L,d,rc,M);

    ph=phi_deg*pi/180;
    x=P(:,1);
    y=P(:,2);

    sproj=x*cos(ph)+y*sin(ph);
    perp2=max(x.^2+y.^2-sproj.^2,0);
    b=sqrt(max(perp2+d.^2,1e-14));

    s0=(0:M-1)*dl;
    a=bsxfun(@minus,sproj,s0);

    integ=asinh(bsxfun(@rdivide,dl-a,b)) + ...
          asinh(bsxfun(@rdivide,a,b));

    % At the soil surface, the real and image finite-line contributions
    % are equal, giving rho/(2*pi*dl).
    V=rho*Iinj/(2*pi*dl)*(integ*frac);
end

function [frac,dl]=segment_current_fractions(L,d,rc,M)

    dl=L/M;

    target_s=((1:M)-0.5)'*dl;
    source_s=(0:M-1)*dl;

    a=bsxfun(@minus,target_s,source_s);

    b_direct=rc;
    b_image=sqrt((2*d)^2+rc^2);

    direct=asinh((dl-a)/b_direct)+asinh(a/b_direct);
    image=asinh((dl-a)/b_image)+asinh(a/b_image);

    % Common rho factor cancels when solving the current fractions.
    G=(direct+image)/(4*pi*dl);

    A=[G,-ones(M,1);ones(1,M),0];
    rhs=[zeros(M,1);1];

    if rcond(A)<1e-14
        sol=pinv(A)*rhs;
    else
        sol=A\rhs;
    end

    frac=sol(1:M);

    % Numerical sanity.
    frac=frac/sum(frac);

    if any(~isfinite(frac))
        error('Invalid segmented current distribution.');
    end
end

function d=circular_difference(a,b)
    d=abs(a-b);
    d=min(d,360-d);
end
