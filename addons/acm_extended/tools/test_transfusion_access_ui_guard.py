from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def read(rel): return (ROOT/rel).read_text(encoding='utf-8', errors='ignore')

def test_access_guard_is_authoritative():
    helper=read('functions/fn_transfusionAccessValid.sqf')
    assert 'ACM_circulation_fnc_hasIV' in helper
    assert 'ACM_circulation_fnc_hasIO' in helper
    add=(ROOT.parent/'circulation/functions/fnc_TransfusionMenu_AddBag.sqf').read_text(encoding='utf-8', errors='ignore')
    toggle=(ROOT.parent/'circulation/functions/fnc_TransfusionMenu_ToggleIVFlow.sqf').read_text(encoding='utf-8', errors='ignore')
    move=(ROOT.parent/'circulation/functions/fnc_TransfusionMenu_MoveBag.sqf').read_text(encoding='utf-8', errors='ignore')
    assert 'ACME_fnc_transfusionAccessValid' in add
    assert 'ACME_fnc_transfusionAccessValid' in toggle
    assert 'ACME_fnc_transfusionAccessValid' in move

def test_transfusion_art_is_only_click_target_and_dims_unselected():
    hot=read('functions/fn_updateTransfusionAccessHotspots.sqf')
    dlg=(ROOT.parent/'circulation/TransfusionMenu_Dialog.hpp').read_text(encoding='utf-8', errors='ignore')
    assert '[0.20,0.65,0.20,0.42]' in hot
    assert 'if (_selected || {_hover}) then {[0.20,0.65,0.20,1]}' in hot
    assert 'action = "";' in dlg
    assert 'ACM_UI_CANVAS_W / 3.4' in dlg

def test_transfusion_page_buttons_stay_blue():
    cfg=read('../acm_extended/config.cpp') if False else read('config.cpp')
    openf=(ROOT.parent/'circulation/functions/fnc_openTransfusionMenu.sqf').read_text(encoding='utf-8', errors='ignore')
    assert 'class ACME_TX_PageButton' in cfg
    assert 'class ACME_TX_PageButton: ACME_SK_PulseButton' in cfg
    assert 'ctrlCreate ["RscText",86952]' in openf
    assert 'ctrlCreate ["RscText",86953]' in openf
    assert 'diag_tickTime * 220' in openf
    assert 'ctrlCreate ["ACME_TX_PageButton",86950]' in openf
    assert '(_uiW / 11) * 0.72' in openf
