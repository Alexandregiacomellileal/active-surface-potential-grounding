%% PAPER 1 - POST-HELD-OUT MEASUREMENT-NOISE STRESS TEST v1.0
% Secondary post-held-out stress test. Held-out 84 were already consumed.
% NO COMSOL. NO METHOD TUNING. Runner is restart-safe at case/noise/repetition level.
clear; clc;

fprintf('\n============================================================\n');
fprintf(' PAPER 1 - POST-HELD-OUT MEASUREMENT-NOISE STRESS v1.0\n');
fprintf(' SECONDARY ANALYSIS | HELD-OUT 84 ALREADY CONSUMED\n');
fprintf('============================================================\n\n');

script_dir=fileparts(mfilename('fullpath'));
stage_root=fileparts(script_dir);
workspace_root=stage_root;
while ~exist(fullfile(workspace_root,'01_COMSOL_FEM'),'dir')
    parent=fileparts(workspace_root);
    if strcmp(parent,workspace_root), error('Could not locate Paper 1 workspace root.'); end
    workspace_root=parent;
end

protocol_dir=fullfile(stage_root,'00_PROTOCOL');
results_root=fullfile(stage_root,'02_RESULTS');
if ~exist(results_root,'dir'), mkdir(results_root); end
protocol_file=fullfile(protocol_dir,'POST_HELDOUT_NOISE_PROTOCOL_v10.json');
pass_file=fullfile(protocol_dir,'NOISE_STRESS_PREFLIGHT_PASS.txt');
assert(exist(protocol_file,'file')==2,'Missing frozen protocol.');
assert(exist(pass_file,'file')==2,'Run verify_postheldout_noise_preflight_v10 first.');
cfg=jsondecode(fileread(protocol_file));
assert(strcmp(cfg.status,'FROZEN BEFORE MEASUREMENT-NOISE STRESS RESULTS'));

noise_levels=double(cfg.noise_model.noise_levels_pct_RMS(:)).';
nrep=double(cfg.noise_model.monte_carlo_repetitions_per_case_level);
global_seed=double(cfg.noise_model.global_rng_seed);
checkpoints=double(cfg.frozen_method.checkpoints(:));
assert(isequal(checkpoints,[6;8;10;15]) && cfg.frozen_method.primary_budget==15);
initial_xy=double(cfg.frozen_method.initial_seed_xy_m);

final_root=fullfile(workspace_root,'05_HeldOut84_FINAL_DO_NOT_TOUCH','FINAL_v5M80_N15');
fem_dir=fullfile(final_root,'02_FEM_RESULTS_FROZEN_v12');
dev_ids=sort([2 3 5 6 9 20 25 32 38 59 66 69 92 93 94 98].');
ff=dir(fullfile(fem_dir,'case_*_surface_potential_FROZEN_v12.csv'));
ids=[];
for kk=1:numel(ff)
    tok=regexp(ff(kk).name,'case_(\d+)_surface_potential_FROZEN_v12\.csv','tokens','once');
    if ~isempty(tok), ids(end+1,1)=str2double(tok{1}); end %#ok<AGROW>
end
expected_ids=sort(unique(ids));
assert(numel(expected_ids)==84 && ~any(ismember(expected_ids,dev_ids)) && ...
    isequal(sort([expected_ids;dev_ids]),(1:100).'),'Held-out ID guardrail failed.');

fprintf('Noise levels (%% RMS): %s\n',mat2str(noise_levels));
fprintf('Monte Carlo repetitions per positive level/case: %d\n',nrep);
fprintf('Total noisy paired tasks: %d\n',numel(expected_ids)*numel(noise_levels)*nrep);
fprintf('Intermediate performance is intentionally NOT printed. Stop/restart is safe.\n\n');

for il=1:numel(noise_levels)
    level=noise_levels(il);
    tag=noise_tag(level);
    level_dir=fullfile(results_root,tag);
    if ~exist(level_dir,'dir'), mkdir(level_dir); end

    for ic=1:numel(expected_ids)
        c=expected_ids(ic);
        fem_file=fullfile(fem_dir,sprintf('case_%03d_surface_potential_FROZEN_v12.csv',c));
        T=readtable(fem_file);
        assert(height(T)==956 && all(isfinite(T.V_fem_V)),'Invalid FEM case %d',c);
        P=[T.x_m T.y_m]; Vclean=T.V_fem_V;
        truth.L=T.L_true_m(1); truth.phi=mod(T.phi_true_deg(1),360);
        truth.d=T.d_true_m(1); truth.rho=T.rho_true_ohm_m(1); truth.I=T.Iinj_A(1);
        if ismember('run_order_col',T.Properties.VariableNames), run_order=T.run_order_col(1); else, run_order=ic; end
        rms_clean=max(sqrt(mean(Vclean.^2)),eps);
        sigma_noise=(level/100)*rms_clean;

        case_file=fullfile(level_dir,sprintf('case_%03d_noise_%s.mat',c,tag));
        protocol_version=cfg.protocol_version; %#ok<NASGU>
        noise_level_pct=level; %#ok<NASGU>
        completed_reps=0;
        active_long=table(); space_long=table();
        active_selection_idx=nan(nrep,15); space_selection_idx=nan(nrep,15);
        noise_seeds=nan(nrep,1); realized_noise_pct_RMS=nan(nrep,1);

        if exist(case_file,'file')
            R=load(case_file);
            assert(strcmp(R.protocol_version,cfg.protocol_version),'Protocol version mismatch in %s',case_file);
            assert(abs(R.noise_level_pct-level)<1e-12,'Noise-level mismatch in %s',case_file);
            completed_reps=R.completed_reps; active_long=R.active_long; space_long=R.space_long;
            active_selection_idx=R.active_selection_idx; space_selection_idx=R.space_selection_idx;
            noise_seeds=R.noise_seeds; realized_noise_pct_RMS=R.realized_noise_pct_RMS;
        end

        for rep=(completed_reps+1):nrep
            seed=mod(global_seed + c*100000 + il*1000 + rep, 2^32-1);
            if seed<1, seed=seed+1; end
            rng(seed,'twister');
            epsvec=sigma_noise*randn(size(Vclean));
            Vmeas=Vclean+epsvec;

            O=paper1_v5M80_noise_task_v10(P,Vclean,Vmeas,truth,run_order,c,initial_xy,checkpoints);
            A=O.active; B=O.space;
            A.rep=repmat(rep,height(A),1); A.noise_level_pct_RMS=repmat(level,height(A),1); A.noise_seed=repmat(seed,height(A),1);
            B.rep=repmat(rep,height(B),1); B.noise_level_pct_RMS=repmat(level,height(B),1); B.noise_seed=repmat(seed,height(B),1);
            A=movevars(A,{'noise_level_pct_RMS','rep','noise_seed'},'Before','n');
            B=movevars(B,{'noise_level_pct_RMS','rep','noise_seed'},'Before','n');
            active_long=[active_long;A]; %#ok<AGROW>
            space_long=[space_long;B]; %#ok<AGROW>
            active_selection_idx(rep,:)=O.active_selection.selected_index(:).';
            space_selection_idx(rep,:)=O.space_selection.selected_index(:).';
            noise_seeds(rep)=seed;
            realized_noise_pct_RMS(rep)=100*sqrt(mean(epsvec.^2))/rms_clean;
            completed_reps=rep;

            tmp=[case_file '.tmp.mat'];
            save(tmp,'protocol_version','noise_level_pct','completed_reps','active_long','space_long', ...
                'active_selection_idx','space_selection_idx','noise_seeds','realized_noise_pct_RMS','-v7');
            movefile(tmp,case_file,'f');
        end
        fprintf('Completed %s | case %3d | %d/%d reps\n',tag,c,completed_reps,nrep);
    end
end

fprintf('\nALL NOISY TASKS COMPLETE. Do not retune.\n');
fprintf('Now run: summarize_postheldout_noise_stress_v10\n');

function tag=noise_tag(level)
    s=sprintf('%.3f',level); s=strrep(s,'.','p');
    tag=['noise_' s '_pctRMS'];
end
