// Two-page debug dispatcher. Page 0 is the screenshot-friendly clinical overview; page 1 is network/engineering state only.
disableSerialization;

private _page = uiNamespace getVariable ["ACME_debug_page", 0];
_page = (_page max 0) min 1;
uiNamespace setVariable ["ACME_debug_page", _page];

if (_page == 0) exitWith {
    call ACME_fnc_debugMenuClinical;
};

call ACME_fnc_debugMenuNetwork;
