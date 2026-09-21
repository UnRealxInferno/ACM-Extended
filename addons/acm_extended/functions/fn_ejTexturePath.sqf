/* Return a guaranteed single-backslash PBO path for the EJ body-map overlay.
 * Building the path from the backslash character avoids any source/preprocessor escaping ambiguity.
 */
params [["_site", 0]];
private _slash = toString [92];
private _side = ["left", "right"] select ((_site max 0) min 1);
format ["%1acm_extended%1ui%1iv%1iv_ej_%2_ca.paa", _slash, _side]
