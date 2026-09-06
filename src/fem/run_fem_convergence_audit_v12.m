%% PAPER 1 - EXPLICIT-MESH + GAUGE-AWARE FEM CONVERGENCE AUDIT v1.2
%
% DEVELOPMENT ONLY. HELD-OUT 84 UNTOUCHED.
%
% WHY v1.2
% --------
% v1.0 showed that COMSOL automatic mesh levels 4->3 were not converged.
% v1.1 showed that domain enlargement is dominated partly by an additive
% reference-potential shift, which the inverse already profiles through b0.
% Also, using autoMeshSize on different domain sizes changes the absolute mesh
% at the same time as the domain.
%
% v1.2 therefore:
%   (1) uses ABSOLUTE user-controlled mesh sizes;
%   (2) explicitly refines the buried-electrode boundary;
%   (3) uses exactly the same absolute mesh settings across domain sizes;
%   (4) evaluates gauge-aware surface-field change;
%   (5) evaluates the change in the full-field M1+b0 inverse geometry.
%
% Audit geometries:
%   nominal + development cases 5, 38, 69, 92.
%
% Mesh audit at Dxy=400 m, Hsoil=200 m:
%   E1: global hmax=40 m, electrode hmax=0.60 m
%   E2: global hmax=30 m, electrode hmax=0.30 m
%   E3: global hmax=20 m, electrode hmax=0.15 m
% Formal mesh check: E2 -> E3.
%
% Domain audit with E3 held ABSOLUTELY FIXED:
%   400x400x200 m
%   600x600x300 m
%   800x800x400 m
% Formal domain check: 600 -> 800.
%
% FORMAL PASS CRITERIA (predeclared):
%   A) gauge-aware field RMS difference < 0.5%
%   B) change in inferred endpoint < 0.05 m
%   C) change in inferred depth < 0.05 m
%
% Why 0.05 m:
%   - 20% of the primary endpoint target (0.25 m);
%   - one half of the previously frozen 0.10-m depth accuracy target.
%
% Raw terminal-voltage and raw field differences are reported diagnostically
% but are NOT formal gates because the finite remote-ground boundary can shift
% the absolute voltage reference and b0 is a nuisance parameter in the inverse.
%
% COMSOL 5.3 + LiveLink for MATLAB / Windows.

clear; clc;

fprintf('\n============================================================\n');
fprintf(' PAPER 1 - EXPLICIT-MESH + GAUGE-AWARE FEM AUDIT v1.2\n');
fprintf(' DEVELOPMENT ONLY | HELD-OUT 84 UNTOUCHED\n');
fprintf('============================================================\n\n');

%% Workspace
script_dir=fileparts(mfilename('fullpath'));
workspace_root=script_dir;

while ~exist(fullfile(workspace_root,'01_COMSOL_FEM'),'dir')
    parent=fileparts(workspace_root);
    if strcmp(parent,workspace_root)
        error('Could not locate Paper 1 workspace root.');
    end
    workspace_root=parent;
end

template_mph=fullfile(workspace_root,'01_COMSOL_FEM', ...
    '00_RUN_FEM_SENTINEL16','paper1_grounding_forward_v02_unsolved.mph');

doe_file=fullfile(workspace_root,'03_Sentinel16_Diagnostics', ...
    '01_Frozen_v10_Code','doe_fem_sentinel16_frozen.csv');

out_dir=fullfile(script_dir,'01_Results_v12');
field_dir=fullfile(out_dir,'fields');

if ~exist(out_dir,'dir'), mkdir(out_dir); end
if ~exist(field_dir,'dir'), mkdir(field_dir); end

if ~exist(template_mph,'file'), error('Template MPH not found: %s',template_mph); end
if ~exist(doe_file,'file'), error('DOE not found: %s',doe_file); end

%% COMSOL connection
comsol_mli='C:\Program Files\COMSOL\COMSOL53\Multiphysics\mli';
comsol_server_exe= ...
    'C:\Program Files\COMSOL\COMSOL53\Multiphysics\bin\win64\comsolmphserver.exe';
comsol_exe= ...
    'C:\Program Files\COMSOL\COMSOL53\Multiphysics\bin\win64\comsol.exe';

porta_comsol=2036;
usuario_comsol='alexandre';
senha_comsol=input('COMSOL Server password: ','s');

if ~exist(comsol_mli,'dir'), error('COMSOL mli folder not found.'); end
addpath(comsol_mli);

conectado=false;
try
    mphstart('localhost',porta_comsol,usuario_comsol,senha_comsol);
    conectado=true;
catch ME
    if ~isempty(strfind(ME.message,'Already connected to a server'))
        conectado=true;
    end
end

if ~conectado
    fprintf('Starting COMSOL Multiphysics Server...\n');
    if exist(comsol_server_exe,'file')
        system(sprintf('start "COMSOL Server" "%s" -port %d', ...
            comsol_server_exe,porta_comsol));
    elseif exist(comsol_exe,'file')
        system(sprintf('start "COMSOL Server" "%s" mphserver -port %d', ...
            comsol_exe,porta_comsol));
    else
        error('COMSOL Server executable not found.');
    end

    pause(8);

    for it=1:4
        try
            fprintf('Connection retry %d...\n',it);
            mphstart('localhost',porta_comsol,usuario_comsol,senha_comsol);
            conectado=true;
            break;
        catch ME
            if ~isempty(strfind(ME.message,'Already connected to a server'))
                conectado=true;
                break;
            end
            pause(3);
        end
    end
end

if ~conectado, error('Could not connect MATLAB to COMSOL Server.'); end

import com.comsol.model.*
import com.comsol.model.util.*

%% Fixed 956-point candidate grid
xv=-30:2:30;
yv=-30:2:30;
P=zeros(956,2);
kk=0;

for ix=1:numel(xv)
    for iy=1:numel(yv)
        if hypot(xv(ix),yv(iy))>2.01
            kk=kk+1;
            P(kk,:)=[xv(ix),yv(iy)];
        end
    end
end

if kk~=956, error('Expected 956 candidate points, got %d.',kk); end

z_eval=-1e-4;
coord=[P(:,1).';P(:,2).';z_eval*ones(1,956)];

%% Development-only audit cases
DOE=readtable(doe_file);
audit_ids=[5 38 69 92];

case_label={'nominal'}';
case_id=0;
L_m=20;
phi_deg=45;
d_m=1;
rho_ohm_m=300;

for c=audit_ids
    r=DOE(DOE.case_id==c,:);
    if height(r)~=1, error('Case %d not unique in DOE.',c); end

    case_label{end+1,1}=sprintf('case_%03d',c); %#ok<SAGROW>
    case_id(end+1,1)=c; %#ok<SAGROW>
    L_m(end+1,1)=r.L_m(1); %#ok<SAGROW>
    phi_deg(end+1,1)=r.phi_deg(1); %#ok<SAGROW>
    d_m(end+1,1)=r.d_m(1); %#ok<SAGROW>
    rho_ohm_m(end+1,1)=r.rho_ohm_m(1); %#ok<SAGROW>
end

case_id=case_id(:);
L_m=L_m(:);
phi_deg=phi_deg(:);
d_m=d_m(:);
rho_ohm_m=rho_ohm_m(:);

%% Absolute mesh configurations
% name, phase, Dxy, Hsoil, global hmax, electrode hmax, local hcurve
C={ ...
    'E1_D400','mesh',400,200,40,0.60,0.30; ...
    'E2_D400','mesh',400,200,30,0.30,0.22; ...
    'E3_D400','mesh',400,200,20,0.15,0.16; ...
    'E3_D600','domain',600,300,20,0.15,0.16; ...
    'E3_D800','domain',800,400,20,0.15,0.16};

% Fixed across every configuration unless listed above.
global_hmin=0.005;
global_hgrad=1.40;
global_hcurve=0.40;
global_hnarrow=1.0;

local_hmin=0.0015;
local_hgrad=1.25;
local_hnarrow=1.5;

%% Open validated unsolved template once
model=mphopen(template_mph);

run_rows={};
rr=0;

for ic=1:numel(case_id)

    fprintf('\n============================================================\n');
    fprintf('AUDIT GEOMETRY %s\n',case_label{ic});
    fprintf('L=%.6f | phi=%.6f | d=%.6f | rho=%.6f\n', ...
        L_m(ic),phi_deg(ic),d_m(ic),rho_ohm_m(ic));
    fprintf('============================================================\n');

    for jc=1:size(C,1)

        cond=C{jc,1};
        phase=C{jc,2};
        Dxy0=C{jc,3};
        Hsoil0=C{jc,4};
        ghmax=C{jc,5};
        lhmax=C{jc,6};
        lhcurve=C{jc,7};

        fprintf('\n--- %s | D=%g H=%g | global hmax=%g | electrode hmax=%g ---\n', ...
            cond,Dxy0,Hsoil0,ghmax,lhmax);

        csv_out=fullfile(field_dir,sprintf('%s_%s.csv',case_label{ic},cond));

        % Restart-safe.
        if exist(csv_out,'file')
            try
                Told=readtable(csv_out);
                if height(Told)==956 && ismember('V_fem_V',Told.Properties.VariableNames) ...
                        && all(isfinite(Told.V_fem_V))
                    fprintf('Valid field already exists -> SKIP solve.\n');
                    V=Told.V_fem_V;
                    vt=Told.V_terminal_V(1);

                    rr=rr+1;
                    run_rows(rr,:)={case_label{ic},case_id(ic),phase,cond, ...
                        Dxy0,Hsoil0,ghmax,lhmax,lhcurve,vt,min(V),max(V), ...
                        sqrt(mean(V.^2)),'SKIPPED_VALID'};
                    continue;
                end
            catch
            end
        end

        try
            %% Parameters
            model.param.set('L',sprintf('%.12g[m]',L_m(ic)));
            model.param.set('phi',sprintf('%.12g[deg]',phi_deg(ic)));
            model.param.set('d',sprintf('%.12g[m]',d_m(ic)));
            model.param.set('rho',sprintf('%.12g[ohm*m]',rho_ohm_m(ic)));
            model.param.set('Iinj','1[A]');
            model.param.set('rc','0.01[m]');
            model.param.set('Dxy',sprintf('%.12g[m]',Dxy0));
            model.param.set('Hsoil',sprintf('%.12g[m]',Hsoil0));

            comp1=model.component('comp1');

            fprintf('Rebuilding geometry...\n');
            comp1.geom('geom1').run;

            %% Robust boundary reselection
            L0=L_m(ic);
            ph0=phi_deg(ic)*pi/180;
            d0=d_m(ic);
            rc0=0.01;
            tol_outer=1e-3;

            top_box=[ ...
                -Dxy0/2-1,Dxy0/2+1; ...
                -Dxy0/2-1,Dxy0/2+1; ...
                -tol_outer,tol_outer];

            bottom_box=[ ...
                -Dxy0/2-1,Dxy0/2+1; ...
                -Dxy0/2-1,Dxy0/2+1; ...
                -Hsoil0-tol_outer,-Hsoil0+tol_outer];

            xp_box=[Dxy0/2-tol_outer,Dxy0/2+tol_outer; ...
                -Dxy0/2-1,Dxy0/2+1;-Hsoil0-1,1];
            xm_box=[-Dxy0/2-tol_outer,-Dxy0/2+tol_outer; ...
                -Dxy0/2-1,Dxy0/2+1;-Hsoil0-1,1];
            yp_box=[-Dxy0/2-1,Dxy0/2+1; ...
                Dxy0/2-tol_outer,Dxy0/2+tol_outer;-Hsoil0-1,1];
            ym_box=[-Dxy0/2-1,Dxy0/2+1; ...
                -Dxy0/2-tol_outer,-Dxy0/2+tol_outer;-Hsoil0-1,1];

            top_bnd=mphselectbox(model,'geom1',top_box,'boundary','include','all');
            bottom_bnd=mphselectbox(model,'geom1',bottom_box,'boundary','include','all');
            xp_bnd=mphselectbox(model,'geom1',xp_box,'boundary','include','all');
            xm_bnd=mphselectbox(model,'geom1',xm_box,'boundary','include','all');
            yp_bnd=mphselectbox(model,'geom1',yp_box,'boundary','include','all');
            ym_bnd=mphselectbox(model,'geom1',ym_box,'boundary','include','all');

            remote_bnd=unique([bottom_bnd(:);xp_bnd(:);xm_bnd(:); ...
                yp_bnd(:);ym_bnd(:)]).';

            x1=L0*cos(ph0);
            y1=L0*sin(ph0);
            margin_xy=3*rc0+1e-3;
            margin_z=3*rc0+1e-3;

            electrode_box=[ ...
                min(0,x1)-margin_xy,max(0,x1)+margin_xy; ...
                min(0,y1)-margin_xy,max(0,y1)+margin_xy; ...
                -d0-margin_z,-d0+margin_z];

            electrode_bnd=mphselectbox(model,'geom1',electrode_box, ...
                'boundary','include','any');

            if isempty(top_bnd) || isempty(remote_bnd) || isempty(electrode_bnd)
                error('Boundary selection failed.');
            end
            if ~isempty(intersect(top_bnd,remote_bnd)) || ...
                    ~isempty(intersect(electrode_bnd,remote_bnd)) || ...
                    ~isempty(intersect(electrode_bnd,top_bnd))
                error('Boundary-selection overlap detected.');
            end

            comp1.physics('ec').feature('term1').selection.set(electrode_bnd);
            comp1.physics('ec').feature('gnd1').selection.set(remote_bnd);

            fprintf('Boundaries OK | top=%d | remote=%d | electrode=%d\n', ...
                numel(top_bnd),numel(remote_bnd),numel(electrode_bnd));

            %% Absolute user-controlled mesh
            try
                comp1.mesh.remove('mesh1');
            catch
            end

            mesh1=comp1.mesh.create('mesh1');
            mesh1.automatic(false);

            sz=mesh1.feature('size');
            sz.set('custom','on');
            sz.set('hmax',sprintf('%.12g[m]',ghmax));
            sz.set('hmin',sprintf('%.12g[m]',global_hmin));
            sz.set('hgrad',sprintf('%.12g',global_hgrad));
            sz.set('hcurve',sprintf('%.12g',global_hcurve));
            sz.set('hnarrow',sprintf('%.12g',global_hnarrow));

            try
                ftet=mesh1.feature('ftet1');
            catch
                ftet=mesh1.feature.create('ftet1','FreeTet');
            end

            try
                lsz=ftet.feature('size_elec');
            catch
                lsz=ftet.feature.create('size_elec','Size');
            end

            lsz.selection.geom('geom1',2);
            lsz.selection.set(electrode_bnd);
            lsz.set('custom','on');
            lsz.set('hmax',sprintf('%.12g[m]',lhmax));
            lsz.set('hmin',sprintf('%.12g[m]',local_hmin));
            lsz.set('hgrad',sprintf('%.12g',local_hgrad));
            lsz.set('hcurve',sprintf('%.12g',lhcurve));
            lsz.set('hnarrow',sprintf('%.12g',local_hnarrow));

            fprintf('Building explicit mesh...\n');
            mesh1.run;

            fprintf('Solving...\n');
            model.study('std1').run;

            V=mphinterp(model,'V','coord',coord);
            V=V(:);

            if numel(V)~=956 || any(~isfinite(V))
                error('Invalid potential vector.');
            end

            vt=NaN;
            try
                vt=mphglobal(model,'ec.V0_1');
                vt=vt(1);
            catch
            end

            point_id=(1:956).';
            x_m=P(:,1);
            y_m=P(:,2);
            z_eval_m=repmat(z_eval,956,1);
            V_fem_V=V;
            V_terminal_V=repmat(vt,956,1);
            case_id_col=repmat(case_id(ic),956,1);
            L_true_m=repmat(L_m(ic),956,1);
            phi_true_deg=repmat(phi_deg(ic),956,1);
            d_true_m=repmat(d_m(ic),956,1);
            rho_true_ohm_m=repmat(rho_ohm_m(ic),956,1);
            Iinj_A=ones(956,1);
            Dxy_m=repmat(Dxy0,956,1);
            Hsoil_m=repmat(Hsoil0,956,1);
            global_hmax_m=repmat(ghmax,956,1);
            local_hmax_m=repmat(lhmax,956,1);
            local_hcurve_col=repmat(lhcurve,956,1);

            Tout=table(case_id_col,point_id,x_m,y_m,z_eval_m,V_fem_V, ...
                V_terminal_V,L_true_m,phi_true_deg,d_true_m,rho_true_ohm_m, ...
                Iinj_A,Dxy_m,Hsoil_m,global_hmax_m,local_hmax_m,local_hcurve_col);

            writetable(Tout,csv_out);

            rr=rr+1;
            run_rows(rr,:)={case_label{ic},case_id(ic),phase,cond, ...
                Dxy0,Hsoil0,ghmax,lhmax,lhcurve,vt,min(V),max(V), ...
                sqrt(mean(V.^2)),'OK'};

        catch ME
            fprintf(2,'ERROR %s / %s:\n%s\n',case_label{ic},cond,ME.message);

            rr=rr+1;
            run_rows(rr,:)={case_label{ic},case_id(ic),phase,cond, ...
                Dxy0,Hsoil0,ghmax,lhmax,lhcurve,NaN,NaN,NaN,NaN, ...
                ['ERROR: ' ME.message]};
        end
    end
end

RunSummary=cell2table(run_rows,'VariableNames',{ ...
    'case_label','case_id','phase','condition','Dxy_m','Hsoil_m', ...
    'global_hmax_m','local_hmax_m','local_hcurve','V_terminal_V', ...
    'V_min_V','V_max_V','V_rms_V','status'});

for k=1:width(RunSummary)
    vn=RunSummary.Properties.VariableNames{k};
    if iscell(RunSummary.(vn)) && ...
            ~ismember(vn,{'case_label','phase','condition','status'})
        try, RunSummary.(vn)=cell2mat(RunSummary.(vn)); catch, end
    end
end

writetable(RunSummary,fullfile(out_dir,'fem_v12_run_summary.csv'));

%% Pairwise gauge-aware + inverse-geometry comparisons
pair_def={ ...
    'E1_D400','E2_D400','mesh_E1_to_E2',false; ...
    'E2_D400','E3_D400','mesh_E2_to_E3_FORMAL',true; ...
    'E3_D400','E3_D600','domain_400_to_600',false; ...
    'E3_D600','E3_D800','domain_600_to_800_FORMAL',true};

pair_rows={};
pp=0;

for il=1:numel(case_label)

    for ip=1:size(pair_def,1)

        a=pair_def{ip,1};
        b=pair_def{ip,2};
        name=pair_def{ip,3};
        formal=pair_def{ip,4};

        fA=fullfile(field_dir,sprintf('%s_%s.csv',case_label{il},a));
        fB=fullfile(field_dir,sprintf('%s_%s.csv',case_label{il},b));

        if ~exist(fA,'file') || ~exist(fB,'file')
            pp=pp+1;
            pair_rows(pp,:)={case_label{il},name,a,b,formal, ...
                NaN,NaN,NaN,NaN,NaN,NaN,NaN,false,false,false,false};
            continue;
        end

        A=readtable(fA);
        B=readtable(fB);

        va=A.V_fem_V;
        vb=B.V_fem_V;

        raw_rel=norm(va-vb)/max(norm(vb),eps);

        shift=mean(va-vb);
        gauge_rel=norm((va-vb)-shift)/max(norm(vb),eps);

        vta=A.V_terminal_V(1);
        vtb=B.V_terminal_V(1);
        terminal_rel=abs(vta-vtb)/max(abs(vtb),eps);

        fa=fit_field_m1(A);
        fb=fit_field_m1(B);

        pA=[fa.L*cosd(fa.phi),fa.L*sind(fa.phi)];
        pB=[fb.L*cosd(fb.phi),fb.L*sind(fb.phi)];

        endpoint_shift=norm(pA-pB);
        L_shift=abs(fa.L-fb.L);
        phi_shift=circ_diff(fa.phi,fb.phi);
        d_shift=abs(fa.d-fb.d);

        pass_field=gauge_rel<0.005;
        pass_endpoint=endpoint_shift<0.05;
        pass_depth=d_shift<0.05;
        pass_pair=pass_field && pass_endpoint && pass_depth;

        pp=pp+1;
        pair_rows(pp,:)={case_label{il},name,a,b,formal, ...
            raw_rel,shift,gauge_rel,terminal_rel, ...
            endpoint_shift,L_shift,phi_shift,d_shift, ...
            pass_field,pass_endpoint,pass_depth,pass_pair};
    end
end

Pairwise=cell2table(pair_rows,'VariableNames',{ ...
    'case_label','comparison','condition_A','condition_reference', ...
    'formal_check','raw_field_rel','optimal_additive_shift_V', ...
    'gauge_field_rel','terminal_rel_diff','endpoint_estimate_shift_m', ...
    'L_estimate_shift_m','phi_estimate_shift_deg','d_estimate_shift_m', ...
    'field_pass','endpoint_pass','depth_pass','pair_pass'});

for k=1:width(Pairwise)
    vn=Pairwise.Properties.VariableNames{k};
    if iscell(Pairwise.(vn)) && ...
            ~ismember(vn,{'case_label','comparison','condition_A','condition_reference'})
        try, Pairwise.(vn)=cell2mat(Pairwise.(vn)); catch, end
    end
end

writetable(Pairwise,fullfile(out_dir,'fem_v12_pairwise.csv'));

formal=Pairwise(Pairwise.formal_check==1,:);
all_pass=all(formal.pair_pass==1);

fid=fopen(fullfile(out_dir,'FEM_V12_DECISION.txt'),'w');
fprintf(fid,'PAPER 1 - FEM CONVERGENCE v1.2 DECISION\n');
fprintf(fid,'======================================\n\n');
fprintf(fid,'Formal gates:\n');
fprintf(fid,' gauge-aware field RMS < 0.5%%\n');
fprintf(fid,' endpoint estimate shift < 0.05 m\n');
fprintf(fid,' depth estimate shift < 0.05 m\n\n');

for i=1:height(formal)
    fprintf(fid,'%s | %s | gauge=%.4f%% | dEnd=%.5f m | dDepth=%.5f m | PASS=%d\n', ...
        formal.case_label{i},formal.comparison{i}, ...
        100*formal.gauge_field_rel(i),formal.endpoint_estimate_shift_m(i), ...
        formal.d_estimate_shift_m(i),formal.pair_pass(i));
end

fprintf(fid,'\nALL FORMAL v1.2 CHECKS PASS: %d\n',all_pass);

if all_pass
    fprintf(fid,'\nRecommended frozen FEM numerical world:\n');
    fprintf(fid,' Dxy = 800 m\n');
    fprintf(fid,' Hsoil = 400 m\n');
    fprintf(fid,' global hmax = 20 m\n');
    fprintf(fid,' electrode local hmax = 0.15 m\n');
    fprintf(fid,' local hmin = 0.0015 m\n');
    fprintf(fid,' local hcurve = 0.16\n');
    fprintf(fid,'\nNEXT: regenerate ALL 16 development FEM fields under these settings,\n');
    fprintf(fid,'then rerun the M1 full-field ceiling before any v5.0 conclusion.\n');
else
    fprintf(fid,'\nDO NOT freeze FEM yet. Inspect the failed formal component(s).\n');
end
fclose(fid);

fprintf('\n============================================================\n');
fprintf(' FEM v1.2 AUDIT COMPLETE\n');
fprintf(' ALL FORMAL CHECKS PASS: %d\n',all_pass);
fprintf(' Results: %s\n',out_dir);
fprintf(' HELD-OUT 84 REMAIN UNTOUCHED\n');
fprintf('============================================================\n');

%% ================================================================
% M1+b0 FULL-FIELD FIT
% ================================================================
function f=fit_field_m1(T)

    P=[T.x_m T.y_m];
    V=T.V_fem_V;

    rho=T.rho_true_ohm_m(1);
    I=1;
    if ismember('Iinj_A',T.Properties.VariableNames), I=T.Iinj_A(1); end

    Llo=8; Lhi=30;
    dlo=0.5; dhi=1.5;

    sigma=max(0.01*sqrt(mean(V.^2)),1e-9);

    ang=(0:45:315).';
    starts=[ ...
        19*ones(8,1),ang,ones(8,1); ...
        10*ones(4,1),(0:90:270).',0.7*ones(4,1); ...
        29*ones(4,1),(45:90:315).',1.3*ones(4,1)];

    obj=@(z)obj_m1(z,P,V,rho,I,sigma,Llo,Lhi,dlo,dhi);

    opts=optimset('Display','off','MaxFunEvals',6000,'MaxIter',3000, ...
        'TolX',1e-8,'TolFun',1e-10);

    bestf=inf;
    bestz=starts(1,:);

    for k=1:size(starts,1)
        [zk,~]=fminsearch(obj,starts(k,:),opts);

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

    f.L=bestz(1);
    f.phi=mod(bestz(2),360);
    f.d=bestz(3);
end

function f=obj_m1(z,P,V,rho,I,sigma,Llo,Lhi,dlo,dhi)

    L=z(1);
    phi=mod(z(2),360);
    d=z(3);

    penalty=0;
    if L<Llo, penalty=penalty+1e8*(Llo-L)^2; end
    if L>Lhi, penalty=penalty+1e8*(L-Lhi)^2; end
    if d<dlo, penalty=penalty+1e8*(dlo-d)^2; end
    if d>dhi, penalty=penalty+1e8*(d-dhi)^2; end

    L=min(max(L,Llo),Lhi);
    d=min(max(d,dlo),dhi);

    Vbase=lineV(P,L,phi,d,rho,I);
    b0=mean(V-Vbase);
    r=(Vbase+b0-V)/sigma;

    f=mean(r.^2)+penalty;
end

function V=lineV(P,L,phi_deg,d,rho,I)

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
