;; ***************
;; Subsystem design
;;   4 rules
;; ***************

; power

;(batch ".\\clp\\eps_design_rules.clp")

; avionics
(defrule MASS-BUDGET::design-avionics-subsystem
  "Computes avionics subsystem mass using rules of thumb"
  (declare (salience 10))
  ?miss <- (MANIFEST::Mission (avionics-mass# nil) (payload-mass# ?m&~nil) (payload-data-rate# ?bps&~nil)(factHistory ?fh))
  =>
  ;(bind ?obdh-mass-coeff 0.0983)
  ;(bind ?obdh-mass (* ?m ?obdh-mass-coeff))
  ;(bind ?obdh-power 0.0)

  (bind ?avionics-list (MatlabFunctions designAvionics ?bps 2 ?m))
  (bind ?av-mass (nth$ 1 ?avionics-list))
  (bind ?av-power (nth$ 6 ?avionics-list))
  (printout t "avionics power: " ?av-power crlf)
  (modify ?miss (avionics-mass# ?av-mass) (avionics-power# ?av-power) (factHistory (str-cat "{R" (?*rulesMap* get MASS-BUDGET::design-avionics-subsystem) " " ?fh "}")))
)

; comms-obdh
(defrule MASS-BUDGET::design-comms-subsystem
    "Computes comm subsystem mass using rules of thumb"
    (declare (salience 10))
    ?miss <- (MANIFEST::Mission (comm-OBDH-mass# nil) (satellite-dry-mass ?m&~nil) (payload-data-rate# ?bps&~nil) (orbit-altitude# ?alt&~nil) (factHistory ?fh))
    =>
    ;(bind ?obdh-mass-coeff 0.0983)
    ;(bind ?obdh-mass (* ?m ?obdh-mass-coeff))
    ;(bind ?obdh-power 0.0)

    ;(printout t ?bps " " ?m " " ?alt crlf)
    (bind ?obdh_list (MatlabFunctions designComs ?bps ?m ?alt))
    (bind ?obdh-mass (nth$ 1 ?obdh_list))
    (bind ?obdh-power (nth$ 2 ?obdh_list))
    ;(printout t ?obdh-mass " " ?obdh-power crlf)
    (modify ?miss (comm-OBDH-mass# ?obdh-mass) (comm-OBDH-power# ?obdh-power) (factHistory (str-cat "{R" (?*rulesMap* get MASS-BUDGET::design-avionics-subsystem) " " ?fh "}")))
)

; adcs
;(batch ".\\clp\\adcs_design_rules.clp")

; thermal
(defrule MASS-BUDGET::design-thermal-subsystem
    "Computes thermal subsystem mass using rules of thumb"
    (declare (salience 10))
    ?miss <- (MANIFEST::Mission (thermal-mass# nil) (payload-mass# ?m&~nil) (factHistory ?fh))
    =>
    ;(bind ?thermal-mass-coeff 0.0607)
    (bind ?thermal-mass-coeff (/ 0.02 0.31))
    (bind ?thermal-mass (* ?m ?thermal-mass-coeff))
    ;(printout t "thermal mass: " ?thermal-mass crlf)
    (modify ?miss (thermal-mass# ?thermal-mass) (factHistory (str-cat "{R" (?*rulesMap* get MASS-BUDGET::design-thermal-subsystem) " " ?fh "}")))
    )

; propulsion

;(batch ".\\clp\\propulsion_design_rules.clp")

; structure

(defrule MASS-BUDGET::design-structure-subsystem
    "Computes structure subsystem mass using rules of thumb"
    (declare (salience 10))
    ?miss <- (MANIFEST::Mission (structure-mass# nil) (payload-mass# ?m&~nil) (factHistory ?fh))
    =>

    ;(bind ?struct-mass (* 0.5462 ?m)); 0.75
    (bind ?struct-mass (* (/ 0.27 0.31) ?m)); 0.75
    ;(printout t "structure mass: " ?struct-mass crlf)
    (modify ?miss (structure-mass# ?struct-mass) (factHistory (str-cat "{R" (?*rulesMap* get MASS-BUDGET::design-structure-subsystem) " " ?fh "}")))
    )

; adapter

(defrule MASS-BUDGET::add-launch-adapter
    "Computes launch adapter mass as 1% of satellite dry mass"
    (declare (salience 10))
    ?miss <- (MANIFEST::Mission (adapter-mass nil) (satellite-dry-mass ?m&~nil) (factHistory ?fh) )
    =>

    ;(bind ?adapter-mass (* 0.01 ?m)); 0.75
    (bind ?adapter-mass (* (/ 0.03 0.31) ?m)); 0.75
    ;(printout t "adapter mass: " ?adapter-mass crlf)
    (modify ?miss (adapter-mass ?adapter-mass) (factHistory (str-cat "{R" (?*rulesMap* get MASS-BUDGET::add-launch-adapter ) " " ?fh "}")))
    )

; **************************************
; SUPPORTING QUERIES AND FUNCTIONS
; **************************************
