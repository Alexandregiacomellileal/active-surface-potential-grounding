%% PAPER 1 - SUMMARIZE POST-HELD-OUT MEASUREMENT-NOISE STRESS v1.0
% Reporting only. Requires all frozen 30-repetition noisy tasks to be complete.
clear; clc; close all;

script_dir=fileparts(mfilename('fullpath'));
stage_root=fileparts(script_dir);
workspace_root=stage_root;
while ~exist(fullfile(workspace_root,'01_COMSOL_FEM'),'dir')
    parent=fileparts(workspace_root); if strcmp(parent,workspace_root), error('Could not locate workspace root.'); end
    workspace_root=parent;
end
protocol_dir=fullfile(stage_root,'00_PROTOCOL'); results_root=fullfile(stage_root,'02_RESULTS');
paper_dir=fullfile(stage_root,'03_PAPER_OUTPUTS'); if ~exist(paper_dir,'dir'), mkdir(paper_dir); end
cfg=jsondecode(fileread(fullfile(protocol_dir,'POST_HELDOUT_NOISE_PROTOCOL_v10.json')));
noise_levels=double(cfg.noise_model.noise_levels_pct_RMS(:)).'; nrep=double(cfg.noise_model.monte_carlo_repetitions_per_case_level);
Bboot=double(cfg.reporting.bootstrap_repetitions); boot_seed=double(cfg.reporting.bootstrap_rng_seed);

final_root=fullfile(workspace_root,'05_HeldOut84_FINAL_DO_NOT_TOUCH','FINAL_v5M80_N15');
fem_dir=fullfile(final_root,'02_FEM_RESULTS_FROZEN_v12'); final_results=fullfile(final_root,'04_FINAL_RESULTS');
ff=dir(fullfile(fem_dir,'case_*_surface_potential_FROZEN_v12.csv')); ids=[];
for kk=1:numel(ff)
    tok=regexp(ff(kk).name,'case_(\d+)_surface_potential_FROZEN_v12\.csv','tokens','once');
    if ~isempty(tok), ids(end+1,1)=str2double(tok{1}); end %#ok<AGROW>
end
ids=sort(unique(ids)); assert(numel(ids)==84);

TallA=table(); TallS=table();
for il=1:numel(noise_levels)
    level=noise_levels(il); tag=noise_tag(level); level_dir=fullfile(results_root,tag);
    for c=ids.'
        f=fullfile(level_dir,sprintf('case_%03d_noise_%s.mat',c,tag));
        if ~exist(f,'file'), error('Incomplete study: missing %s',f); end
        R=load(f);
        if R.completed_reps~=nrep, error('Incomplete %s: %d/%d reps',f,R.completed_reps,nrep); end
        A=R.active_long(R.active_long.n==15,:); S=R.space_long(R.space_long.n==15,:);
        assert(height(A)==nrep && height(S)==nrep);
        TallA=[TallA;A]; TallS=[TallS;S]; %#ok<AGROW>
    end
end
TallA.method(:)={'Active'}; TallS.method(:)={'Space'};
Tnoise=[TallA;TallS];
Tnoise.joint_success=(Tnoise.endpoint_error_m<=0.25) & (Tnoise.d_abs_error_m<=0.05) & (Tnoise.phi_abs_error_deg<=0.10);
writetable(Tnoise,fullfile(paper_dir,'NOISE_STRESS_all_N15_noisy.csv'));

% Add already-disclosed 0% frozen final reference (one observation per case).
A0=readtable(fullfile(final_results,'FINAL_HELDOUT84_ACTIVE_N15_casewise.csv'));
S0=readtable(fullfile(final_results,'FINAL_HELDOUT84_SPACE_N15_casewise.csv'));
A0.noise_level_pct_RMS=zeros(height(A0),1); A0.rep=ones(height(A0),1); A0.method=repmat({'Active'},height(A0),1);
S0.noise_level_pct_RMS=zeros(height(S0),1); S0.rep=ones(height(S0),1); S0.method=repmat({'Space'},height(S0),1);
A0.joint_success=(A0.endpoint_error_m<=0.25)&(A0.d_abs_error_m<=0.05)&(A0.phi_abs_error_deg<=0.10);
S0.joint_success=(S0.endpoint_error_m<=0.25)&(S0.d_abs_error_m<=0.05)&(S0.phi_abs_error_deg<=0.10);

levels=[0 noise_levels]; methods={'Active','Space'}; rows={}; rr=0;
rng(boot_seed,'twister');
for im=1:2
    meth=methods{im};
    for il=1:numel(levels)
        lev=levels(il);
        if lev==0
            if strcmp(meth,'Active'), X=A0; else, X=S0; end
        else
            X=Tnoise(strcmp(Tnoise.method,meth)&abs(Tnoise.noise_level_pct_RMS-lev)<1e-12,:);
        end
        [p,lo,hi]=cluster_mean_ci(double(X.joint_success),X.case_id,Bboot);
        rr=rr+1;
        rows(rr,:)={meth,lev,numel(unique(X.case_id)),height(X),p,lo,hi, ...
            median(X.endpoint_error_m),pct_simple(X.endpoint_error_m,90),max(X.endpoint_error_m), ...
            median(X.d_abs_error_m),pct_simple(X.d_abs_error_m,90),max(X.d_abs_error_m), ...
            median(X.phi_abs_error_deg),pct_simple(X.phi_abs_error_deg,90),max(X.phi_abs_error_deg)}; %#ok<AGROW>
    end
end
S=cell2table(rows,'VariableNames',{'method','noise_pct_RMS','N_cases','N_rows','joint_success_fraction','CI95_low','CI95_high', ...
    'median_endpoint_m','P90_endpoint_m','max_endpoint_m','median_depth_m','P90_depth_m','max_depth_m', ...
    'median_phi_deg','P90_phi_deg','max_phi_deg'});
for j=2:width(S), vn=S.Properties.VariableNames{j}; if iscell(S.(vn)), try, S.(vn)=cell2mat(S.(vn)); catch, end, end, end
writetable(S,fullfile(paper_dir,'NOISE_STRESS_summary_by_level.csv'));

% Paired Active-minus-Space joint-success difference under common noise.
pairrows={}; rp=0;
for il=1:numel(levels)
    lev=levels(il);
    if lev==0
        A=sortrows(A0,{'case_id','rep'}); B=sortrows(S0,{'case_id','rep'});
    else
        A=sortrows(Tnoise(strcmp(Tnoise.method,'Active')&abs(Tnoise.noise_level_pct_RMS-lev)<1e-12,:),{'case_id','rep'});
        B=sortrows(Tnoise(strcmp(Tnoise.method,'Space')&abs(Tnoise.noise_level_pct_RMS-lev)<1e-12,:),{'case_id','rep'});
    end
    assert(isequal(A.case_id,B.case_id)&&isequal(A.rep,B.rep));
    d=double(A.joint_success)-double(B.joint_success);
    [mu,lo,hi]=cluster_mean_ci(d,A.case_id,Bboot);
    rp=rp+1; pairrows(rp,:)={lev,mu,lo,hi,sum(d==1),sum(d==-1),sum(d==0)}; %#ok<AGROW>
end
P=cell2table(pairrows,'VariableNames',{'noise_pct_RMS','active_minus_space_success','CI95_low','CI95_high','active_only_rows','space_only_rows','ties_rows'});
for j=1:width(P), vn=P.Properties.VariableNames{j}; if iscell(P.(vn)), try, P.(vn)=cell2mat(P.(vn)); catch, end, end, end
writetable(P,fullfile(paper_dir,'NOISE_STRESS_paired_success.csv'));

% Main publication figure: joint success vs measurement noise.
f1=figure('Color','w','Position',[100 100 780 500]); hold on;
for im=1:2
    X=S(strcmp(S.method,methods{im}),:); X=sortrows(X,'noise_pct_RMS');
    y=100*X.joint_success_fraction; lo=100*(X.joint_success_fraction-X.CI95_low); hi=100*(X.CI95_high-X.joint_success_fraction);
    errorbar(X.noise_pct_RMS,y,lo,hi,'-o','LineWidth',1.8,'MarkerSize',6,'DisplayName',methods{im});
end
grid on; box on; xlabel('Added potential-noise standard deviation (% of clean field RMS)');
ylabel('Joint success at N=15 (%)'); legend('Location','best');
exportgraphics(f1,fullfile(paper_dir,'Fig_noise_joint_success.pdf'),'ContentType','vector');
exportgraphics(f1,fullfile(paper_dir,'Fig_noise_joint_success.png'),'Resolution',600);

% Depth-error figure: median and P90 for each method.
f2=figure('Color','w','Position',[100 100 780 500]); hold on;
for im=1:2
    X=S(strcmp(S.method,methods{im}),:); X=sortrows(X,'noise_pct_RMS');
    plot(X.noise_pct_RMS,100*X.median_depth_m,'-o','LineWidth',1.8,'DisplayName',[methods{im} ' median']);
    plot(X.noise_pct_RMS,100*X.P90_depth_m,'--s','LineWidth',1.5,'DisplayName',[methods{im} ' P90']);
end
yline(5,'--','Frozen depth threshold'); grid on; box on;
xlabel('Added potential-noise standard deviation (% of clean field RMS)'); ylabel('Depth error (cm)');
legend('Location','best');
exportgraphics(f2,fullfile(paper_dir,'Fig_noise_depth_error.pdf'),'ContentType','vector');
exportgraphics(f2,fullfile(paper_dir,'Fig_noise_depth_error.png'),'Resolution',600);

fid=fopen(fullfile(paper_dir,'NOISE_STRESS_REPORT.txt'),'w');
fprintf(fid,'PAPER 1 - POST-HELD-OUT MEASUREMENT-NOISE STRESS REPORT\n');
fprintf(fid,'=========================================================\n');
fprintf(fid,'SECONDARY POST-HELD-OUT analysis. Held-out 84 were already consumed.\n');
fprintf(fid,'No COMSOL regeneration and no method retuning.\n');
fprintf(fid,'Positive noise levels: %s %% RMS; %d MC reps/case/level.\n',mat2str(noise_levels),nrep);
fprintf(fid,'95%% CIs: cluster bootstrap over 84 cases, B=%d.\n\n',Bboot);
for il=1:numel(levels)
    lev=levels(il); a=S(strcmp(S.method,'Active')&S.noise_pct_RMS==lev,:); b=S(strcmp(S.method,'Space')&S.noise_pct_RMS==lev,:);
    fprintf(fid,'Noise %.2f%% | Active joint %.2f%% [%.2f, %.2f] | Space %.2f%% [%.2f, %.2f]\n', ...
        lev,100*a.joint_success_fraction,100*a.CI95_low,100*a.CI95_high,100*b.joint_success_fraction,100*b.CI95_low,100*b.CI95_high);
end
fprintf(fid,'\nDo not reinterpret this as an independent held-out validation.\n');
fclose(fid);

fprintf('Summary complete: %s\n',paper_dir);

function tag=noise_tag(level)
    s=sprintf('%.3f',level); s=strrep(s,'.','p'); tag=['noise_' s '_pctRMS'];
end
function [mu,lo,hi]=cluster_mean_ci(y,caseid,B)
    ids=unique(caseid); cm=zeros(numel(ids),1);
    for k=1:numel(ids), cm(k)=mean(y(caseid==ids(k))); end
    mu=mean(cm); boot=zeros(B,1); n=numel(cm);
    for b=1:B, boot(b)=mean(cm(randi(n,n,1))); end
    lo=pct_simple(boot,2.5); hi=pct_simple(boot,97.5);
end
function p=pct_simple(x,q)
    x=sort(x(isfinite(x))); if isempty(x), p=NaN; return; end
    if numel(x)==1, p=x(1); return; end
    pos=1+(q/100)*(numel(x)-1); lo=floor(pos); hi=ceil(pos);
    if lo==hi, p=x(lo); else, a=pos-lo; p=(1-a)*x(lo)+a*x(hi); end
end
