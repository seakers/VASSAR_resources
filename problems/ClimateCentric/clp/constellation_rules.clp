; ***********************************************************
;  CONSTELLATION ASSERTION AND LAUNCH COST ESTIMATION RULES
; ***********************************************************

;(defrule CONSTELLATION-ASSERT::assert-constellations
;	"This rule first determines whether there are other satellites with the same orbit and launch vehicle as the reference satellite s1.
;	If there are, the satellite ids are combined into a list (using the function get-all-satellites-in-constellation) and a constellation
;	fact is asserted with the satellite ids list being assigned to the satellite-ids slot.
;	NOTE: This formulation is agnostic of homogeneous or heterogeneous constellations."
;	 
;	(printout t "assert constellations fired." crlf)
;	
;	?s1 <- (MANIFEST::Satellite (id ?id1) (orbit-string ?orb1) (orbit-semimajor-axis ?a1) (orbit-inclination ?i1) (orbit-type ?ot1) (launch-vehicle ?lv1))
;	
;	?sats <- (accumulate (bind ?list (new java.util.ArrayList)) (?list add ?id2)
;			?list
;			(MANIFEST::Satellite (id ?id2&~?id1) (orbit-string ?orb2&:(eq ?orb2 ?orb1)) (launch-vehicle ?lv2&:(eq ?lv2 ?lv1))))
;	(test (> (?sats size) 0))
;	=>
;;	(bind ?sats (get-all-satellites-in-constellation ?id1 ?orb1 ?lv1))
;	(assert (MANIFEST::Constellation (satellite-ids (as-list ?sats)) (launch-vehicle ?lv1) (orbit-string ?orb1) (orbit-type ?ot1) (orbit-semimajor-axis ?a1) (orbit-inclination ?i1) (factHistory "C1")))
;	)

(defrule CONSTELLATION-ASSERT::assert-constellations	
	"This rule assigns one or more satellites to a constellation. All satellites with the same launch vehicle and same orbit are assigned to the same
	constellation. 
	NOTE: This formulation is agnostic to homogeneous and heterogeneous constellations."
	
	?s1 <- (MANIFEST::Satellite (id ?id1) (orbit-string ?orb1) (orbit-semimajor-axis ?a1) (orbit-inclination ?i1) (orbit-type ?ot1) (launch-vehicle ?lv1))
	
	=>
	
;	?sats <- (accumulate (bind ?list (new java.util.ArrayList)) (?list add ?id2)
;			?list
;			(MANIFEST::Satellite (id ?id2) (orbit-string ?orb2&:(eq ?orb2 ?orb1)) (launch-vehicle ?lv2&:(eq ?lv2 ?lv1))))

	(bind ?sats-string (get-all-satellites-in-constellation ?orb1 ?lv1))
	(bind ?eval-command (str-cat "(assert (MANIFEST::Constellation (satellite-ids" ?sats-string ") (launch-vehicle ?lv1) (orbit-string ?orb1) (orbit-type ?ot1) (orbit-semimajor-axis ?a1) (orbit-inclination ?i1) (factHistory "C1")))"))
	
;	(printout t ?eval-command crlf)	
	(eval ?eval-command)
	)
	
(defrule CONSTELLATION-COST-ESTIMATION::assert-constellation-mass-vol-dims
	"This rule asserts the constellation mass, volume and max dimension as the sum of the masses, volumes and max dimensions of the 
	constituent satellites."
	
	?c <- (MANIFEST::Constellation (constellation-mass nil) (constellation-volume nil) (constellation-max-dimension nil) (satellite-ids $?sat-ids) (factHistory ?fh))
	(test (neq ?sat-ids nil))
	=>
	(bind ?const-params (get-constellation-mass-volume-dims $?sat-ids))
;	(printout t ?const-params crlf)
	(modify ?c (constellation-mass (nth$ 1 ?const-params)) (constellation-volume (nth$ 2 ?const-params)) (constellation-max-dimension (nth$ 3 ?const-params)) (factHistory (str-cat "{C" (?*rulesMap* get CONSTELLATION-COST-ESTIMATION::assert-constellation-mass-vol-dims) " " ?fh "}")))
	)
	
; NOT USED TO MAKE SURE EVERY CONSTELLATION HAS AT LEAST ONE LAUNCH VEHICLE ASSOCIATED WITH IT EVENTUALLY
;(defrule CONSTELLATION-COST-ESTIMATION::remove-ineligible-constellation
;	"This rule checks sufficiency of performance in terms of mass budget and volume and max dimension constraints for the constellation given the orbit and 
;	launch vehicle. Satellites in unsatisfactory constellations are retracted."
;	
;	?c <- (MANIFEST::Constellation (constellation-mass ?m&~nil) (constellation-volume ?v&~nil) (constellation-max-dimension ?dim&~nil) (satellite-ids ?sat-ids&~nil)
;		(orbit-semimajor-axis ?a&~nil) (orbit-inclination ?i&~nil) (orbit-type ?ot&~nil) (launch-vehicle ?lv&~nil))
;	=>
;	; Compute mass budget for launch vehicle to carry to the given orbit
;	(bind ?mass-budget (get-performance ?lv ?ot (to-km (r-to-h ?a)) ?i))
;	
;	; Compute launch vehicle volume assuming a cylinder
;	(bind ?lvdims (MatlabFunctions getLaunchVehicleDimensions ?lv))
;	(bind ?d (nth$ 1 ?lvdims))
;	(bind ?h (nth$ 2 ?lvdims))
;	(bind ?lvvol (* (* (** (/ ?d 2) 2) (pi)) ?h))
;	
;	; Compute launch vehicle max dimension
;	(bind ?lvmaxdim (max$ ?lvdims))
;	
;	; Check eligibility of constellation
;	(bind ?eligible true)
;	(if (or (or (> ?m ?mass-budget) (> ?v ?lvvol)) (> ?dim ?lvmaxdim)) then 
;		(bind ?eligible false))
;	
;	; If constellation is ineligible, retract constellation fact and inherent satellite facts
;	(if (eq ?eligible false) then
;		(foreach ?current-id $?sat-ids 
;			(bind ?results (run-query* CONSTELLATION-COST-ESTIMATION::search-satellite-by-id ?current-id))
;			(while (?results next)
;				(bind ?s (?results getObject MANIFEST::Satellite))
;				(retract ?s)))
;		(retract ?c))	
;	)

(defrule CONSTELLATION-COST-ESTIMATION::compute-mass-budget-injection-orbit
	"This rule computes the mass budget for the selected launch vehicle to carry to the assigned injection orbit"
	?c <- (MANIFEST::Constellation (mass-budget# nil) (orbit-type ?orb&~nil) (orbit-string ?orbstr&~nil) (orbit-inclination ?i&~nil) (launch-vehicle ?lv&~nil)
		(orbit-semimajor-axis ?a&~nil) (satellite-ids $?sat-ids&~nil) (factHistory ?fh))
	=>

	(bind ?mb (get-performance ?lv ?orb (to-km (r-to-h ?a)) ?i))
    (modify ?c (mass-budget# ?mb) (factHistory (str-cat "{C" (?*rulesMap* get CONSTELLATION-COST-ESTIMATION::compute-mass-budget-injection-orbit) " " ?fh "}")))
	
	(foreach ?current-id $?sat-ids
		(bind ?results (run-query* CONSTELLATION-COST-ESTIMATION::search-satellite-by-id ?current-id))
		(while (?results next)
			(bind ?s (?results getObject sat))
			(modify ?s (mass-budget# ?mb) (factHistory (str-cat "{C" (?*rulesMap* get CONSTELLATION-COST-ESTIMATION::compute-mass-budget-injection-orbit) " " ?s.factHistory "}"))))
	)
	
;	(printout t "orbit string " ?orbstr crlf)
;	(printout t "mass budget " ?mb crlf)
;	(printout t "launch vehicle " ?lv crlf)
	)
	
(defrule CONSTELLATION-COST-ESTIMATION::compute-number-of-launches
	"This rules computes the number of launches for the constellation."
	
	?c <- (MANIFEST::Constellation (constellation-mass ?m&~nil) (satellite-ids $?sat-ids&~nil) (constellation-volume ?v&~nil) (constellation-max-dimension ?d&~nil) (mass-budget# ?mb&~nil) (orbit-semimajor-axis ?a&~nil) 
		(orbit-inclination ?i&~nil) (orbit-type ?ot&~nil) (orbit-string ?orb&~nil) (launch-vehicle ?lv&~nil) (num-launches nil) (factHistory ?fh))
	
	=>
	
	; Compute launch vehicle volume assuming a cylinder
	(bind ?lvdims (MatlabFunctions getLaunchVehicleDimensions ?lv))
	(bind ?d (nth$ 1 ?lvdims))
	(bind ?h (nth$ 2 ?lvdims))
	(bind ?lvvol (* (* (** (/ ?d 2) 2) (pi)) ?h))
	
	; Compute launch vehicle max dimension
	(bind ?lvmaxdim (max$ ?lvdims))
	
;	(printout t "launch vehicle " ?lv crlf)
;	(printout t "orbit string " ?orb crlf)
;	(printout t "satellite ids " $?sat-ids crlf)
	
;	(printout t "constellation mass " ?m crlf)
;	(printout t "constellation volume " ?v crlf)
;	(printout t "constellation max dimensions " ?d crlf)
	
;	(printout t "mass budget " ?mb crlf)
;	(printout t "launch vehicle vol " ?lvvol crlf)
;	(printout t "LV max dim " ?lvmaxdim crlf)
	
	; Compute number of launches
	(bind ?NL-mass (ceil (/ ?m ?mb)))
	(bind ?NL-vol (ceil (/ ?v ?lvvol)))
	(bind ?NL-diam (ceil (/ ?d ?lvmaxdim)))
	
	(modify ?c (num-launches (max ?NL-mass ?NL-vol ?NL-diam)) (factHistory (str-cat "{C" (?*rulesMap* get CONSTELLATION-COST-ESTIMATION::compute-number-of-launches) " " ?fh "}")))
	
	(foreach ?current-id $?sat-ids
;		(printout t "current id num launches " ?current-id crlf)
		(bind ?results (run-query* CONSTELLATION-COST-ESTIMATION::search-satellite-by-id ?current-id))
		(while (?results next)
			(bind ?s (?results getObject sat))
			(modify ?s (num-launches (max ?NL-mass ?NL-vol ?NL-diam)) (factHistory (str-cat "{C" (?*rulesMap* get CONSTELLATION-COST-ESTIMATION::compute-number-of-launches) " " ?s.factHistory "}"))))
	)
	)
	
(defrule CONSTELLATION-COST-ESTIMATION::compute-constellation-launch-cost
	"This rule computes the overall launch cost for the constellation and assigns the average launch cost to each constituent satellite."
	
	?c <- (MANIFEST::Constellation (launch-cost# nil) (satellite-ids $?sat-ids&~nil) (launch-vehicle ?lv&~nil) (num-launches ?num&~nil) (factHistory ?fh))
	
	=>
	; Compute cost for one launch using the given launch vehicle
	(bind ?ccost (MatlabFunctions getLaunchVehicleCost ?lv))
;	(printout t ?ccost crlf)
	
	; Compute and assert the total constellation launch cost
	(modify ?c (launch-cost# (* ?num ?ccost)) (factHistory (str-cat "{C" (?*rulesMap* get CONSTELLATION-COST-ESTIMATION::compute-constellation-launch-cost) " " ?fh "}")))
	
	; Ascertain number of satellites in constellation
	(bind ?n-sats (length$ $?sat-ids))
	
	; Compute and assert the individual satellite launch costs as the average constellation launch cost
	(foreach ?current-id $?sat-ids
		(bind ?results (run-query* CONSTELLATION-COST-ESTIMATION::search-satellite-by-id ?current-id))
		(while (?results next)
			(bind ?s (?results getObject sat))
			(modify ?s (launch-cost# (/ (* ?num ?ccost) ?n-sats)) (factHistory (str-cat "{C" (?*rulesMap* get CONSTELLATION-COST-ESTIMATION::compute-constellation-launch-cost) " " ?s.factHistory "}"))))
	)
	)
	
(defrule CONSTELLATION-COST-ESTIMATION::compute-constellation-packing-efficiency
	"This rule computes the packing efficiency for the constellation and launch vehicle."
	
	?c <- (MANIFEST::Constellation (satellite-ids $?sat-ids&~nil) (constellation-volume ?v&~nil) (launch-vehicle ?lv&~nil) (num-launches ?num&~nil) (packing-efficiency# nil)
		(orbit-string ?orb&~nil) (mass-budget# ?mb&~nil) (factHistory ?fh))
	
	=>
	
	(bind ?lvdims (get-launch-vehicle-dimensions ?lv))
	(bind ?d (nth$ 1 ?lvdims))
	(bind ?h (nth$ 2 ?lvdims))
	(bind ?lvvol (* (* (** (/ ?d 2) 2) (pi)) ?h))
	
	(bind ?const-launch-mass 0)
	
	(foreach ?current-id $?sat-ids
;		(printout t "current id clm " ?current-id crlf)
		(bind ?results (run-query* CONSTELLATION-COST-ESTIMATION::search-satellite-by-id-pf ?current-id))
		(while (?results next)
;			(printout t "Case 2 clm" crlf)
			(bind ?s (?results getObject sat))
			(bind ?const-launch-mass (+ ?const-launch-mass (* (* ?s.num-of-planes# ?s.num-of-sats-per-plane#) ?s.satellite-launch-mass))))
	)
;	(printout t "const launch mass " ?const-launch-mass crlf)
	
	(bind ?pf-mass (/ ?const-launch-mass (* ?num ?mb)))		
	(bind ?pf-vol (/ ?v (* ?num ?lvvol)))
	(bind ?pf-all (max ?pf-mass ?pf-vol))
	
;	(printout t "number of launches " ?num crlf)
;	(printout t "launch vehicle " ?lv crlf)
;	(printout t "orbit string " ?orb crlf)
;	(printout t "packing efficiency " ?pf-all crlf)
	
	(modify ?c (packing-efficiency# ?pf-all) (factHistory (str-cat "{C" (?*rulesMap* get CONSTELLATION-COST-ESTIMATION::compute-constellation-packing-efficiency) " " ?c.factHistory "}")))
	
	(foreach ?current-id $?sat-ids
		(bind ?results (run-query* CONSTELLATION-COST-ESTIMATION::search-satellite-by-id-pf ?current-id))
		(while (?results next)
;			(printout t "Case 2 pf" crlf)
			(bind ?s (?results getObject sat))
			(modify ?s (lv-pack-efficiency# ?pf-all) (factHistory (str-cat "{C" (?*rulesMap* get CONSTELLATION-COST-ESTIMATION::compute-constellation-packing-efficiency) " " ?s.factHistory "}"))))
	)
	)
	

; ***********************************************************
;              SUPPORTING QUERIES AND FUNCTIONS	
; ***********************************************************

(defquery CONSTELLATION-ASSERT::search-constellation-satellites
	"Queries all satellites with the same orbit and launch vehicle but with different ids."
	(declare (variables ?orbr ?lvr))
	?c <- (MANIFEST::Satellite (id ?id1) (orbit-string ?orbr) (launch-vehicle ?lvr))
	)
	
(deffunction get-all-satellites-in-constellation(?orb ?lv)
	"Function returns the ids of all satellites that belong to a constellation."
;	(printout t "get-all-satellites-in-constellation function used...." crlf)
	(bind ?sat-ids "")
	(bind ?results (run-query* CONSTELLATION-ASSERT::search-constellation-satellites ?orb ?lv))
	(while (?results next)
;		(printout t "some results found....." + (?results getString id1) crlf)
		(bind ?sat-ids (str-cat ?sat-ids " " (?results getString id1)))
	)
;	(printout t ?sat-ids crlf)
	(return ?sat-ids)
	)
	
(defquery CONSTELLATION-COST-ESTIMATION::search-constellation-satellites-heuristics
	"Queries all satellites with the same orbit and launch vehicle but with different ids."
	(declare (variables ?orbr ?lvr))
	?sat <- (MANIFEST::Satellite (id ?id1) (orbit-string ?orbr) (launch-vehicle ?lvr) (num-of-planes# ?np) (num-of-sats-per-plane# ?ns) (satellite-dimensions $?dims) (satellite-launch-mass ?lm) (lv-pack-efficiency# ?lvpf))
	)
	
(defquery CONSTELLATION-COST-ESTIMATION::search-launch-vehicle
	(declare (variables ?name))
	?lv <- (DATABASE::Launch-vehicle (id ?name) (diameter ?d) (height ?h))
	)
	
(deffunction get-launch-vehicle-dimensions(?lvname)
	(bind ?results (run-query* CONSTELLATION-COST-ESTIMATION::search-launch-vehicle ?lvname))
	(while (?results next)
		(bind ?list (create$ (?results getDouble d) (?results getDouble h)))
	)
	(return ?list)
	)
	
(defquery CONSTELLATION-COST-ESTIMATION::search-satellite-by-id
	(declare (variables ?id1))
	?sat <- (MANIFEST::Satellite (id ?id1) (satellite-wet-mass ?m) (satellite-launch-mass ?lm) (satellite-dimensions $?dim) (num-of-planes# ?np) (lv-pack-efficiency# ?pf) (launch-cost# nil) (num-of-sats-per-plane# ?ns) (factHistory ?fh2))
	)
	
(defquery CONSTELLATION-COST-ESTIMATION::search-satellite-by-id-pf
	(declare (variables ?id1))
	?sat <- (MANIFEST::Satellite (id ?id1) (satellite-launch-mass ?lm) (num-of-planes# ?np) (lv-pack-efficiency# ?pf) (num-of-sats-per-plane# ?ns) (factHistory ?fh2))
	)
	
(deffunction get-constellation-mass-volume-dims($?sat-ids)
	(bind ?const-mass 0)
	(bind ?const-vol 0)
	(bind ?const-max-dim 0)
;	(printout t $?sat-ids crlf)
;	(printout t (nth$ 1 $?sat-ids) crlf)
	(if (eq (length$ $?sat-ids) 1) then
;		(printout t "Case 1 of if" crlf)
		(bind ?results (run-query* CONSTELLATION-COST-ESTIMATION::search-satellite-by-id (nth$ 1 $?sat-ids)))
		(while (?results next)
			(bind ?s (?results getObject sat))
			(bind ?const-mass (+ ?const-mass (* (* ?s.num-of-planes# ?s.num-of-sats-per-plane#) ?s.satellite-wet-mass)))
			(bind ?const-vol (+ ?const-vol (* (* ?s.num-of-planes# ?s.num-of-sats-per-plane#) (*$ ?s.satellite-dimensions))))
			(bind ?const-max-dim (+ ?const-max-dim (* (* ?s.num-of-planes# ?s.num-of-sats-per-plane#) (max$ $?s.satellite-dimensions))))
		)
	else 
;		(printout t "Case 2 of if" crlf)
		(foreach ?current-id $?sat-ids
			(bind ?results (run-query* CONSTELLATION-COST-ESTIMATION::search-satellite-by-id ?current-id))
			(while (?results next)
				(bind ?s (?results getObject sat))
				(bind ?const-mass (+ ?const-mass (* (* ?s.num-of-planes# ?s.num-of-sats-per-plane#) ?s.satellite-wet-mass)))
				(bind ?const-vol (+ ?const-vol (* (* ?s.num-of-planes# ?s.num-of-sats-per-plane#) (*$ ?s.satellite-dimensions))))
				(bind ?const-max-dim (+ ?const-max-dim (* (* ?s.num-of-planes# ?s.num-of-sats-per-plane#) (max$ $?s.satellite-dimensions))))
			)
		)
	)	
	(return (create$ ?const-mass ?const-vol ?const-max-dim)))