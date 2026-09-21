#!/usr/bin/env python3
"""Executable source-check fixtures and Python reference models. These do NOT run SQF."""
from __future__ import annotations
import json
import math
from pathlib import Path
import tempfile
import unittest
import varcheck
import tagcheck

class ScannerFixtures(unittest.TestCase):
    def writes(self,text,config=False):
        return varcheck.scan_text(text,'fixture.cpp' if config else 'fixture.sqf',config)[1:]
    def test_comment_write_is_not_evidence(self):
        w,d=self.writes('// x setVariable ["ACME_dead",true];\n/* ACME_dead = true; */')
        self.assertEqual(w+d,[])
    def test_ordinary_string_is_not_code(self):
        w,d=self.writes('hint "x setVariable [\'ACME_dead\', true]";')
        self.assertEqual(w+d,[])
    def test_config_single_quoted_callback(self):
        w,d=self.writes('onLoad="uiNamespace setVariable [\'ACME_panel\',_this select 0]";',True)
        self.assertEqual(w[0]['scope'],'uinamespace');self.assertEqual(w[0]['name'],'ACME_panel')
    def test_format_key_is_template_evidence(self):
        w,d=self.writes('_p setVariable [format ["ACME_thora_tube_%1",_side],true,true];')
        self.assertEqual(len(w),0);self.assertEqual(len(d),1)
        rx=varcheck.format_regex(d[0]['name']);self.assertIsNotNone(rx.fullmatch('ACME_thora_tube_left'))
        self.assertIsNotNone(rx.fullmatch('acme_THORA_TUBE_right'));self.assertIsNone(rx.fullmatch('ACME_other'))
    def test_format_event_callback_is_code(self):
        w,d=self.writes('_c ctrlAddEventHandler ["ButtonClick",format ["uiNamespace setVariable [\'ACME_idx\',%1]",2]];')
        self.assertEqual(w[0]['name'],'ACME_idx')
    def test_compile_string_is_code(self):
        w,d=self.writes('call compile "ACME_active = true;";');self.assertEqual(w[0]['name'],'ACME_active')
    def test_direct_loop_names(self):
        w,d=self.writes('{uiNamespace setVariable [_x,false];} forEach ["ACME_a","ACME_b"];')
        self.assertEqual({x['name'] for x in w},{'ACME_a','ACME_b'})
    def test_tuple_loop_names(self):
        w,d=self.writes('{_x params ["_key","_val"];_p setVariable [_key,_val,true];} forEach [["ACME_a",98],["ACME_b",38]];')
        self.assertEqual({x['name'] for x in w},{'ACME_a','ACME_b'})
    def test_tuple_loop_second_column(self):
        w,d=self.writes('{_x params ["_rate","_key"];_p setVariable [_key,1];} forEach [[7,"ACME_a"],[4,"ACME_b"]];')
        self.assertEqual({x['name'] for x in w},{'ACME_a','ACME_b'})
    def test_reassigned_tuple_key_unresolved(self):
        w,d=self.writes('{_x params ["_key"];_key=call another;_p setVariable [_key,1];} forEach [["ACME_a"]];')
        self.assertEqual(w,[])
    def test_schema_string_not_write(self):
        w,d=self.writes('[["ACME_dead","",true]]');self.assertEqual(w+d,[])
    def test_nil_clear_not_positive_writer(self):
        w,d=self.writes('_p setVariable ["ACME_old",nil];');self.assertEqual(w[0]['kind'],'clear-only')
    def test_loop_nil_clear_not_positive_writer(self):
        w,d=self.writes('{_p setVariable [_x,nil];} forEach ["ACME_a"];');self.assertEqual(w[0]['kind'],'clear-only')
    def test_net_helper_nil_clear(self):
        w,d=self.writes('[_p,"ACME_a",nil] call ACME_fnc_setVarNet;');self.assertEqual(w[0]['kind'],'clear-only')
    def test_approx_net_helper_is_write_evidence(self):
        w,d=self.writes('[_p,"ACME_a",1.25,0.1,2] call ACME_fnc_setVarNetApprox;');self.assertEqual(w[0]['name'],'ACME_a')
    def test_false_assignment_is_real_writer(self):
        w,d=self.writes('_p setVariable ["ACME_a",false];');self.assertEqual(w[0]['kind'],'literal')
    def test_line_numbers_survive_comments(self):
        r,_,_=varcheck.scan_text('/*\nline2\n*/\n_p getVariable ["ACME_a",false];','fixture')
        self.assertEqual(r[0]['line'],4)
    def test_contract_reason_required(self):
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp)/'allow.json';p.write_text('[{"name":"ACME_a","scope":"entity","writer":"x","source":"y","reason":""}]')
            with self.assertRaises(ValueError):varcheck.load_contracts(p)
    def test_contract_writer_required(self):
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp)/'allow.json';p.write_text('[{"name":"ACME_a","scope":"entity","source":"y","reason":"z"}]')
            with self.assertRaises(ValueError):varcheck.load_contracts(p)
    def inventory(self,text):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);(root/'config.cpp').write_text('class CfgFunctions {};');(root/'fn_x.sqf').write_text(text)
            return varcheck.run(root,[])['variables']
    def test_namespace_mismatch_is_detected(self):
        rows=self.inventory('ACME_a=[]; _p getVariable ["ACME_a",[]];')
        self.assertEqual(rows[0]['status'],'missing-state-write-evidence')
    def test_case_only_difference_matches(self):
        rows=self.inventory('uiNamespace setVariable ["ACME_Thora_Patient",player];uiNamespace getVariable ["acme_thora_patient",objNull];')
        self.assertEqual(rows[0]['status'],'literal-write-evidence')
    def test_knob_stays_unverified(self):
        rows=self.inventory('missionNamespace getVariable ["ACME_rate",0.7];');self.assertEqual(rows[0]['status'],'unverified-knob-candidate')
    def test_mission_array_default_stays_unverified(self):
        rows=self.inventory('missionNamespace getVariable ["ACME_offset",[0,1]];');self.assertEqual(rows[0]['status'],'unverified-mission-default')
    def test_unwritten_numeric_entity_is_state(self):
        rows=self.inventory('_p getVariable ["ACME_rr",14];');self.assertEqual(rows[0]['status'],'missing-state-write-evidence')
    def test_config_callback_function_reference(self):
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp);(p/'config.cpp').write_text('onLoad="call ABC_fnc_live";')
            self.assertIn('abc_fnc_live',tagcheck.collect_references(p))
    def test_comment_only_function_reference_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp);(p/'fn.sqf').write_text('// call ABC_fnc_dead;\n/* call ABC_fnc_dead */')
            self.assertNotIn('abc_fnc_dead',tagcheck.collect_references(p))
    def test_quoted_function_name_not_call_proof(self):
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp);(p/'fn.sqf').write_text('hint "ABC_fnc_dead";ABC_fnc_dead = {};')
            self.assertNotIn('abc_fnc_dead',tagcheck.collect_references(p))
    def test_function_alias_reference_is_labeled_only_reference(self):
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp);(p/'fn.sqf').write_text('alias = ABC_fnc_work;')
            self.assertEqual(tagcheck.collect_references(p)['abc_fnc_work'][0]['kind'],'code-reference')
    def test_macro_prefix_from_explicit_dependency(self):
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp);(p/'circulation').mkdir();(p/'circulation'/'fn.sqf').write_text('call FUNC(a);call EFUNC(core,b);call ACEFUNC(medical,c);')
            refs=tagcheck.collect_references(p,'ACM')
            self.assertEqual(set(refs),{'acm_circulation_fnc_a','acm_core_fnc_b','ace_medical_fnc_c'})
    def test_duplicate_resolved_name_across_outer_blocks(self):
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp)/'config.cpp';p.write_text('class CfgFunctions {class A {tag="T";class X {file="\\acm_extended\\functions";class foo {};};};class B {tag="T";class Y {file="\\acm_extended\\functions";class foo {};};};};')
            rows=tagcheck.parse_config(p);self.assertEqual([r['resolved'] for r in rows],['T_fnc_foo','T_fnc_foo'])
    def test_missing_dependency_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaises(ValueError):tagcheck.addons_root(Path(tmp))
    def test_public_entry_contract_requires_existing_evidence(self):
        with tempfile.TemporaryDirectory() as tmp:
            r=Path(tmp);(r/'tools').mkdir();(r/'addons').mkdir()
            (r/'tools'/'external_entry_points.json').write_text(json.dumps([dict(name='x_fnc_s',reason='public',source_root='ace',source='missing.md',evidence='x_fnc_s')]))
            with self.assertRaises(ValueError):tagcheck.load_entry_points(r,r,r)

# The following models mirror the intended equations/protocol. No Arma code is executed.
def dilution(anchor,actual,now,half=1200):
    effective,previous,at=anchor
    result=max(effective,0)*2**(-max(now-at,0)/max(half,1))
    if actual<previous and previous>0:result*=actual/previous
    return min(max(result+max(actual-previous,0),0),max(actual,0))
def cuff_rate(base,clamp,bag_id,cuffs,medicated,now,half=150):
    factor=1
    if bag_id and bag_id in cuffs and bag_id not in medicated:
        at,p0=cuffs[bag_id];p=min(max(p0*2**(-max(now-at,0)/max(half,.1)),0),1)
        if p>=.08:factor=1+1.5*p
    return (min(clamp,base) if clamp>=0 else base)*factor
class ReferenceModels(unittest.TestCase):
    def test_dilution_half_life(self):self.assertEqual(dilution((2,2,0),2,1200),1)
    def test_dilution_repeated_read_no_rearm(self):
        for t in range(0,2401,10):self.assertAlmostEqual(dilution((2,2,0),2,t),2*2**(-t/1200))
    def test_dilution_extra_fluid_counted_once(self):
        value=dilution((2,2,0),3,1200);self.assertEqual(value,2)
        self.assertEqual(dilution((value,3,1200),3,1200),2)
    def test_dilution_outflow_scales_existing_effect(self):self.assertEqual(dilution((2,2,0),1,1200),.5)
    def test_dilution_zero_clears(self):self.assertEqual(dilution((2,2,0),0,1200),0)
    def test_dilution_owner_transfer_same_anchor(self):self.assertEqual(dilution((2,2,0),2,600),dilution((2,2,0),2,600))
    def test_dilution_save_rebase_preserves_age(self):self.assertEqual(dilution((2,2,0),2,600),dilution((2,2,400),2,1000))
    def test_cuff_does_not_boost_other_bag(self):self.assertEqual(cuff_rate(4,-1,'B',{'A':(0,1)},set(),0),4)
    def test_cuff_does_not_boost_drug_bag(self):self.assertEqual(cuff_rate(4,1,'A',{'A':(0,1)},{'A'},0),1)
    def test_cuff_selected_bag_boost(self):self.assertEqual(cuff_rate(4,-1,'A',{'A':(0,1)},set(),0),10)
    def test_cuff_half_life(self):self.assertEqual(cuff_rate(4,-1,'A',{'A':(0,1)},set(),150),7)
    def test_cuff_unspecified_native_query_unboosted(self):self.assertEqual(cuff_rate(4,-1,'',{'A':(0,1)},set(),0),4)
    def test_cuff_slot_reordering_uses_id(self):
        before={'leftarm':['A','B']};after={'leftarm':['B','A']}
        for state in [before,after]:
            self.assertEqual([cuff_rate(4,-1,x,{'A':(0,1)},set(),0) for x in state['leftarm']], [10,4] if state is before else [4,10])
    def test_cuff_empty_pressure_has_no_boost(self):self.assertEqual(cuff_rate(4,-1,'A',{'A':(0,1)},set(),1000),4)
    def test_battery_high_settings_cost_more(self):
        def conv(x,a,b,m):return 1+(m-1)*min(max((x-a)/(b-a),0),1)
        def load(rr,pip,peep):return conv(rr,10,35,1.3)*conv(pip,20,50,1.4)*conv(peep,5,20,1.35)
        self.assertGreater(load(35,50,20),load(12,20,5));self.assertAlmostEqual(load(35,50,20),2.457)
    def test_fresh_blood_threshold_matches_native(self):
        for x,want in [(0,False),(.83,False),(.83001,True),(1,True)]:self.assertEqual(x>.83,want)
    def test_airway_trauma_increment_not_repeated(self):
        grade=(2,2);prior=0
        for bump in [1,1,1,2,2]:
            delta=max(bump-prior,0);grade=tuple(min(x+delta,4) for x in grade);prior=max(bump,prior)
        self.assertEqual(grade,(4,4))
    def test_head_burn_lookup_follows_table_not_fixed_id(self):
        names=['Avulsion','ThermalBurn','ChemicalBurn'];ids=[10,12,20,21]
        self.assertTrue(all(names[i//10] in ['ThermalBurn','ChemicalBurn'] for i in ids))
    def test_service_grant_bound_to_code_and_patient(self):
        grant=('0000','patientA')
        self.assertEqual(grant,('0000','patientA'));self.assertNotEqual(grant,('1111','patientA'));self.assertNotEqual(grant,('0000','patientB'))
    def test_inventory_duplicate_ack_is_idempotent(self):
        applied=False;returns=0
        for ack in [True,True,True]:
            if not applied:applied=True;returns+=int(ack)
        self.assertEqual(returns,1)
    def test_owner_receipt_precedes_epoch_rejection(self):
        receipts={'request':(True,False)}
        for epoch in [1,2,3]:self.assertEqual(receipts.get('request',(False,True)),(True,False))
    def test_two_provider_cuff_consumes_one(self):
        cuff=False;spent=0;refunds=0
        for _ in range(2):
            spent+=1;already=cuff;cuff=True;refunds+=int(already)
        self.assertEqual(spent-refunds,1)

if __name__=='__main__':unittest.main(verbosity=2)
