; *****************************************************
;          DESIGN HEURISTICS COMPUTATION RULES
; *****************************************************

;(defrule HEURISTICS0::compute-packing-efficiency-constellation
;	"This rule computes the packing efficiency for all satellites in a constellation."
;	
;	?c <- (MANIFEST::Constellation (satellite-ids $?sat-ids&~nil) (mass-budget# ?mb&~nil)) 
;	
;	(test (progn
;		(printout t "computing packing efficiency" crlf)
;		(bind $?pe-list (create$ ))
;		(foreach ?id $?sat-ids
;				(bind ?results (run-query* CONSTELLATION-COST-ESTIMATION::search-satellite-by-id ?id))
;				(while (?results next)
;					(append$ $?pe-list (?results getSymbol pf))))
;		(not-contains$ nil $?pe-list)))
;
;	?pack-eff <- (accumulate (bind $?list (create$ ))
;						(append$ $?list ?pf)
;						$?list
;						(MANIFEST::Satellite (id ?id1&:(check-constellation-contains-satellite ?id1 $?sat-ids)) (lv-pack-efficiency# ?pf&~nil))						)
;
;	(test (isempty$ ?pack-eff))			
;	=>
;	(bind ?total-pack-eff 0)
;	
;	(foreach ?id $?sat-ids
;		(bind ?results (run-query* CONSTELLATION-COST-ESTIMATION::search-satellite-by-id ?id))
;		(while (?results next)
;			(bind ?s (?results getObject MANIFEST::Satellite))
;			(bind ?pe-current (compute-packing-efficiency-satellite ?s.num-of-planes# ?s.num-of-sats-per-plane# ?s.satellite-dimensions ?s.launch-vehicle ?s.satellite-launch-mass ?s.mass-budget#))
;			(bind ?total-pack-eff (+ ?total-pack-eff ?pe-current))))
;			
;	(foreach ?id $?sat-ids
;		(bind ?results (run-query* CONSTELLATION-COST-ESTIMATION::search-satellite-by-id ?id))
;		(while (?results next)
;			(bind ?s (?results getObject MANIFEST::Satellite))
;			(modify ?s (lv-pack-efficiency# (/ ?total-pack-eff (length$ $?sat-ids))) (factHistory (str-cat "{R" (?*rulesMap* get HEURISTICS-COMPUTATION1::compute-packing-efficiency-constellation) " " ?s.factHistory "}")))))
;
;	)

;(defrule HEURISTICS0::compute-packing-efficiency
;	"This rule computes the packing efficiency for satellites (whether standalone or part of a constellation)."
;	
;	?m <- (MANIFEST::Satellite (orbit-string ?orb&~nil) (launch-vehicle ?lv&~nil) (num-of-planes# ?np&~nil) (num-of-sats-per-plane# ?ns&~nil) (satellite-dimensions $?dims&~nil)
;		(satellite-launch-mass ?lm&~nil) (mass-budget# ?mb&~nil) (lv-pack-efficiency# nil))
;	
;	=>
;;	(printout t "packing efficiency computation" crlf)
;;	(printout t "launch vehicle " ?lv crlf)
;;	(printout t "orbit string " ?orb crlf)
;	(bind ?N (* ?np ?ns)) 
;
;	(bind ?lvdims (get-launch-vehicle-dimensions ?lv))
;	(bind ?d (nth$ 1 ?lvdims))
;	(bind ?h (nth$ 2 ?lvdims))
;	(bind ?lvvol (* (* (** (/ ?d 2) 2) (pi)) ?h))
;
;	(bind ?pf-mass (/ (* ?lm ?N) ?mb))
;	(bind ?pf-vol (/ (* ?N (*$ $?dims)) ?lvvol))
;
;	(bind $?pf-all (create$ (max ?pf-mass ?pf-vol)))
;	
;	(bind ?results (run-query* HEURISTICS1::search-constellation-satellites-heuristics ?orb ?lv))
;	(while (?results next)	
;		(bind ?s (?results getObject sat))
;;		(printout t "mass budget" ?s.mass-budget# crlf)
;;		(printout t "launch mass" ?s.satellite-launch-mass crlf)
;		(bind ?N-s (* ?s.num-of-planes# ?s.num-of-sats-per-plane#))
;		(bind ?pf-mass-s (/ (* ?N-s ?s.satellite-launch-mass) ?s.mass-budget#))		
;		(bind ?pf-vol-s (/ (* ?N-s (*$ ?s.satellite-dimensions)) ?lvvol))
;		(append$ $?pf-all (max ?pf-mass-s ?pf-vol-s))
;;		(printout t "packing efficiency" $?pf-all crlf))	
;	
;;	(printout t "pack eff sum" (sum$ $?pf-all))
;;	(printout t "pack eff length" (length$ $?pf-all))
;	(bind ?results (run-query* HEURISTICS1::search-constellation-satellites-heuristics ?orb ?lv))
;	(while (?results next)
;		(bind ?s (?results getObject sat))
;		(modify ?s (lv-pack-efficiency# (/ (sum$ $?pf-all) (length$ $?pf-all)))))
;	
;	(modify ?m (lv-pack-efficiency# (/ (sum$ $?pf-all) (length$ $?pf-all))))
;	)
	
(defrule HEURISTICS1::compute-data-rate-duty-cycle
	"This rule computes the data rate duty cycle for the current satellite.
	Assumes 1 seven minute pass at 500Mbps max."
	
	?m <- (MANIFEST::Satellite (data-rate-duty-cycle# nil) (orbit-period# ?orbper&~nil) (payload-data-rate# ?pdr) (factHistory ?fh))
	=>
;	(printout t "Data-rate duty cycle computed" crlf)
	(bind ?perorb (/ (* (* ?orbper 1.2) ?pdr) (* 1024 8)))
	(bind ?drdc (/ (* (* (* (* (/ 1 8192) 500) 60) 7) 1) ?perorb))
	(modify ?m (data-rate-duty-cycle# ?drdc) (factHistory (str-cat "{R" (?*rulesMap* get HEURISTICS-COMPUTATION1::compute-data-rate-duty-cycle) " " ?fh "}")))
	)

(defrule HEURISTICS1::compute-power-duty-cycle
	"This rule computes the power duty cycle for the current satellite.
	Assumes a limit of 10kW."
	
	?m <- (MANIFEST::Satellite (power-duty-cycle# nil) (satellite-BOL-power# ?sbp&~nil) (factHistory ?fh))
	=> 
;	(printout t "Power duty cycle computed" crlf)
	(bind ?pdc (/ 10000 ?sbp))
	(modify ?m (power-duty-cycle# ?pdc) (factHistory (str-cat "{R" (?*rulesMap* get HEURISTICS-COMPUTATION1::compute-power-duty-cycle) " " ?fh "}")))
	)
	
(defrule HEURISTICS1::compute-payload-duty-cycle
	"This rule computes the overall payload duty cycle using the data-rate and power duty cycles."
	
	?m <- (MANIFEST::Satellite (payload-duty-cycle# nil) (data-rate-duty-cycle# ?drdc&~nil) (power-duty-cycle# ?pdc&~nil) (factHistory ?fh))
	=> 
;	(printout t "Payload duty cycle computed" crlf)
	(bind ?paydc (min ?drdc ?pdc))
	(modify ?m (payload-duty-cycle# ?paydc) (factHistory (str-cat "{R" (?*rulesMap* get HEURISTICS-COMPUTATION1::compute-payload-cycle) " " ?fh "}")))
	)
	
; *****************************************************
;            SUPPORTING FUNCTIONS AND QUERIES
; *****************************************************

(defquery HEURISTICS1::search-constellation-satellites-heuristics
	"Queries all satellites with the same orbit and launch vehicle but with different ids."
	(declare (variables ?orbr ?lvr))
	?sat <- (MANIFEST::Satellite (id ?id1) (orbit-string ?orbr) (launch-vehicle ?lvr) (num-of-planes# ?np) (num-of-sats-per-plane# ?ns) (satellite-dimensions $?dims) (satellite-launch-mass ?lm) (mass-budget# ?mb) (lv-pack-efficiency# ?lvpf))
	)

(defquery HEURISTICS1::search-launch-vehicle
	(declare (variables ?name))
	?lv <- (DATABASE::Launch-vehicle (id ?name) (diameter ?d) (height ?h))
	)
	
(deffunction get-launch-vehicle-dimensions(?lvname)
	(bind ?results (run-query* HEURISTICS1::search-launch-vehicle ?lvname))
	(while (?results next)
		(bind ?list (create$ (?results getDouble d) (?results getDouble h)))
	)
	(return ?list)
	)
	
(deffunction compute-packing-efficiency-satellite (?n-p ?n-s ?dim ?l-v ?s-lm ?m-b)
	(bind ?N (* ?n-p ?n-s))
	(bind ?lvdims (get-launch-vehicle-dimensions ?l-v))
	(bind ?d (nth$ 1 ?lvdims))
	(bind ?h (nth$ 2 ?lvdims))
	(bind ?lvvol (* (* (** (/ ?d 2) 2) (pi)) ?h))
	(bind ?eff-mass (/ (* ?s-lm ?N) ?m-b))
	(bind ?eff-vol (/ (* (*$ ?dim) ?N) ?lvvol))
	(bind ?pack-eff (max ?eff-mass ?eff-vol))
	)
	
;(deffunction check-constellation-contains-satellite (?id $?const-ids)
;	(printout t (contains$ 0 (create$ 0 1 2 3)) crlf)
;	(printout t (contains$ nil (create$ 0 1 2 3)) crlf)
;	(printout t (contains$ nil (create$ nil)) crlf)
;
;	(return (contains$ ?id $?const-ids))
;	)
;	
; SAME AS get-performance IN launch_cost_estimation_rules.clp
;(deffunction get-mass-budget (?lv ?typ ?h ?i)
; 	(bind ?coeffs (MatlabFunctions getLaunchVehiclePerformanceCoeffs ?lv (str-cat ?typ "-" ?i)))
;	(if (isempty$ ?coeffs) then 
;		(throw new JessException (str-cat "get-performance: coeffs not found for lv typ h i = " ?lv " " ?typ " " ?h " " ?i)))
;	(bind ?perf (dot-product$ ?coeffs (create$ 1 ?h (** ?h 2))))
;	(return ?perf)
;)
