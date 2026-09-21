#!/usr/bin/env python3
"""Inventory literal ACME variable reads and source evidence for writes.

Evidence is separated into literal writes, compatible format templates, documented external
hooks, and missing evidence. A compatible format template does not prove that a particular
key is written in a running mission. Defaults do not prove that a read is a tuning knob.
This tool does not evaluate dynamic code, general dataflow, namespaces' concrete objects,
preprocessed runtime code, or callback reachability.
"""
from __future__ import annotations
import argparse
from collections import defaultdict
from pathlib import Path
import json
import re
from source_scan import Token, code_streams, matching, render, source_files, split_args

NAMESPACES={'missionnamespace','uinamespace','profilenamespace','missionprofilenamespace',
            'parsingnamespace','servernamespace','localnamespace'}
SETTING_TYPES={'CHECKBOX','SLIDER','LIST','COLOR','EDITBOX'}

def receiver(tokens:list[Token])->str:
    if tokens and tokens[-1].value.lower() in NAMESPACES:return tokens[-1].value.lower()
    return 'entity'

def key_pattern(tokens:list[Token])->tuple[str,str]|None:
    if len(tokens)==1 and tokens[0].kind=='string':return ('literal',tokens[0].value)
    if len(tokens)>=3 and tokens[0].value.lower()=='format' and tokens[1].value=='[' and tokens[2].kind=='string':
        pattern=tokens[2].value
        if re.search(r'%\d+',pattern):return ('format',pattern)
        return ('literal',pattern)
    return None

def format_regex(pattern:str)->re.Pattern:
    # Conservative pattern evidence. The actual format argument domain is not inferred.
    out=[];last=0
    for m in re.finditer(r'%\d+',pattern):
        out.append(re.escape(pattern[last:m.start()]));out.append(r'[^\s"\[\],]*');last=m.end()
    out.append(re.escape(pattern[last:]));return re.compile('^'+''.join(out)+'$',re.I)

def foreach_names(ts:list[Token],at:int,pairs:dict[int,int],key:str)->list[str]:
    # Resolve explicit name lists and params-bound columns of literal tuple lists.
    # General dataflow, reassigned keys and computed list sources remain unresolved.
    enclosing=sorted((i,j) for i,j in pairs.items() if i<at<j and ts[i].value=='{')
    for begin,end in reversed(enclosing):
        k=end+1
        if k+1>=len(ts) or ts[k].value.lower()!='foreach' or ts[k+1].value!='[':continue
        lo=k+1;hi=pairs.get(lo)
        if hi is None:continue
        parts=split_args(ts,lo+1,hi,pairs)
        if key=='_x' and all(len(x)==1 and x[0].kind=='string' for x in parts):return [x[0].value for x in parts]
        col=None
        for j in range(begin+1,at-2):
            if ts[j].value.lower()=='_x' and ts[j+1].value.lower()=='params' and ts[j+2].value=='[' and j+2 in pairs:
                paramlist=split_args(ts,j+3,pairs[j+2],pairs)
                for n,param in enumerate(paramlist):
                    if len(param)==1 and param[0].kind=='string' and param[0].value.lower()==key:col=n
        if col is None:continue
        if any(ts[j].value.lower()==key and ts[j+1].value=='=' for j in range(begin+1,at-1)):continue
        names=[]
        for row in parts:
            rp=matching(row)
            if not row or row[0].value!='[' or rp.get(0)!=len(row)-1:break
            args=split_args(row,1,len(row)-1,rp)
            if col>=len(args) or len(args[col])!=1 or args[col][0].kind!='string':break
            names.append(args[col][0].value)
        else:
            if names:return names
    return []

def scan_text(text:str,path:str,config:bool=False)->tuple[list[dict],list[dict],list[dict]]:
    reads=[];writes=[];dynamic=[]
    for ts in code_streams(text,config):
        pairs=matching(ts)
        for i,t in enumerate(ts):
            v=t.value.lower()
            if t.kind=='ident' and v in {'getvariable','setvariable'} and i+1<len(ts):
                scope=receiver(ts[:i]);parts=[]
                if ts[i+1].kind=='string':parts=[[ts[i+1]]]
                elif ts[i+1].value=='[' and i+1 in pairs:
                    parts=split_args(ts,i+2,pairs[i+1],pairs)
                if not parts:continue
                key=key_pattern(parts[0])
                if key is None and v=='setvariable' and len(parts[0])==1 and parts[0][0].kind=='ident':
                    for name in foreach_names(ts,i,pairs,parts[0][0].value.lower()):
                        writes.append({'name':name,'scope':scope,'kind':('clear-only' if len(parts)>1 and render(parts[1]).lower()=='nil' else 'literal-loop'),'file':path,'line':t.line})
                    continue
                if key is None:continue
                kind,name=key
                if not name.lower().startswith('acme_'):continue
                if v=='getvariable' and kind=='literal':
                    default=render(parts[1]) if len(parts)>1 else 'nil'
                    reads.append({'name':name,'scope':scope,'default':default,'file':path,'line':t.line})
                elif v=='setvariable':
                    row={'name':name,'scope':scope,'kind':kind,'file':path,'line':t.line}
                    if len(parts)>1 and render(parts[1]).lower()=='nil':row['kind']='clear-only'
                    (dynamic if kind=='format' else writes).append(row)
            if t.kind=='ident' and t.value.lower().startswith('acme_') and i+1<len(ts) and ts[i+1].value=='=':
                writes.append({'name':t.value,'scope':'missionnamespace','kind':'assignment','file':path,'line':t.line})
            if t.kind=='ident' and v=='call' and i+1<len(ts) and ts[i+1].value.lower() in {'acme_fnc_setvarnet','acme_fnc_setvarnetapprox'}:
                if i==0 or ts[i-1].value!=']' or i-1 not in pairs:continue
                lo=pairs[i-1];parts=split_args(ts,lo+1,i-1,pairs)
                if len(parts)<3:continue
                key=key_pattern(parts[1])
                if key and key[1].lower().startswith('acme_'):
                    kind,name=key;helper=ts[i+1].value.split('_')[-1];row={'name':name,'scope':receiver(parts[0]),'kind':kind+'-'+helper,'file':path,'line':t.line}
                    if render(parts[2]).lower()=='nil':row['kind']='clear-only'
                    (dynamic if kind=='format' else writes).append(row)
            if t.value=='[' and i in pairs:
                parts=split_args(ts,i+1,pairs[i],pairs)
                if len(parts)>=2 and len(parts[0])==1 and parts[0][0].kind=='string' and len(parts[1])==1 and parts[1][0].kind=='string':
                    name=parts[0][0].value
                    if name.lower().startswith('acme_') and parts[1][0].value in SETTING_TYPES:
                        # Require an actual settings-registration call after this array.
                        end=pairs[i]
                        if end+2<len(ts) and ts[end+1].value.lower()=='call' and ts[end+2].value.lower() in {'cba_fnc_addsetting','cba_settings_fnc_init'}:
                            writes.append({'name':name,'scope':'missionnamespace','kind':'setting','file':path,'line':t.line})
    return reads,writes,dynamic

def load_contracts(path:Path)->dict[tuple[str,str],dict]:
    if not path.is_file():return {}
    data=json.loads(path.read_text(encoding='utf-8'));out={}
    for item in data:
        if not isinstance(item,dict) or not isinstance(item.get('reason'),str) or not item['reason'].strip():
            raise ValueError('Every external variable contract requires a non-empty reason.')
        if not item.get('writer') or not item.get('source'):raise ValueError('External contracts require writer and source fields.')
        key=(item['scope'].lower(),item['name'].lower())
        if key in out:raise ValueError('Duplicate external variable contract: '+str(key))
        out[key]=item
    return out

def run(root:Path,upstream:list[Path],contracts:Path|None=None)->dict:
    if not (root/'config.cpp').is_file():raise ValueError('Addon config.cpp is missing')
    for p in upstream:
        if not p.is_dir() or not source_files(p):raise ValueError('Reference source directory is missing or empty: '+str(p))
    reads=[];writes=[];dynamic=[]
    for base in [root]+upstream:
        for p in source_files(base):
            rr,ww,dd=scan_text(p.read_text(encoding='utf-8-sig'),str(p.relative_to(base)),p.suffix.lower() in {'.hpp','.cpp','.inc'})
            if base==root:reads+=rr
            for row in ww+dd:row['source_root']='addon' if base==root else str(base.name)
            writes+=ww;dynamic+=dd
    bykey=defaultdict(list);byread=defaultdict(list)
    for w in writes:
        if w['kind']!='clear-only':bykey[(w['scope'],w['name'].lower())].append(w)
    for r in reads:byread[(r['scope'],r['name'].lower())].append(r)
    allow=load_contracts(contracts or root/'tools/external_variables.json')
    patterns=[(w,format_regex(w['name'])) for w in dynamic if w['kind']!='clear-only']
    rows=[]
    for key,rr in sorted(byread.items()):
        scope,name=key; row={'name':rr[0]['name'],'scope':scope,'reads':rr}
        if key in bykey:row.update(status='literal-write-evidence',evidence=bykey[key])
        else:
            matches=[w for w,rx in patterns if w['scope']==scope and rx.fullmatch(name)]
            if matches:row.update(status='format-template-evidence',evidence=matches)
            elif key in allow:row.update(status='documented-external',contract=allow[key])
            elif scope=='missionnamespace' and all(re.fullmatch(r'(?:-?\d+(?:\.\d*)?(?:e[+-]?\d+)?|true|false|".*")',r['default'],re.I) for r in rr):
                row.update(status='unverified-knob-candidate')
            elif scope=='missionnamespace':row.update(status='unverified-mission-default')
            else:row.update(status='missing-state-write-evidence')
        rows.append(row)
    counts={s:sum(r['status']==s for r in rows) for s in ['literal-write-evidence','format-template-evidence','documented-external','unverified-knob-candidate','unverified-mission-default','missing-state-write-evidence']}
    return {'scope':'Static read/write evidence only. Missing evidence is a triage finding, not proof of a runtime defect.',
            'unique_name_scope_pairs':len(rows),'unique_names':len({r['name'].lower() for r in rows}),
            'counts':counts,'variables':rows,'unused_external_contracts':[v for k,v in allow.items() if k not in byread]}

def main()->int:
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('addon',type=Path);ap.add_argument('upstream',nargs='*',type=Path)
    ap.add_argument('--contracts',type=Path);ap.add_argument('--json',type=Path);a=ap.parse_args()
    try:r=run(a.addon,a.upstream,a.contracts)
    except (OSError,ValueError,UnicodeError) as e:ap.error(str(e))
    print(r['scope']);print('Name/scope pairs:',r['unique_name_scope_pairs'])
    for k,v in r['counts'].items():print(k+':',v)
    for row in r['variables']:
        if row['status']=='missing-state-write-evidence':
            print(row['name'],row['scope'])
            for site in row['reads'][:6]:print(f"  {site['file']}:{site['line']} default={site['default']}")
    if a.json:a.json.parent.mkdir(parents=True,exist_ok=True);a.json.write_text(json.dumps(r,indent=2)+'\n')
    return int(r['counts']['missing-state-write-evidence']>0)
if __name__=='__main__':raise SystemExit(main())
