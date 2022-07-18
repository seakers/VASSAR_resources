; ***************************************
; PROPULSION SUBSYSTEM (AKM only, no ADCS)
;     (4 rules)
; ***************************************

(defrule DESIGN-PREP::assert-all-injection-types
    ?orig <- (MANIFEST::Mission (Propulsion-Injection nil) (factHistory ?fh))
    =>

    (modify ?orig (Propulsion-Injection Chemical) (factHistory (str-cat "{R" (?*rulesMap* get DESIGN-PREP::assert-all-injection-types) " " ?fh "}")))
    (duplicate ?orig (Propulsion-Injection Electric) (factHistory (str-cat "{R" (?*rulesMap* get DESIGN-PREP::assert-all-injection-types) " " ?fh "}")))
    )


(defrule DESIGN-PREP::assert-all-adcs-types
    ?chemical <- (MANIFEST::Mission (Propulsion-Injection Chemical) (Propulsion-ADCS nil) (factHistory ?fh))
    ?electric <- (MANIFEST::Mission (Propulsion-Injection Electric) (Propulsion-ADCS nil) (factHistory ?fh))
    =>

    (modify ?chemical (Propulsion-ADCS Chemical) (factHistory (str-cat "{R" (?*rulesMap* get DESIGN-PREP::assert-all-adcs-types) " " ?fh "}")))
    (modify ?electric (Propulsion-ADCS Chemical) (factHistory (str-cat "{R" (?*rulesMap* get DESIGN-PREP::assert-all-adcs-types) " " ?fh "}")))
    (duplicate ?electric (Propulsion-ADCS Electric) (factHistory (str-cat "{R" (?*rulesMap* get DESIGN-PREP::assert-all-adcs-types) " " ?fh "}")))
    )


(defrule MANIFEST::get-Isp-injection-chem
    "This rule estimates the Isp injection from the type of propellant"
    ?miss <- (MANIFEST::Mission (propellant-injection ?prop&~nil) (Isp-injection nil) (factHistory ?fh) (Propulsion-Injection Chemical))
    =>

    (modify ?miss (Isp-injection (get-prop-Isp ?prop)) (factHistory (str-cat "{R" (?*rulesMap* get MANIFEST::get-Isp-injection) " " ?fh "}")))
    )

(defrule MANIFEST::get-Isp-injection-elec
    "This rule estimates the Isp injection from the type of propellant"
    ?miss <- (MANIFEST::Mission (propellant-injection ?prop&~nil) (Isp-injection nil) (factHistory ?fh) (Propulsion-Injection Electric))
    =>

    (modify ?miss (Isp-injection 1500) (factHistory (str-cat "{R" (?*rulesMap* get MANIFEST::get-Isp-injection) " " ?fh "}")))
    )

(defrule MANIFEST::get-Isp-ADCS-chem
    "This rule estimates the Isp ADCS from the type of propellant"
    ?miss <- (MANIFEST::Mission (propellant-ADCS ?prop&~nil) (Isp-ADCS nil) (factHistory ?fh) (Propulsion-ADCS Chemical))
    =>

    (modify ?miss (Isp-ADCS (get-prop-Isp ?prop)) (factHistory (str-cat "{R" (?*rulesMap* get MANIFEST::get-Isp-ADCS) " " ?fh "}")))
    )

(defrule MANIFEST::get-Isp-ADCS-elec
    "This rule estimates the Isp ADCS from the type of propellant"
    ?miss <- (MANIFEST::Mission (propellant-ADCS ?prop&~nil) (Isp-ADCS nil) (factHistory ?fh) (Propulsion-ADCS Electric))
    =>

    (modify ?miss (Isp-ADCS 1500) (factHistory (str-cat "{R" (?*rulesMap* get MANIFEST::get-Isp-ADCS) " " ?fh "}")))
    )



(defrule MASS-BUDGET::compute-propellant-mass
    "This rule computes the propellant mass necessary for the DeltaV
    using the rocket equation and assuming a certain Isp."

    ?miss <- (MANIFEST::Mission (satellite-dry-mass ?dry-mass&~nil)
         (delta-V-injection ?dV-i&~nil) (delta-V ?dV&~nil)
        (Isp-injection ?Isp-i&~nil) (Isp-ADCS ?Isp-a&~nil)
        (propellant-mass-injection nil) (propellant-mass-ADCS nil) (factHistory ?fh))
   
    =>
    (bind ?mp-inj (rocket-equation-mf-dV-to-mp ?dV-i ?Isp-i ?dry-mass))
    (bind ?mp-a (rocket-equation-mf-dV-to-mp (- ?dV ?dV-i) ?Isp-a ?dry-mass))
    ;(printout t "mass injection: " ?mp-inj crlf)
    ;(printout t "mass adcs: " ?mp-a crlf)
    (modify ?miss (propellant-mass-injection ?mp-inj) (propellant-mass-ADCS ?mp-a) (factHistory (str-cat "{R" (?*rulesMap* get MASS-BUDGET::compute-propellant-mass) " " ?fh "}"))); wet mass
    )

(defrule MASS-BUDGET::design-propulsion-AKM
    "Computes dry AKM mass using rules of thumb:
    94% of wet AKM mass is propellant, 6% motor"

    ?miss <- (MANIFEST::Mission (propulsion-mass# nil) (Propulsion-Injection Chemical) (Propulsion-ADCS Chemical)
        (propellant-mass-injection ?mp-inj&~nil) (propellant-mass-ADCS ?mp-a) (factHistory ?fh))

        =>
    (bind ?m (+ ?mp-inj ?mp-a))
    ;(printout t "propellant mass total: " ?m crlf)
    ;(printout t "propulsion-mass: " (* ?m (/ 6 94)) crlf)
    (modify ?miss (propulsion-mass# (* ?m (/ 6 94))) (factHistory (str-cat "{R" (?*rulesMap* get MASS-BUDGET::design-propulsion-AKM) " " ?fh "}")))
    )

(defrule MASS-BUDGET::design-propulsion-hybrid
    "Computes dry AKM mass using rules of thumb:
    94% of wet AKM mass is propellant, 6% motor"

    ?miss <- (MANIFEST::Mission (propulsion-mass# nil) (Propulsion-Injection Electric) (Propulsion-ADCS Chemical)
        (propellant-mass-injection ?mp-inj&~nil) (propellant-mass-ADCS ?mp-a) (propulsion-power ?power&~nil) (factHistory ?fh))

        =>
    (bind ?m (+ ?mp-inj ?mp-a))
    ;(printout t "propellant mass total: " ?m crlf)
    ;(printout t "propulsion-mass: " (* ?m (/ 6 94)) crlf)
    (modify ?miss (propulsion-mass# (+ (* ?mp-a (/ 6 94)) (ep-mass-total 1 0 ?power))) (factHistory (str-cat "{R" (?*rulesMap* get MASS-BUDGET::design-propulsion-AKM) " " ?fh "}")))
    )

(defrule MANIFEST::assign-injection-time
    ?miss <- (MANIFEST::Mission (injection-time nil))
    =>
    (modify ?miss (injection-time Low))
    )

(defrule MASS-BUDGET::electric-propulsion-thrust-requirement-LEO
    "Computes thrust requirement of propulsion system given injection time."
    ?miss <- (MANIFEST::Mission (injection-time ?time&~nil) (delta-V ?dV&~nil) (orbit-type ~GEO) (orbit-altitude# ?alt&~nil) (Propulsion-Injection Electric) (thrust-requirement nil) (satellite-dry-mass ?dry-mass&~nil))
    =>
    (bind ?dV-error (- (sqrt (/ 3.986e14 (+ ?alt 10))) (sqrt (/ 698600.5 ?alt))))
    (if (eq ?time Low) then (modify ?miss (thrust-requirement (ep-thrust-requirement 365 ?dV-error ?dry-mass)))
     elif (eq ?time Medium) then (modify ?miss (thrust-requirement (ep-thrust-requirement 100 ?dV-error ?dry-mass)))
     else (modify ?miss (thrust-requirement 1e15)))
    )

(defrule MASS-BUDGET::electric-propulsion-thrust-requirement-GEO
    "Computes thrust requirement of propulsion system given injection time."
    ?miss <- (MANIFEST::Mission (injection-time ?time&~nil) (delta-V ?dV&~nil) (orbit-type GEO) (orbit-altitude# ?alt&~nil) (Propulsion-Injection Electric) (thrust-requirement nil) (satellite-dry-mass ?dry-mass&~nil))
    =>
    (bind ?dV-error (- (sqrt (/ 3.986e14 (+ ?alt 50))) (sqrt (/ 698600.5 ?alt))))
    (if (eq ?time Low) then (modify ?miss (thrust-requirement (ep-thrust-requirement 365 ?dV-error ?dry-mass)))
     elif (eq ?time Medium) then (modify ?miss (thrust-requirement (ep-thrust-requirement 100 ?dV-error ?dry-mass)))
     else (modify ?miss (thrust-requirement 1e15)))
    )

(defrule MASS-BUDGET::electric-propulsion-power-estimate
    "Computes the power of the propulsion system using empirical relationship to thrust. Data used: DOI 10.2514/1.B34650"
    ?miss <- (MANIFEST::Mission (thrust-requirement ?Thrust&~nil) (Propulsion-Injection Electric) (propulsion-power nil))
    =>
    (modify ?miss (propulsion-power (ep-thrust-to-power ?Thrust)))
    )

(defrule MASS-BUDGET::electric-propulsion-mass
    "Computes the mass of the propulsion system using empirical relationship to power. Takes into account # active thrusters,
    # redundant thrusters, and power. Assumes 1 active, 0 redundant. DOI: 10.2514/1.B34525"
    ?miss <- (MANIFEST::Mission (propulsion-mass# nil) (Propulsion-Injection Electric) (Propulsion-ADCS Electric) (propulsion-power ?power&~nil))
    =>
    (modify ?miss (propulsion-mass# (ep-mass-total 1 0 ?power)))
    )

(defrule PROPULSION-SELECTION::eliminate-more-expensive-options
    "From all feasible options, eliminate the most expensive ones"

    ?m1 <- (MANIFEST::Mission (Name ?name) (lifecycle-cost# ?c1&~nil))
    (MANIFEST::Mission (Name ?name) (lifecycle-cost# ?c2&~nil&:(< ?c2 ?c1)))

        =>

    (printout t "eliminating missions" crlf)

	 (retract ?m1)
   )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SUPPORTING QUERIES AND FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(deffunction rocket-equation-mi-dV-to-mp (?dV ?Isp ?mi)
    ; mprop = mwet*(1-exp(-dV/V0))
    (return (* ?mi (- 1 (exp (/ ?dV (* -9.81 ?Isp))))))
    )

(deffunction rocket-equation-mf-dV-to-mp (?dV ?Isp ?mf)
    ; mprop = mdry*(-1+exp(dV/V0))
    ;(printout t ?dV " " ?Isp " " ?mf crlf)
    (return (* ?mf (- (exp (/ ?dV (* 9.81 ?Isp))) 1)))
    )

(deffunction get-prop-Isp (?prop)
    (bind ?props (create$ solid-comp solid-double solid-comp-double cold-h2 cold-he cold-n2 cold-nh3 cold-co2 mono-n2h4 mono-h2o2 mono-adn bi-mmh-nto bi-ch4-lox bi-h2o2))
    (bind ?Isps (create$ 242 235 275 272 165 73 96 61 240 200 255 300 380 450))

    (bind ?ind (member$ ?prop ?props))
    (if (eq ?ind FALSE) then (printout t "get-prop-Isp: propellant not found" crlf) (return FALSE)
    else (return (nth$ ?ind ?Isps)))
    )

(deffunction ep-mass-tg (?n-ac ?n-rd ?power-system)
    (return (* (+ 1 .5) (+ ?n-ac ?n-rd) (+ (* 2.4254 (/ ?power-system ?n-ac)) 0)))
    )

(deffunction ep-mass-ppu (?n-ac ?n-rd ?power-system)
    (return (* (+ ?n-ac ?n-rd) (+ (* 1.7419 (/ ?power-system ?n-ac)) 4.645)))
    )

(deffunction ep-mass-xfs (?n-ac ?n-rd ?power-system)
    (return (+ (* (+ ?n-ac ?n-rd) 3.2412) 4.5189))
    )

(deffunction ep-mass-cab (?n-ac ?n-rd ?power-system)
    (return (* (+ ?n-ac ?n-rd) (+ (* 0.06778 (/ ?power-system ?n-ac)) 0.7301)))
    )

(deffunction ep-mass-tank (?n-ac ?n-rd ?power-system)
    (return (* 0.04 100 ?power-system))
    )

(deffunction ep-mass-total (?n-ac ?n-rd ?power-system)
    "Inputs: Number of actual trusters, number of redudnant thrusters, propulsion system power."
    (return (* (+ 1 .26) (+ (ep-mass-tg ?n-ac ?n-rd ?power-system) (ep-mass-ppu ?n-ac ?n-rd ?power-system) (ep-mass-xfs ?n-ac ?n-rd ?power-system) (ep-mass-cab ?n-ac ?n-rd ?power-system) (ep-mass-tank ?n-ac ?n-rd ?power-system))))
    )

(deffunction ep-thrust-to-power (?thrust)
    (return (+ (* 21.082 (/ ?thrust 1000) 15.663)))
    )

(deffunction ep-thrust-requirement (?transfer-time ?dV ?dry-mass)
    return (/ (* ?dV ?dry-mass) (* ?transfer-time 24 60 60 1000))
    )