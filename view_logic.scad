///////////////////////////////////////////////////////////////////////////////
// view_logic.scad
// Project-level view / export / explode / print logic
///////////////////////////////////////////////////////////////////////////////

// ---- SAFE READS OF GLOBALS ----
// These never overwrite anything.

_vm_export_mode =
    is_undef(export_mode) ? 0 : export_mode;

_vm_explodeMode =
    is_undef(explodeMode) ? false : explodeMode;

_vm_explodeDistance =
    is_undef(explodeDistance) ? 0 : explodeDistance;


// ---- DERIVED LOGIC ----

// Explode is only meaningful for full assembly
effectiveExplode =
    (_vm_export_mode == 0) && _vm_explodeMode;

// Slot + key explode halfway between box and baffle
explodeMidY =
    effectiveExplode
        ? _vm_explodeDistance / 2
        : 0;

// Show slot + key when:
// - Full assembly AND explode
// - OR slot/key export mode
show_slot_key =
    effectiveExplode ||
    (_vm_export_mode == 4);

// Printing orientation:
// Slot + key lie flat only in export mode 4
print_flat =
    (_vm_export_mode == 4);
