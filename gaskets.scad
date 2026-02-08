///////////////////////////////////////////////////////////////////////////////
// gaskets.scad
//
// G.U.M.B.O. — Gasket Generator
//
// • Parametric TPU gaskets
// • One gasket per enabled driver
// • Uses EXACT driver geometry (round, clipped, oval, etc.)
// • Shape-aware sealing bead
// • Flat print layout
//
// Future:
// • Back panel gasket
// • Port / terminal gaskets
//
///////////////////////////////////////////////////////////////////////////////


include <utils.scad>
include <drivers.scad>



/////////////////////////////
// PUBLIC EXPORT DISPATCH
/////////////////////////////

module gaskets_export() {

    if (enableDriverGaskets)
        driver_gaskets_export();

    // Future expansion:
    // if (enableBackPanelGasket)
    //     back_panel_gasket_export();
}


/////////////////////////////
// DRIVER GASKETS (EXPORT)
/////////////////////////////

module driver_gaskets_export() {

    idx = 0;

    for (j = [0 : len(driverParams) - 1]) {

        if (driverParams[j][3]) {

            translate([
                idx * (max_driver_diameter()
                       + gasket_width * 2
                       + gasket_spacing),
                0,
                0
            ])
                driver_gasket_single(j);

            idx = idx + 1;
        }
    }
}


/////////////////////////////
// SINGLE DRIVER GASKET
/////////////////////////////

module driver_gasket_single(j) {

    cutout_d = driverParams[j][0];

    screw_cnt = driverScrewCount[j];
    screw_cd  = driverParams[j][1];   // ← THIS WAS THE BUG
    screw_d   = driverParams[j][2];
    start_ang = 45;                   // match baffle default


    difference() {

        // ─────────────────────────
        // ALL SOLID GASKET GEOMETRY
        // ─────────────────────────
        union() {

            // MAIN GASKET BODY
            linear_extrude(height = gasket_thk)
                difference() {

                    offset(delta = gasket_width)
                        driver_cutout_2d(j, gasket_clearance);

                    circle(d = cutout_d + gasket_clearance);
                }

            // SEALING BEAD
            if (gasket_bead_enable)
                translate([0,0,gasket_thk])
                    linear_extrude(height = gasket_bead_h)
                        difference() {
                            offset(delta = gasket_bead_w)
                                circle(d = cutout_d + gasket_bead_offset);

                            circle(d = cutout_d + gasket_bead_offset);
                        }
        }

        // ─────────────────────────
        // SCREW HOLES (CUT EVERYTHING)
        // ─────────────────────────
        for (i = [0 : screw_cnt - 1]) {
        ang = start_ang + 360 / screw_cnt * i;
        rotate([0,0,ang])
            translate([screw_cd/2, 0, -1])   // start below gasket
                cylinder(
                    d = screw_d + gasket_hole_clear,   // OVERSIZED ON PURPOSE
                    h = gasket_thk + gasket_bead_h + 3, // definitely through
                    center = false
                    );
        }
    }
}




/*
/////////////////////////////
// SEALING BEAD (SHAPE-AWARE)
/////////////////////////////

module gasket_bead_for_driver(j) {

    translate([0,0,gasket_thk])
        linear_extrude(height = gasket_bead_h)
            difference() {

                // outer edge of bead
                offset(delta = gasket_bead_w)
                    driver_cutout_2d(j, gasket_clearance + gasket_bead_offset);

                // inner edge of bead
                driver_cutout_2d(j, gasket_clearance + gasket_bead_offset);
            }
} */

