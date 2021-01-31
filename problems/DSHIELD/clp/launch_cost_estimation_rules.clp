(defrule LV-SELECTION0::assert-all-possible-lvs
	?orig <- (MANIFEST::Mission (launch-vehicle nil) (factHistory ?fh1))
	?lv <- (DATABASE::Launch-vehicle (id ?name) )
	=>
	(duplicate ?orig (launch-vehicle ?name) (factHistory (str-cat "{R" (?*rulesMap* get LV-SELECTION0::assert-all-possible-lvs) " D" (call ?orig getFactId) " S" (call ?lv getFactId) "}")))
)

(defrule LV-SELECTION1::remove-nils
	?orig <- (MANIFEST::Mission (launch-vehicle nil))

	=>
	(retract ?orig)
)

(defrule LV-SELECTION1::compute-constellation
		"Gathers information from all missions to gather payloads of similar orbits into a constellation"

		?m1 <- (MANIFEST::Mission (id ?sat1) (orbit-string ?orb1) (num-of-planes# ?np1&~0) (num-of-sats-per-plane# ?ns1&~0&~nil) (launch-vehicle ?lv1) )
		?m2 <- (MANIFEST::Mission (id ?sat2) (orbit-string ?orb2) (num-of-planes# 1) (num-of-sats-per-plane# 1) (launch-vehicle ?lv2) )
		(test (eq ?lv1 ?lv2))

		=>

		;(printout t ?orb1 " " ?orb2 " " ?lv1 crlf)

		(bind ?list (MatlabFunctions countSats ?orb1 ?orb2))

		(bind ?npp (nth$ 1 ?list))
		(bind ?nsp (nth$ 2 ?list))
		(bind ?np2 (nth$ 3 ?list))
		(bind ?ns2 (nth$ 4 ?list))

		(modify ?m1 (num-of-planes# (+ ?np1 ?npp)) (num-of-sats-per-plane# (+ ?ns1 ?nsp)))
		(modify ?m2 (num-of-planes# ?np2) (num-of-sats-per-plane# ?ns2))

		;(printout t "Results List: " (+ ?np1 ?npp) " " (+ ?ns1 ?nsp) " " ?np2 " " ?ns2 crlf)
)

(defrule LV-SELECTION1::eliminate-empty-missions
		"Retract any discarded mission that was grouped into another mission"
		?m1 <- (MANIFEST::Mission (Name ?name) (num-of-sats-per-plane# ?ns1&~nil&:(<= ?ns1 0)))

        =>

	 (retract ?m1)
	 ;(printout t "Retracting: " ?m1 crlf)
)

(defrule LV-SELECTION2::compute-planes
		"Gathers information from all missions to gether payloads of similar orbits but in different planes"
		?m1 <- (MANIFEST::Mission (id ?sat1) (orbit-string ?orb1) (num-of-planes# ?np1&~0) (num-of-sats-per-plane# ?ns1&~0&~nil) (launch-vehicle ?lv1) (instruments $?ins1) )
		?m2 <- (MANIFEST::Mission (id ?sat2) (orbit-string ?orb2) (num-of-planes# ?np2&~0) (num-of-sats-per-plane# ?ns2&~0&~nil) (launch-vehicle ?lv2) (instruments $?ins2) )
		(test (eq ?ins1 ?ins2))
		(test (eq ?lv1 ?lv2))
		(test (neq ?m1 ?m2))

		=>

		;(printout t ?orb1 " " ?orb2 " " ?lv1 crlf)

		(bind ?list (MatlabFunctions countPlanes ?orb1 ?np1 ?ns1 ?orb2 ?np2 ?ns2))

		(bind ?Np1 (nth$ 1 ?list))
		(bind ?Ns1 (nth$ 2 ?list))
		(bind ?Np2 (nth$ 3 ?list))
		(bind ?Ns2 (nth$ 4 ?list))

		(modify ?m1 (num-of-planes# ?Np1) (num-of-sats-per-plane# ?Ns1))
		(modify ?m2 (num-of-planes# ?Np2) (num-of-sats-per-plane# ?Ns2))

		;(printout t "Results List: " ?Np1 " " ?Ns1 " " ?Np2 " " ?Ns2 crlf)
)

(defrule LV-SELECTION2::eliminate-empty-missions
		"Retract any discarded mission that was grouped into another mission"
		?m1 <- (MANIFEST::Mission (Name ?name) (num-of-sats-per-plane# ?ns1&~nil&:(<= ?ns1 0)))

        =>

	 (retract ?m1)
	 ;(printout t "Retracting: " ?m1 crlf)
)

(defrule LV-SELECTION3::compute-number-of-launches
    "Compute number of launches needed for a certain constellation on a certain launcher"

      ?f <-  (MANIFEST::Mission (id ?sat) (launch-vehicle ?lv&~nil) (num-launches nil)
        (num-of-planes# ?np&~nil) (num-of-sats-per-plane# ?ns&~nil) (satellite-wet-mass ?m&~nil) (satellite-dimensions $?dim)
        (orbit-type ?orb&~nil) (orbit-semimajor-axis ?a&~nil) (orbit-eccentricity ?e&~nil)
         (orbit-inclination ?i&~nil) (factHistory ?fh))
    =>
    (bind ?N (* ?np ?ns))
    (bind ?perf (get-performance ?lv ?orb (to-km (r-to-h ?a)) ?i))
    ;(printout t "the perf of lv " ?lv " for orbit "  ?orb " a = " ?a " i = " ?i " is " ?perf crlf)
    (bind ?NL-mass (ceil (/ (* ?m ?N) ?perf)))
    (bind ?NL-vol (ceil (/ (* (*$ $?dim) ?N) (*$ (MatlabFunctions getLaunchVehicleDimensions ?lv)))))
    ;(printout t "the dimensoins of lv " ?lv " are diam "  (nth$ 1 (MatlabFunctions getLaunchVehicleDimensions ?lv)) " h = " (nth$ 2 (MatlabFunctions getLaunchVehicleDimensions ?lv)) crlf)
    (bind ?NL-diam (ceil (/ (* (max$ ?dim) ?N) (max$ (MatlabFunctions getLaunchVehicleDimensions ?lv)))))
    (modify ?f (num-launches (max ?NL-mass ?NL-vol ?NL-diam)) (factHistory (str-cat "{R" (?*rulesMap* get LV-SELECTION2::compute-number-of-launches) " " ?fh "}")))
)

(defrule LV-SELECTION4::eliminate-empty-missions
		"Retract any discarded mission that was grouped into another mission"

		?m1 <- (MANIFEST::Mission (Name ?name) (num-of-sats-per-plane# ?ns1&~nil&:(<= ?ns1 0)))

        =>

	 (retract ?m1)
	 ;(printout t "Retracting: " ?m1 crlf)
)

(defrule LV-SELECTION4::compute-launch-cost
    "This rule computes launch cost as the product of number of launches and
    the cost of a single launch."

    ?f <- (MANIFEST::Mission (launch-vehicle ?lv&~nil) (num-launches ?num&~nil)
        (launch-cost# nil) (num-of-planes# ?np&~nil) (num-of-sats-per-plane# ?ns&~nil) (factHistory ?fh))
    =>
		(bind ?ccost (MatlabFunctions getLaunchVehicleCost ?lv))

		(if (> ?num  (* ?np ?ns)) then (bind ?ccost 1e10)) ; If there are more launches than satellites then infeasible!
		;(if (<= ?ns 0) then (bind ?ccost 1e10))
		;(if (<= ?ns 0) then (bind ?num 1))

		;(printout t "Launch cost for " ?np " planes with " ?ns " sats with " ?num " launches: " (* ?num ?ccost) crlf)

    (modify ?f (launch-cost# (* ?num ?ccost)) (launch-cost (fuzzyscprod (cost-fv ?ccost 10) ?num)) (factHistory (str-cat "{R" (?*rulesMap* get LV-SELECTION2::compute-launch-cost) " " ?fh "}")))
	;(modify ?f (launch-cost# (* ?num ?ccost)) )
)

	; cost rule
(defrule LV-SELECTION4::eliminate-more-expensive-launch-options
    "From all feasible options, eliminate the most expensive ones"

    ?m1 <- (MANIFEST::Mission (Name ?name) (launch-vehicle ?lv1&~nil) (launch-cost# ?c1&~nil))
    (MANIFEST::Mission (Name ?name) (launch-vehicle ?lv2&~?lv1&~nil) (launch-cost# ?c2&~nil&:(< ?c2 ?c1)))

        =>

	 (retract ?m1)
    )

(deffunction large-enough-height (?lv ?dim); ?dim = (max-diam area height)
    ;(printout t "large-enough-diameter " ?lv ?dim crlf )
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
    ;(bind ?area (nth$ 2 ?dim))

    )

(deffunction large-enough-area (?lv ?dim); ?dim = (max-diam area height)
    (bind ?fairing-dimensions (MatlabFunctions getLaunchVehicleDimensions ?lv)); (diam height)
    ;(bind ?diam (nth$ 1 ?dim))
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
