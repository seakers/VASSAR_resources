(defrule LV-SELECTION0::assert-all-possible-lvs
	?orig <- (MANIFEST::Satellite (id ?sat-id) (launch-vehicle nil) (factHistory ?fh))
	?lv <- (DATABASE::Launch-vehicle (id ?name) )
	=>
	(duplicate ?orig (launch-vehicle ?name) (id (sym-cat ?sat-id _ ?name)) (factHistory (str-cat "{R" (?*rulesMap* get LV-SELECTION0::assert-all-possible-lvs) " D" (call ?orig getFactId) " S" (call ?lv getFactId) " " ?fh "}")))
)

(defrule LV-SELECTION1::remove-nils
	?orig <- (MANIFEST::Satellite (launch-vehicle nil))

	=>
;	(printout t "Remove-nils called." crlf)
	(retract ?orig)
)

;(defrule LV-SELECTION2::compute-number-of-launches-standalone
;    "Compute number of launches needed for a standalone satellite on a certain launcher."
;
;      ?f <-  (MANIFEST::Satellite (id ?sat) (launch-vehicle ?lv&~nil) (num-launches nil) (part-of-constellation nil)
;        (num-of-planes# ?np&~nil) (num-of-sats-per-plane# ?ns&~nil) (satellite-wet-mass ?m&~nil) (satellite-dimensions $?dim)
;        (orbit-type ?orb&~nil) (orbit-semimajor-axis ?a&~nil) (orbit-inclination ?i&~nil) (factHistory ?fh))
;
;    =>
;	(printout t "Start" crlf)
;    (bind ?N (* ?np ?ns))
;    (bind ?perf (get-performance ?lv ?orb (to-km (r-to-h ?a)) ?i))
;    ;(printout t "the perf of lv " ?lv " for orbit "  ?orb " a = " ?a " i = " ?i " is " ?perf crlf)
;    (bind ?NL-mass (ceil (/ (* ?m ?N) ?perf)))
;	(printout t "NL-mass computed: " ?NL-mass crlf)
;	(bind ?lvdims (MatlabFunctions getLaunchVehicleDimensions ?lv))
;	(bind ?d (nth$ 1 ?lvdims))
;	(bind ?h (nth$ 2 ?lvdims))
;	(bind ?lvvol (* (* (** (/ ?d 2) 2) (pi)) ?h))
;   (bind ?NL-vol (ceil (/ (* (*$ $?dim) ?N) ?lvvol)))
;	(printout t "NL-vol computed: " ?NL-vol crlf)
;    ;(printout t "the dimensions of lv " ?lv " are diam "  (nth$ 1 ?lvdims) " h = " (nth$ 2 ?lvdims) crlf)
;    (bind ?NL-diam (ceil (/ (* (max$ $?dim) ?N) (max$ ?lvdims))))
;	(bind ?nl (max ?NL-mass ?NL-vol ?NL-diam))
;	(printout t "NL-diam computed: " ?NL-diam crlf)
;	(printout t "num-launches: " ?nl crlf)
;    (modify ?f (num-launches (max ?NL-mass ?NL-vol ?NL-diam)) (factHistory (str-cat "{R" (?*rulesMap* get LV-SELECTION3::compute-number-of-launches) " " ?fh "}")))
;)

;(defrule LV-SELECTION3::compute-launch-cost-standalone
;    "This rule computes launch cost as the product of number of launches and
;    the cost of a single launch for a standalone satellite."
;
;    ?f <- (MANIFEST::Satellite (launch-vehicle ?lv&~nil) (part-of-constellation nil) (num-launches ?num&~nil) 
;        (launch-cost# nil) (num-of-planes# ?np&~nil) (num-of-sats-per-plane# ?ns&~nil) (factHistory ?fh))
;    =>
;		(bind ?ccost (MatlabFunctions getLaunchVehicleCost ?lv))
;
;		(if (> ?num  (* ?np ?ns)) then (bind ?ccost 1e10)) ; If there are more launches than satellites then infeasible!
;
;    (modify ?f (launch-cost# (* ?num ?ccost)) (launch-cost (fuzzyscprod (cost-fv ?ccost 10) ?num)) (factHistory (str-cat "{R" (?*rulesMap* get LV-SELECTION4::compute-launch-cost-homogeneous) " " ?fh "}")))
;)

(defrule LV-SELECTION4::eliminate-more-expensive-launch-options
    "From all feasible options, eliminate the most expensive ones"

    ?m1 <- (MANIFEST::Satellite (instruments $?instr1) (orbit-string ?orb1) (launch-vehicle ?lv1&~nil) (launch-cost# ?c1&~nil))
    ?m2 <- (MANIFEST::Satellite (instruments $?instr2) (orbit-string ?orb2) (launch-vehicle ?lv2&~nil) (launch-cost# ?c2&~nil))
	(test (eq ?orb1 ?orb2))
	(test (eq $?instr1 $?instr2))
	(test (neq ?lv1 ?lv2))
	(test (<= ?c2 ?c1))

        =>

	 (retract ?m1)
    )
	
(defrule LV-SELECTION4::retract-all-constellations
	"Retracts all constellation facts after launch cost is computed."
	
	?c <- (MANIFEST::Constellation (launch-cost# ?lc&~nil))
	
	=>
	
	(retract ?c))

(deffunction large-enough-height (?lv ?dim); ?dim = (max-diam area height) ; TODO height or diam?
    (bind ?fairing-dimensions (MatlabFunctions getLaunchVehicleDimensions ?lv)); (diam height)
    (bind ?diam (nth$ 1 ?dim))
    (if (eq ?diam nil) then (return 0) else
        ;(printout t "large-enough-height " ?lv " with dimensions " ?fairing-dimensions " sat-diameter " ?diam " " crlf)
        ;(printout t " max fairing dims " (max$ ?fairing-dimensions) " (* 0.8 ?diam) = " (* 0.8 ?diam) crlf)
        (if (> (max$ ?fairing-dimensions) (* 0.8 ?diam)) then
        (return 1)
        else (return 0)
        )
      )

    )

(deffunction large-enough-area (?lv ?dim); ?dim = (max-diam area height) ; TODO height or diam?
    (bind ?fairing-dimensions (MatlabFunctions getLaunchVehicleDimensions ?lv)); (diam height)
    (bind ?area (nth$ 2 ?dim))
    (if (eq ?area nil) then (return 0))
    (if (> (* (nth$ 1 ?fairing-dimensions) (nth$ 2 ?fairing-dimensions)) (* 0.65 ?area)) then
        (return 1)
        else (return 0)
        )
    )

(deffunction get-performance (?lv ?typ ?h ?i)
	(bind ?coeffs (MatlabFunctions getLaunchVehiclePerformanceCoeffs ?lv (str-cat ?typ "-" ?i)))
	(if (isempty$ ?coeffs) then
		(throw new JessException (str-cat "get-performance: coeffs not found for lv typ h i = " ?lv " " ?typ " " ?h " " ?i)))
	(bind ?perf (dot-product$ ?coeffs (create$ 1 ?h (** ?h 2))))
	(return ?perf)
)

(deffunction sufficient-performance (?lv ?m ?typ ?h ?i)
    ;(printout t "sufficient performance " ?lv " m=" ?m " orb=" ?typ " h=" ?a " i=" ?i)
    (bind ?margin 1.1); 10% margin
    (bind ?perf (get-performance ?lv ?typ ?h ?i))
    (return (> ?perf (* ?margin ?m)))
    )
	