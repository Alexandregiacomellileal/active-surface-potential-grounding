%% PAPER 1 - M1+b0 FULL-FIELD CEILING | FROZEN FEM v1.2
%
% Uses ALL 956 points from the REGENERATED development-16 FEM fields
% produced by:
%   run_fem_development16_FROZEN_v12
%
% NO COMSOL connection required.
% HELD-OUT 84 ARE NOT READ.
%
% Outputs:
%   m1_fullfield_ceiling_FROZEN_v12_all16.csv
%   m1_ceiling_old_vs_FROZEN_v12.csv  (when historical result is found)

clear; clc;

fprintf('\n============================================================\n');
fprintf(' PAPER 1 - M1+b0 FULL-FIELD CEILING | FROZEN FEM v1.2\n');
fprintf(' DEVELOPMENT 16 ONLY | 956 POINTS PER CASE\n');
fprintf('============================================================\n\n');

script_dir=fileparts(mfilename('fullpath'));
root=script_dir;

while ~exist(fullfile(root,'01_COMSOL_FEM'),'dir')
    parent=fileparts(root);
    if strcmp(parent,root)
        error('Could not locate Paper 1 workspace root.');
    end
    root=parent;
end

fem_dir=fullfile(root,'01_COMSOL_FEM','05_Development16_FROZEN_v12', ...
    '00_RUN_CURRENT','01_Results_FROZEN_v12');

files=dir(fullfile(fem_dir,'case_*_surface_potential_FROZEN_v12.csv'));

if numel(files)~=16
    error('Expected 16 frozen-v1.2 FEM fields in %s; found %d.',fem_dir,numel(files));
end

sigma_fraction=0.01;
rows={};

for ii=1:numel(files)

    fn=fullfile(files(ii).folder,files(ii).name);
    T=readtable(fn);

    if height(T)~=956 || any(~isfinite(T.V_fem_V))
        error('Invalid frozen field: %s',files(ii).name);
    end

    P=[T.x_m T.y_m];
    V=T.V_fem_V;

    if ismember('case_col',T.Properties.VariableNames)
        c=T.case_col(1);
    else
        c=T.case_id_col(1);
    end

    Lt=T.L_true_m(1);
    phit=mod(T.phi_true_deg(1),360);
    dt=T.d_true_m(1);
    rho=T.rho_true_ohm_m(1);
    I=T.Iinj_A(1);

    sigma_design=max(sigma_fraction*sqrt(mean(V.^2)),1e-9);

    [theta,b0]=fit_fullfield_m1(P,V,rho,I,sigma_design);

    Vhat=uniform_line_V(P,theta(1),theta(2),theta(3),rho,I)+b0;
    rr=Vhat-V;

    ptrue=[Lt*cosd(phit),Lt*sind(phit)];
    phat=[theta(1)*cosd(theta(2)),theta(1)*sind(theta(2))];

    eend=norm(phat-ptrue);
    eL=abs(theta(1)-Lt);
    ephi=circ_diff(theta(2),phit);
    ed=abs(theta(3)-dt);

    rmse=sqrt(mean(rr.^2));
    rmsepct=100*rmse/max(sqrt(mean(V.^2)),eps);

    fprintf('case %3d | endpoint=%.6f m | Lerr=%.5f | phierr=%.5f deg | derr=%.5f | RMSE=%.4f%% RMS\n', ...
        c,eend,eL,ephi,ed,rmsepct);

    rows(end+1,:)={c,Lt,phit,dt,rho, ...
        theta(1),theta(2),theta(3),b0, ...
        eL,ephi,ed,eend,rmse,rmsepct,eend<=0.25}; %#ok<AGROW>
end

R=cell2table(rows,'VariableNames',{ ...
    'case_id','L_true_m','phi_true_deg','d_true_m','rho_ohm_m', ...
    'L_hat_fullfield_m','phi_hat_fullfield_deg','d_hat_fullfield_m', ...
    'b0_fullfield_V','L_abs_error_m','phi_abs_error_deg','d_abs_error_m', ...
    'endpoint_error_fullfield_m','field_RMSE_V','field_RMSE_pct_RMS', ...
    'passes_endpoint_0p25'});

for k=1:width(R)
    vn=R.Properties.VariableNames{k};
    if iscell(R.(vn))
        try, R.(vn)=cell2mat(R.(vn)); catch, end
    end
end

R=sortrows(R,'case_id');

out_file=fullfile(script_dir,'m1_fullfield_ceiling_FROZEN_v12_all16.csv');
writetable(R,out_file);

fprintf('\n------------------------------------------------------------\n');
fprintf('Frozen-v1.2 FEM cases with M1 full-field endpoint >0.25 m: %d/%d\n', ...
    sum(~R.passes_endpoint_0p25),height(R));
fprintf('Output: %s\n',out_file);

%% Historical comparison if available
old_file=fullfile(root,'04_Robust_MultiHyp_v2','09_M1_FullField_Ceiling', ...
    'm1_fullfield_ceiling_all16.csv');

if exist(old_file,'file')

    O=readtable(old_file);

    if ismember('case_id',O.Properties.VariableNames) && ...
            ismember('endpoint_error_fullfield_m',O.Properties.VariableNames)

        C=outerjoin( ...
            O(:,{'case_id','endpoint_error_fullfield_m','field_RMSE_pct_RMS'}), ...
            R(:,{'case_id','endpoint_error_fullfield_m','field_RMSE_pct_RMS'}), ...
            'Keys','case_id','MergeKeys',true);

        C.Properties.VariableNames={ ...
            'case_id', ...
            'endpoint_old_m','field_RMSE_old_pct_RMS', ...
            'endpoint_FROZEN_v12_m','field_RMSE_FROZEN_v12_pct_RMS'};

        C.delta_endpoint_FROZEN_minus_old_m = ...
            C.endpoint_FROZEN_v12_m-C.endpoint_old_m;

        C.old_pass_0p25=C.endpoint_old_m<=0.25;
        C.FROZEN_v12_pass_0p25=C.endpoint_FROZEN_v12_m<=0.25;

        C=sortrows(C,'case_id');

        compare_file=fullfile(script_dir,'m1_ceiling_old_vs_FROZEN_v12.csv');
        writetable(C,compare_file);

        fprintf('\nHistorical old-FEM vs frozen-v1.2 comparison:\n');

        for i=1:height(C)
            fprintf('case %3d | old %.6f -> frozen %.6f m | delta %+0.6f m\n', ...
                C.case_id(i),C.endpoint_old_m(i), ...
                C.endpoint_FROZEN_v12_m(i), ...
                C.delta_endpoint_FROZEN_minus_old_m(i));
        end

        fprintf('Comparison output: %s\n',compare_file);
    end
else
    fprintf('\nHistorical ceiling CSV not found; skipping automatic comparison.\n');
end

fprintf('\n============================================================\n');
fprintf(' FROZEN-v1.2 M1 CEILING DIAGNOSTIC COMPLETE\n');
fprintf(' HELD-OUT 84 REMAIN UNTOUCHED\n');
fprintf('============================================================\n');

%% ================================================================
% M1+b0 FIT
% ================================================================
function [theta,b0]=fit_fullfield_m1(P,Vobs,rho,I,sigma_design)

    Llo=8; Lhi=30;
    dlo=0.5; dhi=1.5;

    ang=(0:45:315).';
    starts1=[19*ones(8,1),ang,ones(8,1)];
    starts2=[10*ones(4,1),(0:90:270).',0.7*ones(4,1)];
    starts3=[29*ones(4,1),(45:90:315).',1.3*ones(4,1)];
    starts=[starts1;starts2;starts3];

    obj=@(z)objective(z,P,Vobs,rho,I,sigma_design,Llo,Lhi,dlo,dhi);

    opts=optimset('Display','off','MaxFunEvals',8000,'MaxIter',4000, ...
        'TolX',1e-9,'TolFun',1e-12);

    bestf=inf;
    bestz=starts(1,:);

    for k=1:size(starts,1)
        [zk,fk]=fminsearch(obj,starts(k,:),opts);
        if fk<bestf
            bestf=fk;
            bestz=zk;
        end
    end

    theta=bestz;
    theta(1)=min(max(theta(1),Llo),Lhi);
    theta(2)=mod(theta(2),360);
    theta(3)=min(max(theta(3),dlo),dhi);

    Vbase=uniform_line_V(P,theta(1),theta(2),theta(3),rho,I);
    b0=mean(Vobs-Vbase);
end

function f=objective(z,P,Vobs,rho,I,sigma_design,Llo,Lhi,dlo,dhi)

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

    Vbase=uniform_line_V(P,Lc,phi,dc,rho,I);
    b0=mean(Vobs-Vbase);

    rr=(Vbase+b0-Vobs)/sigma_design;
    f=mean(rr.^2)+penalty;
end

function V=uniform_line_V(P,L,phi_deg,d,rho,I)

    ph=phi_deg*pi/180;
    x=P(:,1);
    y=P(:,2);

    a=x*cos(ph)+y*sin(ph);
    b=sqrt(max(x.^2+y.^2+d.^2-a.^2,1e-14));

    V=rho*I/(2*pi*L).*( ...
        asinh((L-a)./b)+asinh(a./b));
end

function d=circ_diff(a,b)
    d=abs(a-b);
    d=min(d,360-d);
end
