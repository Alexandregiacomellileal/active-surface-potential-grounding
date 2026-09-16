#!/usr/bin/env python3
"""Reproduce the deterministic physical full-grid v5-M80 inversion."""
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
import math, os, json
import numpy as np
import pandas as pd
from scipy.optimize import minimize
from scipy.linalg import solve as scipy_solve

RHO=100.0; RC=0.006; HP=0.03; MSEG=80
PENALTY=1e8; XATOL=1e-8; FATOL=1e-10; MAXITER=3000; MAXFEV=6000
LB=(1.0,4.0); DB=(0.05,0.80); RREF={.20:44.1,.30:41.6,.40:40.1}
RAW={.20:'Dados_Brutos',.30:'Dados_Brutos_D030',.40:'Dados_Brutos_D040'}

def read_campaign(workbook,d):
    q=pd.read_excel(workbook,sheet_name=RAW[d],header=3,engine='openpyxl')
    x=pd.to_numeric(q.iloc[:289,4],errors='raise').to_numpy(float)
    y=pd.to_numeric(q.iloc[:289,5],errors='raise').to_numpy(float)
    r=pd.to_numeric(q.iloc[:289,6],errors='raise').to_numpy(float)
    return np.c_[x,y], RREF[d]-r

def segment_current_fractions(L,d):
    dl=L/MSEG; target=((np.arange(1,MSEG+1)-.5)*dl)[:,None]; source=(np.arange(MSEG)*dl)[None,:]
    a=target-source; direct=np.arcsinh((dl-a)/RC)+np.arcsinh(a/RC)
    bimg=math.sqrt((2*d)**2+RC**2); image=np.arcsinh((dl-a)/bimg)+np.arcsinh(a/bimg)
    G=(direct+image)/(4*np.pi*dl)
    A=np.block([[G,-np.ones((MSEG,1))],[np.ones((1,MSEG)),np.zeros((1,1))]])
    rhs=np.r_[np.zeros(MSEG),1.0]
    try: sol=scipy_solve(A,rhs,assume_a='gen',check_finite=False)
    except Exception: sol=np.linalg.pinv(A)@rhs
    f=sol[:MSEG]; f/=f.sum(); return f,dl

def response(P,L,phi,d):
    if d<=HP: return np.full(len(P),np.nan)
    f,dl=segment_current_fractions(L,d); ph=np.deg2rad(phi%360.); x=P[:,0]; y=P[:,1]
    s=x*np.cos(ph)+y*np.sin(ph); perp=np.maximum(x*x+y*y-s*s,0.)
    b=np.sqrt(np.maximum(perp+(d-HP)**2,1e-14)); a=s[:,None]-np.arange(MSEG)[None,:]*dl
    integ=np.arcsinh((dl-a)/b[:,None])+np.arcsinh(a/b[:,None])
    return RHO/(2*np.pi*dl)*(integ@f)

def starts():
    Lv=[LB[0]+q*(LB[1]-LB[0]) for q in (.25,.5,.75)]; dv=[DB[0]+q*(DB[1]-DB[0]) for q in (.25,.5,.75)]
    return np.array([[L,p,d] for L in Lv for d in dv for p in np.arange(0,360,45)],float)

def objective(P,z):
    sigma=max(.01*math.sqrt(float(np.mean(z*z))),1e-9)
    def f(raw):
        L,phi,d=map(float,raw); pen=0.
        if L<LB[0]: pen+=PENALTY*(LB[0]-L)**2
        elif L>LB[1]: pen+=PENALTY*(L-LB[1])**2
        if d<DB[0]: pen+=PENALTY*(DB[0]-d)**2
        elif d>DB[1]: pen+=PENALTY*(d-DB[1])**2
        try:
            v=response(P,np.clip(L,*LB),phi%360.,np.clip(d,*DB))
            b0=float(np.mean(z-v)); rr=(v+b0-z)/sigma
            return float(np.mean(rr*rr)+pen)
        except Exception: return 1e30
    return f

def run_one(j,s,P,z):
    f=objective(P,z); r=minimize(f,s,method='Nelder-Mead',options={'maxiter':MAXITER,'maxfev':MAXFEV,'xatol':XATOL,'fatol':FATOL})
    x=np.array(r.x,float); x[0]=np.clip(x[0],*LB); x[1]%=360.; x[2]=np.clip(x[2],*DB)
    return j,float(f(x)),x

def circerr(p):
    e=abs(p%360.); return min(e,360-e)

def enderr(L,p):
    return math.hypot(L*math.cos(math.radians(p))-2.4,L*math.sin(math.radians(p)))

def main():
    here=Path(__file__).resolve().parent; repo=here.parents[2]
    workbook=repo/'comparacao_real_MTR1522_D020_D030_D040_FINAL.xlsx'; out=here.parent/'results'; out.mkdir(exist_ok=True)
    S=starts(); rows=[]
    for d in (.20,.30,.40):
        P,z=read_campaign(workbook,d); found=[]
        with ThreadPoolExecutor(max_workers=min(32,os.cpu_count() or 4)) as ex:
            fut=[ex.submit(run_one,j,s,P,z) for j,s in enumerate(S,1)]
            for q in as_completed(fut): found.append(q.result())
        best=min(found,key=lambda t:t[1]); j,obj,x=best; L,p,dh=x
        v=response(P,L,p,dh); b0=float(np.mean(z-v)); rmse=float(np.sqrt(np.mean((v+b0-z)**2))); de=abs(dh-d)
        rows.append(dict(protocol='main',true_depth_m=d,L_hat_m=L,phi_hat_deg=p,d_hat_m=dh,
                         L_abs_error_m=abs(L-2.4),phi_abs_error_deg=circerr(p),d_abs_error_m=de,
                         d_rel_error_pct=100*de/d,endpoint_error_m=enderr(L,p),b0_ohm=b0,
                         field_RMSE_ohm=rmse,objective=obj,n_starts=72,best_start_id=j))
    tab=pd.DataFrame(rows); tab.to_csv(out/'reproduced_main.csv',index=False)
    agg={'mean_relative_depth_error_pct':float(tab.d_rel_error_pct.mean()),
         'mean_absolute_depth_error_cm':float(100*tab.d_abs_error_m.mean()),
         'max_endpoint_error_m':float(tab.endpoint_error_m.max()),
         'mean_endpoint_error_m':float(tab.endpoint_error_m.mean()),
         'max_phi_abs_error_deg':float(tab.phi_abs_error_deg.max())}
    (out/'reproduced_aggregate.json').write_text(json.dumps(agg,indent=2),encoding='utf-8')
    print(tab[['true_depth_m','L_hat_m','phi_hat_deg','d_hat_m','d_rel_error_pct','endpoint_error_m']].to_string(index=False))
    print(json.dumps(agg,indent=2))
if __name__=='__main__': main()
