///////////////////////////////////////////////////////////////////////////////
// Slot + Key Geometry (PURE — no view, no print, no explode)
// Source: Tab + Key Insert Generator
///////////////////////////////////////////////////////////////////////////////

// -----------------------------
// PARAMETERS (shared)
// -----------------------------
tabInsertThickness = 2.8;
tabPocketClearance = 0.3;

baffleSlotLength = 14;
baffleSlotWidth  = 6;

baffleKeyLength = 8;
baffleKeyWidth  = 4;


// -----------------------------
// RAW SLOT TAB (centered)
// -----------------------------
module raw_slot_tab() {
    l = baffleSlotLength - 2*tabPocketClearance;
    w = baffleSlotWidth  - 2*tabPocketClearance;
    h = tabInsertThickness;
    cube([l, h, w], center=true);
}


// -----------------------------
// RAW KEY INSERT (Minkowski)
// -----------------------------
module raw_key_insert() {
    l = baffleKeyLength - 2*tabPocketClearance;
    w = baffleKeyWidth  - 2*tabPocketClearance;
    h = tabInsertThickness;

    baseW = w - 2;
    baseL = l - 2;

    minkowski() {
        cube([baseL, h, baseW], center=true);
        cylinder(r=1, h=0.01, center=true);
    }
}


// -----------------------------
// SLOT (final orientation)
// -----------------------------
module slot() {
    h = tabInsertThickness;
    rotate([90, 0, 0])
        translate([0, h/2-.01, 0])
            raw_slot_tab();
}


// -----------------------------
// KEY (final orientation)
// -----------------------------
module key() {
    h = tabInsertThickness;
    translate([0, 0, h/4])
        raw_key_insert();
}

module slot_key_assembly_mode0() {
    // Assembly for mode 0: Place slot and key as needed
    translate([baffleSlotPosX, explodeMidY, baffleSlotPosZ]) slot();
    translate([baffleKeyPosX, explodeMidY, baffleKeyPosZ]) key();
}
