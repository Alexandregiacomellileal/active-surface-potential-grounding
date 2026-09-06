function OUT=paper1_v5M80_noise_task_v10(P,Vclean,Vmeas,truth,run_order,c,initial_xy,checkpoints)
% PAPER1_V5M80_NOISE_TASK_V10
% Frozen v5-M80 inverse/acquisition core copied from the final held-out
% evaluator. The ONLY scientific change is that fitting/acquisition sees
% Vmeas while truth/full-field evaluation remains referenced to Vclean.
%
% No COMSOL. No tuning. No access to unselected Vmeas values during fitting
% or Active candidate selection.

Mseg=80;
rc=0.01;
sigma_fraction=0.01; % frozen design scale, not the injected noise level

assert(size(P,1)==956 && numel(Vclean)==956 && numel(Vmeas)==956, ...
    'Expected the frozen 956-point candidate domain.');
assert(all(isfinite(Vclean)) && all(isfinite(Vmeas)),'Nonfinite potentials.');

P=double(P); Vclean=double(Vclean(:)); Vmeas=double(Vmeas(:));
checkpoints=double(checkpoints(:));

sigma_design=max(sigma_fraction*sqrt(mean(Vclean.^2)),1e-9);
D2=pairwise_sqdist(P);

initial_idx=zeros(size(initial_xy,1),1);
for k=1:size(initial_xy,1)
    d2=sum((P-initial_xy(k,:)).^2,2);
    [md2,idx]=min(d2);
    if md2>1e-12
        error('Fixed seed point (%.1f,%.1f) missing.',initial_xy(k,1),initial_xy(k,2));
    end
    initial_idx(k)=idx;
end

[TRactive,TSactive]=run_active_case(P,Vclean,Vmeas,D2,initial_idx,truth, ...
    run_order,c,checkpoints,Mseg,rc,sigma_design,'V5M80_VoronoiAOptimalActive');
[TRspace,TSspace]=run_space_case(P,Vclean,Vmeas,initial_idx,truth, ...
    run_order,c,checkpoints,Mseg,rc,sigma_design,'V5M80_SpaceMaximin');

OUT=struct();
OUT.active=TRactive;
OUT.active_selection=TSactive;
OUT.space=TRspace;
OUT.space_selection=TSspace;
OUT.sigma_design_V=sigma_design;
end

function [TR,TS]=run_active_case(P,Vclean,Vmeas,D2,initial_idx,truth,run_order,c, ...
    checkpoints,Mseg,rc,sigma_design,method_name)

    sel=initial_idx(:);
    [theta,b0,w]=fit_voronoi_segmented(P(sel,:),Vmeas(sel),P, ...
        truth.rho,truth.I,rc,Mseg,sigma_design,[], 'seed');

    selection_order=(1:6).';
    selected_index=sel(:);
    x_m=P(sel,1); y_m=P(sel,2);
    selection_type=repmat({'seed'},6,1);
    predicted_Atrace=nan(6,1); predicted_neff=nan(6,1);
    predicted_max_weight=nan(6,1); geometric_min_distance_m=nan(6,1);

    cp_rows={}; rr=0;
    for n=6:max(checkpoints)
        if ismember(n,checkpoints)
            rr=rr+1;
            row=result_metrics(n,theta,b0,w,truth,P(sel,:),Vmeas(sel),P,Vclean, ...
                truth.rho,truth.I,rc,Mseg);
            cp_rows(rr,:)=row; %#ok<AGROW>
        end
        if n==max(checkpoints), break; end

        remaining=setdiff((1:size(P,1)).',sel,'stable');
        [chosen,diag]=choose_voronoi_aoptimal_candidate_v5( ...
            P,D2,sel,remaining,theta,truth.rho,truth.I,rc,Mseg);
        sel(end+1,1)=chosen; %#ok<AGROW>

        selection_order(end+1,1)=n+1; %#ok<AGROW>
        selected_index(end+1,1)=chosen; %#ok<AGROW>
        x_m(end+1,1)=P(chosen,1); %#ok<AGROW>
        y_m(end+1,1)=P(chosen,2); %#ok<AGROW>
        selection_type{end+1,1}='active'; %#ok<AGROW>
        predicted_Atrace(end+1,1)=diag.best_trace; %#ok<AGROW>
        predicted_neff(end+1,1)=diag.predicted_neff; %#ok<AGROW>
        predicted_max_weight(end+1,1)=diag.predicted_max_weight; %#ok<AGROW>
        geometric_min_distance_m(end+1,1)=diag.min_distance_to_selected_m; %#ok<AGROW>

        next_n=n+1;
        if ismember(next_n,checkpoints), fit_mode='checkpoint'; else, fit_mode='sequential'; end
        [theta,b0,w]=fit_voronoi_segmented(P(sel,:),Vmeas(sel),P, ...
            truth.rho,truth.I,rc,Mseg,sigma_design,theta,fit_mode);
    end

    names=result_variable_names();
    TR=array2table(cell2mat(cp_rows),'VariableNames',names);
    TR.run_order=repmat(run_order,height(TR),1); TR.case_id=repmat(c,height(TR),1);
    TR.method=repmat({method_name},height(TR),1);
    TR.L_true_m=repmat(truth.L,height(TR),1); TR.phi_true_deg=repmat(truth.phi,height(TR),1);
    TR.d_true_m=repmat(truth.d,height(TR),1); TR.rho_true_ohm_m=repmat(truth.rho,height(TR),1);
    TR=movevars(TR,{'run_order','case_id','method','L_true_m','phi_true_deg','d_true_m','rho_true_ohm_m'},'Before','n');

    TS=table(selection_order,selected_index,x_m,y_m,selection_type,predicted_Atrace, ...
        predicted_neff,predicted_max_weight,geometric_min_distance_m);
    TS.run_order=repmat(run_order,height(TS),1); TS.case_id=repmat(c,height(TS),1);
    TS.method=repmat({method_name},height(TS),1);
    TS=movevars(TS,{'run_order','case_id','method'},'Before','selection_order');
end

function [TR,TS]=run_space_case(P,Vclean,Vmeas,initial_idx,truth,run_order,c, ...
    checkpoints,Mseg,rc,sigma_design,method_name)

    sel=initial_idx(:);
    selection_order=(1:6).'; selected_index=sel(:); x_m=P(sel,1); y_m=P(sel,2);
    selection_type=repmat({'seed'},6,1); predicted_Atrace=nan(6,1);
    predicted_neff=nan(6,1); predicted_max_weight=nan(6,1);
    geometric_min_distance_m=nan(6,1);

    while numel(sel)<max(checkpoints)
        remaining=setdiff((1:size(P,1)).',sel,'stable');
        [chosen,min_dist]=choose_space_maximin(P,sel,remaining);
        sel(end+1,1)=chosen; %#ok<AGROW>
        selection_order(end+1,1)=numel(sel); selected_index(end+1,1)=chosen; %#ok<AGROW>
        x_m(end+1,1)=P(chosen,1); y_m(end+1,1)=P(chosen,2); %#ok<AGROW>
        selection_type{end+1,1}='space'; predicted_Atrace(end+1,1)=NaN; %#ok<AGROW>
        predicted_neff(end+1,1)=NaN; predicted_max_weight(end+1,1)=NaN; %#ok<AGROW>
        geometric_min_distance_m(end+1,1)=min_dist; %#ok<AGROW>
    end

    cp_rows={}; theta_prev=[];
    for jj=1:numel(checkpoints)
        n=checkpoints(jj); seln=sel(1:n);
        if isempty(theta_prev), mode='seed'; else, mode='checkpoint'; end
        [theta,b0,w]=fit_voronoi_segmented(P(seln,:),Vmeas(seln),P, ...
            truth.rho,truth.I,rc,Mseg,sigma_design,theta_prev,mode);
        theta_prev=theta;
        cp_rows(jj,:)=result_metrics(n,theta,b0,w,truth,P(seln,:),Vmeas(seln),P,Vclean, ...
            truth.rho,truth.I,rc,Mseg); %#ok<AGROW>
    end

    names=result_variable_names();
    TR=array2table(cell2mat(cp_rows),'VariableNames',names);
    TR.run_order=repmat(run_order,height(TR),1); TR.case_id=repmat(c,height(TR),1);
    TR.method=repmat({method_name},height(TR),1);
    TR.L_true_m=repmat(truth.L,height(TR),1); TR.phi_true_deg=repmat(truth.phi,height(TR),1);
    TR.d_true_m=repmat(truth.d,height(TR),1); TR.rho_true_ohm_m=repmat(truth.rho,height(TR),1);
    TR=movevars(TR,{'run_order','case_id','method','L_true_m','phi_true_deg','d_true_m','rho_true_ohm_m'},'Before','n');

    TS=table(selection_order,selected_index,x_m,y_m,selection_type,predicted_Atrace, ...
        predicted_neff,predicted_max_weight,geometric_min_distance_m);
    TS.run_order=repmat(run_order,height(TS),1); TS.case_id=repmat(c,height(TS),1);
    TS.method=repmat({method_name},height(TS),1);
    TS=movevars(TS,{'run_order','case_id','method'},'Before','selection_order');
end

function [chosen,diag]=choose_voronoi_aoptimal_candidate_v5(Pdomain,D2,sel,remaining,theta,rho,I,rc,Mseg)
    n=numel(sel); Ndom=size(Pdomain,1);
    [dmin2,owner]=min(D2(:,sel),[],2);
    counts_current=accumarray(owner,1,[n,1]);
    Jsel=numerical_jacobian_segmented(Pdomain(sel,:),theta,rho,I,rc,Mseg);
    Gsel=[Jsel,ones(n,1)];
    Jcand=numerical_jacobian_segmented(Pdomain(remaining,:),theta,rho,I,rc,Mseg);
    Gcand=[Jcand,ones(numel(remaining),1)];
    H=endpoint_transform_jacobian(theta);
    traces=inf(numel(remaining),1); neffs=zeros(numel(remaining),1); maxws=zeros(numel(remaining),1);
    for k=1:numel(remaining)
        idx=remaining(k); d2c=D2(:,idx);
        steal=(d2c < dmin2 - 1e-12);
        lost=accumarray(owner(steal),1,[n,1]); cnew=sum(steal);
        counts=[counts_current-lost; cnew];
        if any(counts<=0), error('Unexpected nonpositive hypothetical Voronoi cell count.'); end
        w=counts/Ndom; wn=(n+1)*w;
        G=[Gsel;Gcand(k,:)];
        F=G.'*(bsxfun(@times,G,wn));
        C=pinv(F+1e-12*eye(4));
        Ctheta=C(1:3,1:3); Cq=H*Ctheta*H.';
        traces(k)=trace(Cq); neffs(k)=1/sum(w.^2); maxws(k)=max(w);
    end
    best_trace=min(traces); tol=1e-12*max(1,abs(best_trace));
    cand=find(abs(traces-best_trace)<=tol); kbest=cand(1);
    chosen=remaining(kbest);
    dsel=sqrt(sum((Pdomain(sel,:)-Pdomain(chosen,:)).^2,2));
    diag.best_trace=traces(kbest); diag.predicted_neff=neffs(kbest);
    diag.predicted_max_weight=maxws(kbest); diag.min_distance_to_selected_m=min(dsel);
end

function [chosen,min_dist]=choose_space_maximin(P,sel,remaining)
    dmin=inf(numel(remaining),1);
    for j=1:numel(sel)
        d=sqrt(sum((P(remaining,:)-P(sel(j),:)).^2,2)); dmin=min(dmin,d);
    end
    best=max(dmin); tol=1e-12*max(1,best); cand=find(abs(dmin-best)<=tol);
    kbest=cand(1); chosen=remaining(kbest); min_dist=dmin(kbest);
end

function [theta,b0,w]=fit_voronoi_segmented(P,Vobs,Pdomain,rho,Iinj,rc,M,sigma_design,theta_prev,mode)
    Llo=8; Lhi=30; dlo=0.5; dhi=1.5;
    w=discrete_voronoi_weights(P,Pdomain); wn=size(P,1)*w;
    if isempty(theta_prev) || strcmp(mode,'seed')
        ang=(0:45:315).';
        starts1=[19*ones(8,1),ang,ones(8,1)];
        starts2=[10*ones(4,1),(0:90:270).',0.7*ones(4,1)];
        starts3=[29*ones(4,1),(45:90:315).',1.3*ones(4,1)];
        starts=[starts1;starts2;starts3];
    elseif strcmp(mode,'sequential')
        starts=theta_prev;
    else
        tp=theta_prev;
        starts=[tp; tp(1),mod(tp(2)+10,360),tp(3); tp(1),mod(tp(2)-10,360),tp(3); ...
            min(30,tp(1)+1),tp(2),tp(3); max(8,tp(1)-1),tp(2),tp(3); ...
            tp(1),tp(2),min(1.5,tp(3)+0.10); tp(1),tp(2),max(0.5,tp(3)-0.10)];
    end
    obj=@(z)objective_voronoi_segmented(z,P,Vobs,wn,rho,Iinj,rc,M,sigma_design,Llo,Lhi,dlo,dhi);
    if strcmp(mode,'sequential'), maxfe=1800; maxit=900; else, maxfe=6000; maxit=3000; end
    opts=optimset('Display','off','MaxFunEvals',maxfe,'MaxIter',maxit,'TolX',1e-8,'TolFun',1e-10);
    bestf=inf; bestz=starts(1,:);
    for k=1:size(starts,1)
        [zk,~]=fminsearch(obj,starts(k,:),opts);
        zc=zk; zc(1)=min(max(zc(1),Llo),Lhi); zc(2)=mod(zc(2),360); zc(3)=min(max(zc(3),dlo),dhi);
        fc=obj(zc);
        if fc<bestf, bestf=fc; bestz=zc; end
    end
    theta=bestz;
    Vbase=segmented_surface_V(P,theta(1),theta(2),theta(3),rho,Iinj,rc,M);
    b0=sum(wn.*(Vobs-Vbase))/sum(wn);
end

function f=objective_voronoi_segmented(z,P,Vobs,wn,rho,Iinj,rc,M,sigma_design,Llo,Lhi,dlo,dhi)
    L=z(1); phi=mod(z(2),360); d=z(3); penalty=0;
    if L<Llo, penalty=penalty+1e8*(Llo-L)^2; elseif L>Lhi, penalty=penalty+1e8*(L-Lhi)^2; end
    if d<dlo, penalty=penalty+1e8*(dlo-d)^2; elseif d>dhi, penalty=penalty+1e8*(d-dhi)^2; end
    Lc=min(max(L,Llo),Lhi); dc=min(max(d,dlo),dhi);
    try
        Vbase=segmented_surface_V(P,Lc,phi,dc,rho,Iinj,rc,M);
        if any(~isfinite(Vbase)), f=1e30; return; end
        b0=sum(wn.*(Vobs-Vbase))/sum(wn);
        rr=(Vbase+b0-Vobs)/sigma_design;
        f=sum(wn.*rr.^2)/sum(wn)+penalty;
    catch
        f=1e30;
    end
end

function w=discrete_voronoi_weights(Psel,Pdomain)
    n=size(Psel,1); counts=zeros(n,1);
    for q=1:size(Pdomain,1)
        d2=sum((Psel-Pdomain(q,:)).^2,2); [~,j]=min(d2); counts(j)=counts(j)+1;
    end
    w=counts/sum(counts); if any(w<=0), error('Unexpected zero discrete Voronoi weight.'); end
end

function V=segmented_surface_V(P,L,phi_deg,d,rho,Iinj,rc,M)
    [frac,dl]=segment_current_fractions(L,d,rc,M);
    ph=phi_deg*pi/180; x=P(:,1); y=P(:,2);
    sproj=x*cos(ph)+y*sin(ph); perp2=max(x.^2+y.^2-sproj.^2,0);
    b=sqrt(max(perp2+d.^2,1e-14)); s0=(0:M-1)*dl; a=bsxfun(@minus,sproj,s0);
    integ=asinh(bsxfun(@rdivide,dl-a,b))+asinh(bsxfun(@rdivide,a,b));
    V=rho*Iinj/(2*pi*dl)*(integ*frac);
end

function [frac,dl]=segment_current_fractions(L,d,rc,M)
    dl=L/M; target_s=((1:M)-0.5)'*dl; source_s=(0:M-1)*dl;
    a=bsxfun(@minus,target_s,source_s);
    b_direct=rc; b_image=sqrt((2*d)^2+rc^2);
    direct=asinh((dl-a)/b_direct)+asinh(a/b_direct);
    image=asinh((dl-a)/b_image)+asinh(a/b_image);
    G=(direct+image)/(4*pi*dl);
    A=[G,-ones(M,1);ones(1,M),0]; rhs=[zeros(M,1);1];
    if rcond(A)<1e-14, sol=pinv(A)*rhs; else, sol=A\rhs; end
    frac=sol(1:M); frac=frac/sum(frac);
    if any(~isfinite(frac)), error('Invalid segmented current distribution.'); end
end

function J=numerical_jacobian_segmented(P,theta,rho,Iinj,rc,M)
    steps=[1e-3,1e-3,1e-4]; J=zeros(size(P,1),3);
    for k=1:3
        zp=theta; zm=theta; zp(k)=zp(k)+steps(k); zm(k)=zm(k)-steps(k);
        if k==2, zp(2)=mod(zp(2),360); zm(2)=mod(zm(2),360); end
        Vp=segmented_surface_V(P,zp(1),zp(2),zp(3),rho,Iinj,rc,M);
        Vm=segmented_surface_V(P,zm(1),zm(2),zm(3),rho,Iinj,rc,M);
        J(:,k)=(Vp-Vm)/(2*steps(k));
    end
end

function H=endpoint_transform_jacobian(theta)
    L=theta(1); ph=theta(2)*pi/180;
    H=[cos(ph),-L*sin(ph)*pi/180,0; sin(ph),L*cos(ph)*pi/180,0; 0,0,1];
end

function D2=pairwise_sqdist(P)
    xx=sum(P.^2,2); D2=bsxfun(@plus,xx,xx.')-2*(P*P.'); D2=max(D2,0);
end

function row=result_metrics(n,theta,b0,w,truth,Psel,Vsel_meas,Pdomain,Vdomain_clean,rho,I,rc,M)
    Lhat=theta(1); phihat=mod(theta(2),360); dhat=theta(3);
    eL=abs(Lhat-truth.L); ephi=circular_difference(phihat,truth.phi); ed=abs(dhat-truth.d);
    ptrue=[truth.L*cosd(truth.phi),truth.L*sind(truth.phi)];
    phat=[Lhat*cosd(phihat),Lhat*sind(phihat)]; eend=norm(phat-ptrue);

    Vhat_sel=segmented_surface_V(Psel,Lhat,phihat,dhat,rho,I,rc,M)+b0;
    rr_sel=Vhat_sel-Vsel_meas; rmse_sel=sqrt(mean(rr_sel.^2));
    rmse_sel_pct=100*rmse_sel/max(sqrt(mean(Vsel_meas.^2)),eps);
    wn=n*w; wrmse_sel=sqrt(sum(wn.*rr_sel.^2)/sum(wn));

    % Evaluation-only diagnostic against the clean 956-point FEM field.
    Vhat_full=segmented_surface_V(Pdomain,Lhat,phihat,dhat,rho,I,rc,M)+b0;
    rr_full=Vhat_full-Vdomain_clean; rmse_full=sqrt(mean(rr_full.^2));
    rmse_full_pct=100*rmse_full/max(sqrt(mean(Vdomain_clean.^2)),eps);

    neff=1/sum(w.^2); maxw=max(w); [frac,~]=segment_current_fractions(Lhat,dhat,rc,M); negI=sum(frac<0);
    row={n,Lhat,phihat,dhat,b0,eL,ephi,ed,eend,rmse_sel,rmse_sel_pct,wrmse_sel,rmse_full_pct,neff,maxw,negI,eend<=0.25};
end

function names=result_variable_names()
    names={'n','L_hat_m','phi_hat_deg','d_hat_m','offset_V','L_abs_error_m','phi_abs_error_deg', ...
        'd_abs_error_m','endpoint_error_m','rmse_selected_V','rmse_selected_pct_RMS', ...
        'weighted_rmse_selected_V','fullfield_RMSE_pct_RMS','voronoi_weight_neff', ...
        'voronoi_max_weight','n_negative_current_fractions','passes_endpoint_0p25'};
end

function d=circular_difference(a,b)
    d=abs(a-b); d=min(d,360-d);
end
