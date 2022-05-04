;; **********************
;; SAR EXAMPLE ENUMERATION RULES
;; ***************************
;(set-reset-globals FALSE)
;(ENUMERATION::SMAP-ARCHITECTURE (payload SMAP_RAD SMAP_MWR CMIS VIIRS BIOMASS) (num-sats 1) (orbit-altitude 800) (orbit-raan DD) (orbit-type SSO) (orbit-inc SSO) (num-planes 1) (doesnt-fly ) (num-sats-per-plane 1) (num-instruments 5) (sat-assignments 1 1 1 1 1))

(deftemplate MANIFEST::ARCHITECTURE (slot bitString) (multislot payload) (slot num-sats) (slot source) (slot orbit)
    (slot orbit-altitude) (slot orbit-raan) (slot orbit-type) (slot orbit-inc) (slot num-planes)
    (multislot doesnt-fly) (slot num-sats-per-plane) (slot lifecycle-cost) (slot benefit)
	(slot space-segment-cost) (slot ground-segment-cost) (slot pareto-ranking) (slot utility)
	(slot mutate) (slot crossover)  (slot improve) (slot id)
    (slot num-instruments) (multislot sat-assignments) (multislot ground-stations) (multislot constellations) (slot factHistory))

;(defglobal ?*smap-instruments* = 0)
;(bind ?*smap-instruments* (create$ SMAP_RAD SMAP_MWR CMIS VIIRS BIOMASS))
;(deftemplate DATABASE::list-of-instruments (multislot list))

;(deffacts DATABASE::list-of-instruments (DATABASE::list-of-instruments
;        (list (create$ SMAP_RAD SMAP_MWR CMIS VIIRS BIOMASS))))
(reset)
(defquery DATABASE::get-instruments
    ?f <- (DATABASE::list-of-instruments (list $?l))
    )

(deffunction get-instruments ()
    (bind ?res (run-query* DATABASE::get-instruments))
    (?res next)
    (bind ?f (?res getObject f))
    (return ?f.list)
    )

(deffunction get-my-instruments ()
    ;(bind ?list (matlabf get_instrument_list))
    ;(if (listp ?list) then (return ?list) else (return (create$ ?list)))
    (bing ?list (MatlabFunction getInstrumentList))
    (printout t ?list crlf)
  (return ?list)
    )

(deffunction set-my-instruments (?list)
    ;(matlabf get_instrument_list ?list)
    ;(return TRUE)
    )


(deffunction create-index-of ()
    (bind ?prog "(deffunction index-of (?elem) ")
    (bind ?i 0)
    (bind ?smap-instruments (get-instruments))
    (foreach ?el ?smap-instruments
        (bind ?prog (str-cat ?prog " (if (eq (str-compare ?elem " ?el ") 0) then (return " (++ ?i) ")) "))
        )
    (bind ?prog (str-cat ?prog "(return -1))"))
    ;(printout t ?prog crlf)
    (build ?prog)
    )



(create-index-of)


(deffunction get-instrument (?ind)
    (return (nth$ ?ind (get-instruments)))
    )

(deffunction get-my-instrument (?ind)
    (return (eval (nth$ ?ind (get-my-instruments))))
    )



;; **********************
;; SMAP EXAMPLE MANIFEST RULES
;; ***************************


(deffunction to-indexes (?instrs)
    (bind ?list (create$ ))
    (for (bind ?i 1) (<= ?i (length$ ?instrs)) (++ ?i)
        (bind ?list (insert$ ?list ?i (my-index-of (nth$ ?i ?instrs))))
        )
    (return ?list)
    )

(deffunction to-strings (?indexes)

    (return (map get-my-instrument ?indexes))
    )

(deffunction pack-assignment-to-sats (?ass)
    (bind ?list (create$ )) (bind ?n 1)
    (for (bind ?i 1) (<= ?i (length$ ?ass)) (++ ?i)
        (bind ?indexes (find$ ?i ?ass))
        (if (isempty$ ?indexes) then (continue))
        (bind ?list (insert$ ?list ?n "sat")) (++ ?n)
        (bind ?sat-ins (to-strings ?indexes))
        (bind ?list (insert$ ?list ?n ?sat-ins)) (bind ?n (+ ?n (length$ ?sat-ins)))

        )
    (return ?list)
    )



(deffunction pack-sats-to-assignment (?sats ?n)
    (bind ?nsat 0) (bind ?ass (create-list-n$ ?n))
    (for (bind ?i 1) (<= ?i (length$ ?sats)) (++ ?i)
        (bind ?el (nth$ ?i ?sats))
        ;(printout t ?el " eq sat? " (eq "sat" ?el) "  nsat " ?nsat crlf)
        (if (eq "sat" ?el) then (++ ?nsat) else
            ;(printout t "ass " ?ass " element " ?el " index " (index-of ?el) " nsat " ?nsat crlf)
            (bind ?ass (replace$ ?ass (my-index-of ?el) (my-index-of ?el) ?nsat))
            )
        )
    (return ?ass)
    )

;; **********************
;; SAR PAYLOAD SIZING RULES
;; ***************************
(defrule  MANIFEST0::size-SAR-antenna
  "If a P or L-band SAR antenna is given but the mass and volume are unknown, then estimate said values"

  ?ant <- (DATABASE::Instrument  (Intent "Antenna MW radars -SAR-") (Name ?name) (mass# nil) (dimension-x# ?x) (dimension-y# ?y) (dimension-z# nil) (spectral-bands MW-L|MW-P))

  =>
  ; "Values estimated from large circular reflector with patch antenna feed"
  (bind ?z (/ ?x (* 0.45 16)) )
  (bind ?mDish (* 3.1416 (* (/ ?x 2) (/ ?x 2)) ?z 0.1514163) )
  (bind ?feedL (* (/ 3.3 30) ?x))
  (bind ?feedW (/ ?feedL 3))
  (bind ?mainFeed (* 590 0.05 ?feedL ?feedW) )
  (bind ?divFeed (* 590 0.0007 (/ ?feedL 3) (/ ?feedW 3) ) )
  (bind ?mFeed (+ ?mainFeed (* 3 ?divFeed)) )

  ;(printout t ?name " Antenna estimates: [" ?x ", " ?y ", " ?z "], " ?mDish " + " ?mFeed " = " (+ ?mDish ?mFeed) crlf)

  ( modify ?ant (dimension-z# ?z) (mass# (+ ?mDish ?mFeed)) )
)

(defrule MANIFEST0::size-SAR-mass
  "If a P or L-band SAR instrument is given but the mass and dimensions are unknown, then estimate said values"

  ?sar <- (DATABASE::Instrument  (Intent "Imaging MW radars -SAR-") (spectral-bands MW-L|MW-P) (Name ?name) (mass# nil)
                                 (dimension-x# nil) (dimension-y# nil) (dimension-z# nil) (peak-power# ?Pp&~nil))
  =>
  ; "Uses empirical peak power to mass relation"
  (bind ?m (- (* 21.253 (log ?Pp) ) 50.093))

  ; (printout t ?name " electronics mass: " ?m crlf)
  (modify ?sar (mass# ?m) (dimension-x# 0.6) (dimension-y# 0.6) (dimension-z# 0.3))
)

(defrule MANIFEST0::estimate-SAR-power
  "If a P or L-band SAR instrument is given but the average and characteristic power are unknown, then estimate said values"

  ?sar <- (DATABASE::Instrument  (Intent "Imaging MW radars -SAR-") (spectral-bands MW-L|MW-P) (Name ?name) (average-power# nil)
                                 (peak-power# ?Pp&~nil) (characteristic-power# nil) )

  =>
  ; "Assumes a duty cycle of 10%"
  (bind ?Pavg (* 0.1 ?Pp))
  (bind ?Pchar ?Pavg)
  ;(printout t ?name " peak, average, and characteristic power: [" ?Pp ", " ?Pavg ", " ?Pchar "]" crlf)

  ( modify ?sar (average-power# ?Pavg) (characteristic-power# ?Pchar) )
)

(defrule MANIFEST0::estimate-SAR-data-rate
  "If a P or L-band SAR instrument is given but the data rate is unknown, then estimate said value"

  ?sar <- (DATABASE::Instrument  (Intent "Imaging MW radars -SAR-") (spectral-bands MW-L|MW-P) (Name ?name) (average-data-rate# nil) (number-of-looks# ?Nl&~nil) (characteristic-orbit ?alt) (Horizontal-Spatial-Resolution-Along-track# ?dAT&~nil) (Horizontal-Spatial-Resolution-Cross-track# ?dCT&~nil) (Swath# ?sw))
  =>
  ; "Values estimated as basic imager"
  (bind ?resAT (* ?dAT 0.001 (sqrt ?Nl)))
  (bind ?resCT (* ?dCT 0.001 (sqrt ?Nl)))
  (bind ?Vg (/ (sqrt (/ 398600441800000 (* (+ ?alt 63711) 1000)) ) 1000) )

  (bind ?Nb 1.0)
  (bind ?Nx (/ ?sw ?resCT))
  (bind ?bpp 8.0)

  ; (printout t ?resAT " " ?resCT " " ?Vg " " ?sw " " ?Nb " " ?Nx " " ?bpp crlf)

  (bind ?Rb (* ?Nb ?Nx ?bpp ?Vg (/ 1 ?resAT)) )
  (bind ?Rb (* ?Rb 0.000001))
  ; (printout t ?name " data-rate: " ?Rb " Mbps" crlf)

  ( modify ?sar (average-data-rate# ?Rb) (number-of-looks# nil) (Horizontal-Spatial-Resolution-Along-track# nil) (Horizontal-Spatial-Resolution-Cross-track# nil) (Swath# nil) )
)

;; **********************
;; SMAP EXAMPLE CAPABILITY RULES
;; ***************************
(deffunction contains$ (?list ?elem)
    (if (eq (length$ ?list) 0) then (return FALSE))
    (if (eq (first$ ?list) (create$ ?elem)) then (return TRUE) else
         (return (contains$ (rest$ ?list) ?elem)))
    )

(defrule MANIFEST0::SMAP-add-common-dish-to-MWR
    "If we manifest the SMAP radar, radiometer, or both, then we need to
    manifest the share dish"
    (declare (salience 100))
    ?miss <- (MANIFEST::Mission (instruments $?list-of-instruments))
    (test (eq (contains$ ?list-of-instruments SMAP_ANT) FALSE))
    (test (eq (contains$ ?list-of-instruments SMAP_MWR) TRUE))

       =>
    ;(bind ?new-list (add-element$ ?list-of-instruments SMAP_ANT))
    ;(printout t "contains SMAP_ANT = " (eq (subsetp (create$ SMAP_ANT) ?list-of-instruments) FALSE) " new list = " ?new-list crlf))
    (modify ?miss (instruments (add-element$ ?list-of-instruments SMAP_ANT)))

    )

(defrule MANIFEST0::SMAP-add-common-dish-to-RAD
    "If we manifest the SMAP radar, radiometer, or both, then we need to manifest the share dish"
	(declare (salience 100))
    ?miss <- (MANIFEST::Mission (instruments $?list-of-instruments))
	(test (eq (contains$ ?list-of-instruments SMAP_ANT) FALSE))
    (test (eq (contains$ ?list-of-instruments SMAP_RAD) TRUE))
    ;(test (eq (subsetp (create$ SMAP_MWR) ?list-of-instruments) TRUE))
       =>
    ;(bind ?new-list (insert$ ?list-of-instruments (+ 1 (length$ ?list-of-instruments)) SMAP_ANT))
    ;(printout t "contains SMAP_ANT = " (eq (subsetp (create$ SMAP_ANT) ?list-of-instruments) FALSE) " new list = " ?new-list crlf)
    (modify ?miss (instruments (add-element$ ?list-of-instruments SMAP_ANT)))

    )

;(defrule MANIFEST0::Add-common-dish-to-PSAR
;	(declare (salience 100))
;    ?miss <- (MANIFEST::Mission (instruments $?list-of-instruments))
;	  (test (eq (contains$ ?list-of-instruments P-band_ANT) FALSE))
;    (test (eq (contains$ ?list-of-instruments P-band_SAR) TRUE))
;       =>
;    (modify ?miss (instruments (add-element$ ?list-of-instruments P-band_ANT)))
;    ;(printout  t "payload: " $?list-of-instruments  crlf)
;    )

(defrule MANIFEST0::Add-common-dish-to-LSAR
	(declare (salience 100))
    ?miss <- (MANIFEST::Mission (instruments $?list-of-instruments))
	  (test (eq (contains$ ?list-of-instruments L-band_ANT) FALSE))
    (test (eq (contains$ ?list-of-instruments L-band_SAR) TRUE))
       =>
    (modify ?miss (instruments (add-element$ ?list-of-instruments L-band_ANT)))
    ;(printout t "payload: " $?list-of-instruments  crlf)
    )

(defrule MANIFEST::Check-common-dish
	(declare (salience 100))
    ?miss <- (MANIFEST::Mission (instruments $?list-of-instruments))
	(test (eq (contains$ ?list-of-instruments L-band_ANT) TRUE))
    (test (eq (contains$ ?list-of-instruments P-band_ANT) TRUE))
       =>
    (modify ?miss (instruments (del-element$ ?list-of-instruments P-band_ANT)))
    ;(printout t "payload: " $?list-of-instruments  crlf)
    )

(deffunction compute-swath-conical-MWR (?h ?half-scan ?off-nadir)
    (return (* 2 (/ ?h (cos ?off-nadir)) (tan ?half-scan)))
    )

(defrule MANIFEST::compute-SMAP-MWR-spatial-resolution
    ?MWR <- (CAPABILITIES::Manifested-instrument  (Name SMAP_MWR)
         (frequency# ?f&~nil) (orbit-altitude# ?h&~nil) (Horizontal-Spatial-Resolution# nil) (off-axis-angle-plus-minus# ?theta&~nil) (scanning-angle-plus-minus# ?alfa&~nil) (flies-in ?sat))
    (CAPABILITIES::Manifested-instrument  (Name SMAP_ANT) (dimension-x# ?D&~nil) (flies-in ?sat))
    =>
    (bind ?dtheta (to-deg (/ 3e8 (* ?D ?f)))); lambda/D
    (bind ?theta1 (- ?theta (/ ?dtheta 2)))
    (bind ?theta2 (+ ?theta (/ ?dtheta 2)))
    (bind ?x1 (* (* 1000 ?h) (tan ?theta1)))
    (bind ?x2 (* (* 1000 ?h) (tan ?theta2)))
    (bind ?along (- ?x2 ?x1))
    (bind ?cross (* 2 (* (/ ?h (cos ?theta)) (tan (/ ?dtheta 2)))))
    ;(printout t "(compute-swath-conical-MWR ?h ?alfa ?theta) = " (compute-swath-conical-MWR ?h ?alfa ?theta) crlf)

    (bind ?sw (compute-swath-conical-MWR ?h ?alfa ?theta))
    (modify ?MWR (Angular-resolution-elevation# ?dtheta)
    (Horizontal-Spatial-Resolution# ?along)
    (Horizontal-Spatial-Resolution-Along-track# ?along)
        (Horizontal-Spatial-Resolution-Cross-track# ?cross)
        (Swath# ?sw)
        (Field-of-view# ?alfa))
    )

(defrule MANIFEST::compute-CMIS-spatial-resolution
    ?MWR <- (CAPABILITIES::Manifested-instrument  (Name CMIS)
         (frequency# ?f&~nil) (orbit-altitude# ?h&~nil) (dimension-x# ?D&~nil) (Horizontal-Spatial-Resolution# nil) (off-axis-angle-plus-minus# ?theta&~nil) (scanning-angle-plus-minus# ?alfa&~nil) (flies-in ?sat))
    =>
    (bind ?dtheta (to-deg (/ 3e8 (* ?D ?f)))); lambda/D
    (bind ?theta1 (- ?theta (/ ?dtheta 2)))
    (bind ?theta2 (+ ?theta (/ ?dtheta 2)))
    (bind ?x1 (* (* 1000 ?h) (tan ?theta1)))
    (bind ?x2 (* (* 1000 ?h) (tan ?theta2)))
    (bind ?along (- ?x2 ?x1))
    (bind ?cross (* 2 (* (/ ?h (cos  ?theta)) (tan (/ ?dtheta 2)))))
    (bind ?sw (compute-swath-conical-MWR ?h ?alfa ?theta))
    (modify ?MWR (Angular-resolution-elevation# ?dtheta) (Horizontal-Spatial-Resolution# ?along) (Horizontal-Spatial-Resolution-Along-track# ?along)
        (Horizontal-Spatial-Resolution-Cross-track# ?cross) (Swath# ?sw) (Field-of-view# ?alfa))
    )

(defrule MANIFEST::compute-SMAP-RAD-spatial-resolution
    ?RAD <- (CAPABILITIES::Manifested-instrument  (Name SMAP_RAD) (bandwidth# ?B&~nil) (off-axis-angle-plus-minus# ?theta&~nil) (number-of-looks# ?nl&~nil)  (scanning-angle-plus-minus# ?alfa&~nil)
         (frequency# ?f&~nil) (orbit-altitude# ?h&~nil) (Horizontal-Spatial-Resolution# nil) (off-axis-angle-plus-minus# ?theta&~nil) (flies-in ?sat))
    (CAPABILITIES::Manifested-instrument  (Name SMAP_ANT) (dimension-x# ?D&~nil) (flies-in ?sat))
    =>
    ;(printout t "b = " ?B " theta = " ?theta crlf)
    (bind ?dtheta (to-deg (/ 3e8 (* ?D ?f)))); lambda/D
    (bind ?range-res (/ 3e8 (* 2 ?B (sin ?theta))))
    (bind ?sw (* 2 ?h (tan (/ (+ ?alfa ?theta) 2))))

    (printout t "SMAP HSR = " (* ?nl ?range-res) " HSRAT = " (/ ?range-res (sin ?theta)) " HSRCT = " ?range-res crlf)

    (modify ?RAD (Angular-resolution-elevation# ?dtheta) (Horizontal-Spatial-Resolution# (* ?nl ?range-res))
        (Horizontal-Spatial-Resolution-Along-track# (/ ?range-res (sin ?theta)))
        (Horizontal-Spatial-Resolution-Cross-track# ?range-res) (Swath# ?sw)
        (Field-of-view# ?alfa))
    )

(defrule MANIFEST::compute-SAR-spatial-resolution
    ?RAD <- (CAPABILITIES::Manifested-instrument  (Name P-band_SAR|L-band_SAR) (bandwidth# ?B&~nil) (off-axis-angle-plus-minus# ?theta&~nil) (number-of-looks# ?nl&~nil)  (scanning-angle-plus-minus# ?alfa&~nil)
         (frequency# ?f&~nil) (orbit-altitude# ?h&~nil) (Horizontal-Spatial-Resolution# nil) (off-axis-angle-plus-minus# ?theta&~nil) (flies-in ?sat))
    (CAPABILITIES::Manifested-instrument  (Name P-band_ANT|L-band_ANT) (dimension-x# ?D&~nil) (flies-in ?sat))
    (MANIFEST::Mission (orbit-semimajor-axis ?a&~nil))
    =>
    (bind ?dtheta (to-deg (/ 3e8 (* ?D ?f)))); lambda/D
    (bind ?range-res (/ 3e8 (* 2 ?B (sin ?theta))))
    (bind ?sw (* 2 ?h (tan (/ (+ ?alfa ?theta) 2))))

    ;(printout t "b = " ?B " theta = " ?theta crlf)
    ;(printout t "dth = " ?dtheta " rage-res = " ?range-res " swath = " ?sw crlf)
    ;(printout t "SAR HSR = " (/ ?range-res 1) " HSRAT = " (/ (* ?B 1000 (sqrt (/ 3.986e14 ?a))) (* 2 ?nl)) " HSRCT = " ?range-res crlf)

    (modify ?RAD (Angular-resolution-elevation# ?dtheta)
        (Horizontal-Spatial-Resolution# (/ ?range-res 1) )
        (Horizontal-Spatial-Resolution-Along-track# (/ (* ?B 1000 (sqrt (/ 3.986e14 ?a))) (* 2 ?nl)) )
        (Horizontal-Spatial-Resolution-Cross-track# ?range-res)
        (Swath# ?sw))
    )


(defrule MANIFEST::compute-BIOMASS-spatial-resolution
    ?RAD <- (CAPABILITIES::Manifested-instrument  (Name BIOMASS) (dimension-x# ?D&~nil) (bandwidth# ?B&~nil) (off-axis-angle-plus-minus# ?theta&~nil) (number-of-looks# ?nl&~nil)  (scanning-angle-plus-minus# ?alfa&~nil)
         (frequency# ?f&~nil) (orbit-altitude# ?h&~nil) (Horizontal-Spatial-Resolution# nil) (off-axis-angle-plus-minus# ?theta&~nil) (flies-in ?sat))
    =>
    ;(printout t "b = " ?B " theta = " ?theta crlf)
    (bind ?dtheta (to-deg (/ 3e8 (* ?D ?f)))); lambda/D
    (bind ?range-res (/ 3e8 (* 2 ?B (sin ?theta))))
    (bind ?sw (compute-swath-conical-MWR ?h ?alfa ?theta))
    (modify ?RAD (Angular-resolution-elevation# ?dtheta) (Horizontal-Spatial-Resolution# (* ?nl ?range-res))
        (Horizontal-Spatial-Resolution-Along-track# (/ ?range-res (sin ?theta)))
        (Horizontal-Spatial-Resolution-Cross-track# ?range-res) (Swath# ?sw)
        (Field-of-view# ?alfa))
    )

(defrule MANIFEST::compute-Reflectometer-spatial-Resolution
    ?REF <- (CAPABILITIES::Manifested-instrument (Name CYGNSS|SNOOPI) (frequency# ?f&~nil) (off-axis-angle-plus-minus# ?th-incidence&~nil)
            (orbit-altitude# ?h&~nil) (Horizontal-Spatial-Resolution# nil) (flies-in ?sat))

    =>
    (bind ?lambda (/ 3e8 ?f))
    (bind ?hg (- 26559.8 6371))

    (bind ?res-az (sqrt (* ?lambda (/ 1 (** (sin ?th-incidence) 2)) ?h 1e3)))
    (bind ?res-el (* ?res-az (sin ?th-incidence)))
    (bind ?dtheta (* 2 (atan (* ?res-az (cos ?th-incidence) (/ 1 (* 2 ?h)) ) ) ))

    (modify ?REF (Angular-resolution-elevation# ?dtheta)
      (Horizontal-Spatial-Resolution# ?res-az)
      (Horizontal-Spatial-Resolution-Along-track# ?res-az)
      (Horizontal-Spatial-Resolution-Cross-track# ?res-el)
      (Swath# ?res-az)
      (Field-of-view# 35.0)
      )

    (printout t "f = " ?f ", h = " ?h ", hg = " ?hg ", res-az = " ?res-az ", res-el = " ?res-el
                ", lambda = " ?lambda ", th_i = " ?th-incidence ", angular-res = " ?dtheta ", fov = " 35.0 crlf)
    )

(defrule compute-sensitivity-to-soil-moisture-in-vegetation
    "This rule computes the sensitivity to soil moisture in the presence
    of vegetation as a function of frequency, based on [Jackson et al, 91]:
    sensitivity = 10*lambda - 0.4 in BT/SM%"

    ?instr <- (CAPABILITIES::Manifested-instrument (frequency# ?f&~nil)
          (sensitivity# nil))
    =>
    (modify ?instr (sensitivity# (- (* 10 (/ 3e8 ?f)) 0.4)))
    )

(defrule CAPABILITIES::compute-image-distortion-in-side-looking-instruments
    "Computes image distortion for side-looking instruments"
    ?instr <- (CAPABILITIES::Manifested-instrument (orbit-altitude# ?h&~nil)
        (Geometry slant) (characteristic-orbit ?href&~nil) (image-distortion# nil))
    =>
    (modify ?instr (image-distortion# (/ ?h ?href)))

    )

(deffunction between (?x ?mn ?mx)
    ;(printout t ?x " " ?mn " " ?mx crlf)
    ;(printout t ">= x min " (>= ?x ?mn)  " <= x max = " (<= ?x ?mx) crlf)
    (return
        (and
            (>= ?x ?mn) (<= ?x ?mx)))
    )




(deffunction get-soil-penetration (?f)
    (bind ?lambda (/ 3e10 ?f)); lambda in cm
    (if (< ?lambda 1) then (return 0.001))
    (if (between ?lambda 1 2) then (return 0.01))
    (if (between ?lambda 2 5) then (return 0.05))
    (if (between ?lambda 5 10) then (return 0.08))
    (if (between ?lambda 10 25) then (return 0.3))
    (if (between ?lambda 25 50) then (return 0.8))
    (if (> ?lambda 50) then (return 1.0))
    )

(defrule CAPABILITIES::compute-soil-penetration
    ?instr <- (CAPABILITIES::Manifested-instrument (frequency# ?f&~nil)
        (soil-penetration# nil))
    =>
    (modify ?instr (soil-penetration# (get-soil-penetration ?f)))
    )
;; **********************
;; SMAP EXAMPLE EMERGENCE RULES
;; ***************************

(defrule SYNERGIES::SMAP-spatial-disaggregation
    "A frequent coarse spatial resolution measurement can be combined
     with a sparse high spatial resolution measurement to produce
    a frequent high spatial resolution measurement with average accuracy"

    ?m1 <- (REQUIREMENTS::Measurement (Parameter "2.3.2 soil moisture") (Illumination Active)
        (Horizontal-Spatial-Resolution# ?hs1&~nil) (Accuracy# ?a1&~nil)  (Id ?id1) (taken-by ?ins1))
    ?m2 <- (REQUIREMENTS::Measurement (Parameter "2.3.2 soil moisture") (Illumination Passive)
        (Horizontal-Spatial-Resolution# ?hs2&~nil) (Accuracy# ?a2&~nil) (Id ?id2&~?id1) (taken-by ?ins2))
    (SYNERGIES::cross-registered (measurements $?meas&:(contains$ $?meas ?id1)&:(contains$ $?meas ?id2)))
    ;(not (REASONING::stop-improving (Measurement ?p)))
    (test (eq (str-index disaggregated ?ins1) FALSE))
    (test (eq (str-index disaggregated ?ins2) FALSE))

	=>
	;(printout t hola crlf)
    (duplicate ?m1 (Horizontal-Spatial-Resolution# (sqrt (* ?hs1 ?hs2))) (Accuracy# ?a2)
            (Id (str-cat ?id1 "-disaggregated" ?id2))
            (taken-by (str-cat ?ins1 "-" ?ins2 "-disaggregated")));; fuzzy-max in accuracy is OK because joint product does provide 4% accuracy
)


(defrule SYNERGIES::carbon-net-ecosystem-exchange
    "Carbon net ecosystem exchange data products are produced from the combination of soil moisture, land surface temperature,
    landcover classificatin, and vegetation gross primary productivity [Entekhabi et al, 2010]"

    ?SM <- (REQUIREMENTS::Measurement (Parameter "2.3.2 soil moisture")  (Id ?id1) (taken-by ?ins1))
    (REQUIREMENTS::Measurement (Parameter "2.5.1 Surface temperature -land-") (Id ?id2) (taken-by ?ins2))
    (REQUIREMENTS::Measurement (Parameter "2.6.2 landcover status")  (Id ?id3) (taken-by ?ins3))
    (REQUIREMENTS::Measurement (Parameter "2.4.2 vegetation state") (Id ?id4) (taken-by ?ins4))
    (SYNERGIES::cross-registered (measurements $?m)) (test (subsetp (create$ ?id1 ?id2 ?id3 ?id4) $?m))
    ;(not (REQUIREMENTS::Measurement (Parameter "2.3.3 Carbon net ecosystem exchange NEE")))
	=>

    (duplicate ?SM (Parameter "2.3.3 Carbon net ecosystem exchange NEE")
            (Id (str-cat ?id1 "-syn" ?id2 "-syn" ?id3 "-syn" ?id4))
            (taken-by (str-cat ?ins1 "-syn" ?ins2 "-syn-" ?ins3 "-syn-" ?ins4)));; fuzzy-max in accuracy is OK because joint product does provide 4% accuracy
)

(defrule SYNERGIES::snow-cover-3freqs
    "Full accuracy of snow cover product is obtained when IR, X, and L-band measurements
    are combined "

    ?IR <- (REQUIREMENTS::Measurement (Parameter "4.2.4 snow cover") (Spectral-region opt-VNIR+TIR)
         (Accuracy Low) (Id ?id1) (taken-by ?ins1))

    ?X <- (REQUIREMENTS::Measurement (Parameter "4.2.4 snow cover") (Spectral-region MW-X+Ka+Ku+mm)
         (Accuracy Low) (Id ?id2) (taken-by ?ins2))

    ?L <- (REQUIREMENTS::Measurement (Parameter "4.2.4 snow cover") (Spectral-region MW-L)
        (Accuracy Low) (Id ?id3) (taken-by ?ins3))

	(SYNERGIES::cross-registered (measurements $?m)) (test (subsetp (create$ ?id1 ?id2 ?id3) $?m))
    =>

    (duplicate ?X (Accuracy High) (Id (str-cat ?id1 "-syn-" ?id2 "-syn-" ?id3))
            (taken-by (str-cat ?ins1 "-syn-" ?ins2 "-syn-" ?ins3)))
    )

(defrule SYNERGIES::snow-cover-2freqs
    "Medium accuracy of snow cover product is obtained when IR and MW measurements
    are combined "

    ?IR <- (REQUIREMENTS::Measurement (Parameter "4.2.4 snow cover") (Spectral-region opt-VNIR+TIR)
         (Accuracy Low) (Id ?id1) (taken-by ?ins1))

    ?MW <- (REQUIREMENTS::Measurement (Parameter "4.2.4 snow cover") (Spectral-region ?sr&~nil)
         (Accuracy Low) (Id ?id2) (taken-by ?ins2))

    (test (neq (str-index MW ?sr) FALSE))

	(SYNERGIES::cross-registered (measurements $?m)) (test (subsetp (create$ ?id1 ?id2) $?m))
    =>
    ;(printout t "snow cover 2 freqs " crlf)
    (duplicate ?MW (Accuracy Medium) (Id (str-cat ?id1 "-syn-" ?id2 ))
            (taken-by (str-cat ?ins1 "-syn-" ?ins2)))
    )

(defrule SYNERGIES::ice-cover-3freqs
    "Full accuracy of ice cover product is obtained when IR, X, and L-band measurements
    are combined "

    ?IR <- (REQUIREMENTS::Measurement (Parameter "4.3.2 Sea ice cover") (Spectral-region opt-VNIR+TIR)
         (Accuracy Low) (Id ?id1) (taken-by ?ins1))

    ?X <- (REQUIREMENTS::Measurement (Parameter "4.3.2 Sea ice cover") (Spectral-region MW-X+Ka+Ku+mm)
        (Accuracy Low) (Id ?id2) (taken-by ?ins2))

    ?L <- (REQUIREMENTS::Measurement (Parameter "4.3.2 Sea ice cover") (Spectral-region MW-L)
         (Accuracy Low) (Id ?id3) (taken-by ?ins3))

	(SYNERGIES::cross-registered (measurements $?m)) (test (subsetp (create$ ?id1 ?id2 ?id3) $?m))
    =>

    (duplicate ?X (Accuracy High) (Id (str-cat ?id1 "-syn-" ?id2 "-syn-" ?id3))
            (taken-by (str-cat ?ins1 "-syn-" ?ins2 "-syn-" ?ins3)))
    )

(defrule SYNERGIES::ice-cover-2freqs
    "Medium accuracy of ice cover product is obtained when IR and MW measurements
    are combined "

    ?IR <- (REQUIREMENTS::Measurement (Parameter "4.3.2 Sea ice cover") (Spectral-region opt-VNIR+TIR)
        (Accuracy Low) (Id ?id1) (taken-by ?ins1))

    ?MW <- (REQUIREMENTS::Measurement (Parameter "4.3.2 Sea ice cover") (Spectral-region ?sr&~nil)
         (Accuracy Low) (Id ?id2) (taken-by ?ins2))

    (test (neq (str-index MW ?sr) FALSE))

	(SYNERGIES::cross-registered (measurements $?m)) (test (subsetp (create$ ?id1 ?id2) $?m))
    =>

    (duplicate ?MW (Accuracy Medium) (Id (str-cat ?id1 "-syn-" ?id2 ))
            (taken-by (str-cat ?ins1 "-syn-" ?ins2)))
    )

(defrule SYNERGIES::ocean-salinity-space-average
    "L-band passive radiometer can yield 0.2psu data if we average in space
    (from SMAP applications report)"

    ?L <- (REQUIREMENTS::Measurement (Parameter "3.3.1 Ocean salinity") (Accuracy# ?a1&~nil)
        (Horizontal-Spatial-Resolution# ?hsr1&~nil) (Id ?id1) (taken-by ?ins1&SMAP_MWR))
    (test (eq (str-index averaged ?ins1) FALSE))
    =>
    (bind ?a2 (/ ?a1 3.0))
    (bind ?hsr2 (* ?hsr1 3.0))
    (duplicate ?L (Accuracy# ?a2) (Horizontal-Spatial-Resolution# ?hsr2) (Id (str-cat ?id1 "-space-averaged"))
        (taken-by (str-cat ?ins1 "-space-averaged")))
    )

(defrule SYNERGIES::ocean-wind-space-average
    "L-band passive radiometer can yield 1 m/s wind data if we average in space
    (from SMAP applications report)"

    ?L <- (REQUIREMENTS::Measurement (Parameter "3.4.1 Ocean surface wind speed") (Accuracy# ?a1&~nil)
        (Horizontal-Spatial-Resolution# ?hsr1&~nil) (Id ?id1) (taken-by ?ins1&SMAP_MWR))
    (test (eq (str-index averaged ?ins1) FALSE))
    =>
    (bind ?a2 (/ ?a1 2.0))
    (bind ?hsr2 (* ?hsr1 2.0))
    (duplicate ?L (Accuracy# ?a2) (Horizontal-Spatial-Resolution# ?hsr2) (Id (str-cat ?id1 "-space-averaged"))
        (taken-by (str-cat ?ins1 "-space-averaged")))
    )
;; **********************
;; SMAP VALUES BY DEFAULT
;; ***************************

(defrule MANIFEST::put-ADCS-values-by-default
"Use values  by default for satellite parameters"
?miss <- (MANIFEST::Mission  (ADCS-requirement nil))
=>
(modify ?miss (ADCS-requirement 0.01) (ADCS-type three-axis) (propellant-ADCS mono-n2h4)
 (propellant-injection mono-n2h4) (slew-angle 2.0)
)
)
;(defrule CAPABILITIES::cross-register-measurements-from-cross-registered-instruments;
;	(CAPABILITIES::Manifested-instrument (Name ?ins1) (measurement-ids $?m1))
	;(CAPABILITIES::Manifested-instrument (Name ?ins2&~?ins1) (measurement-ids $?m2))
	;(SYNERGIES::cross-registered-instruments (instruments $?ins))
	;(test (contains$ $?ins ?ins1))
	;(test (contains$ $?ins ?ins2))
;
;	=>
;	(assert (SYNERGIES::cross-registered (measurements (str-cat $?m1 $?m2))))
;)

(defrule CAPABILITIES-CROSS-REGISTER::cross-register-measurements-from-cross-registered-instruments
	(SYNERGIES::cross-registered-instruments (instruments $?ins))
	?c <- (accumulate (bind ?str "")                        ;; initializer
                (bind ?str (str-cat ?str " " $?m1))                    ;; action
                ?str                                        ;; result
                (CAPABILITIES::Manifested-instrument (Name ?ins1&:(contains$ $?ins ?ins1)) (measurement-ids $?m1))
				) ;; CE
	=>
	(assert (SYNERGIES::cross-registered (measurements (explode$ ?c)) (degree-of-cross-registration spacecraft)))
	;(printout t ?c crlf)
)
