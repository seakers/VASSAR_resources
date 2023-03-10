;; **********************
;; SMAP EXAMPLE ENUMERATION RULES
;; ***************************
;(set-reset-globals FALSE)
;(ENUMERATION::SMAP-ARCHITECTURE (payload SMAP_RAD SMAP_MWR CMIS VIIRS BIOMASS) (num-sats 1) (orbit-altitude 800) (orbit-raan DD) (orbit-type SSO) (orbit-inc SSO) (num-planes 1) (doesnt-fly ) (num-sats-per-plane 1) (num-instruments 5) (sat-assignments 1 1 1 1 1))

(deftemplate MANIFEST::ARCHITECTURE "models a satellite with instruments _payload with orbit _orbit" (slot bitString) (multislot payload) (slot num-sats) (slot source) (slot orbit)
    (slot orbit-altitude) (slot orbit-raan) (slot orbit-type) (slot orbit-inc) (slot num-planes)
    (multislot doesnt-fly) (slot num-sats-per-plane) (slot lifecycle-cost) (slot benefit)  
	(slot space-segment-cost) (slot ground-segment-cost) (slot pareto-ranking) (slot utility)
	(slot mutate) (slot crossover)  (slot improve) (slot id) (multislot heuristics-to-apply) (multislot heuristics-applied) 
    (slot num-instruments) (multislot sat-assignments) (multislot ground-stations) (multislot constellations) (slot factHistory))

;(defglobal ?*smap-instruments* = 0)
;(bind ?*smap-instruments* (create$ SMAP_RAD SMAP_MWR CMIS VIIRS BIOMASS))

; this deftemplate is moved to JessInitializer.java
;(deftemplate DATABASE::list-of-instruments (multislot list) (slot factHistory))

; this deffacts is moved to JessInitializer.java
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
	(return (MatlabFunction getInstrumentList))
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
;; SMAP EXAMPLE CAPABILITY RULES
;; ***************************
(deffunction contains$ (?list ?elem)
    (if (eq (length$ ?list) 0) then (return FALSE))
    (if (eq (first$ ?list) (create$ ?elem)) then (return TRUE) else
         (return (contains$ (rest$ ?list) ?elem)))    
    )


(deffunction compute-swath-conical-MWR (?h ?half-scan ?off-nadir)
    (return (* 2 (/ ?h (cos ?off-nadir)) (tan ?half-scan)))
    )






(defrule MANIFEST::compute-spatial-resolution-and-swath-nadir-looking-no-scanning-imagers
    "calculates the spatial resolution and swath for a nadir looking instrument without scanning, using angular resolution, orbit altitude, and field of view. Equations: $dx = 2\times 1000 \times h \times \tan (\frac{d\theta}{2})$ and $sw = 2 \times 1000 \times h \times \tan (\frac{fov}{2})$, where $d\theta$ is the angular resolution, $h$ is the orbit altitude, and $fov$ is the field of view"
    ?MWR <- (CAPABILITIES::Manifested-instrument  (Geometry nadir) (scanning no-scanning) (Intent "Imaging multi-spectral radiometers -passive MW-"|"Imaging multi-spectral radiometers -passive optical-"|"High resolution optical imagers")
         (Angular-resolution# ?dtheta&~nil) (orbit-altitude# ?h&~nil) (Field-of-view# ?fov&~nil) (Horizontal-Spatial-Resolution# nil) (flies-in ?sat)(factHistory ?fh))
    =>
    (bind ?dx (* 2 (* 1000 ?h) (tan (/ ?dtheta 2))))
    (bind ?sw (* 2 (* 1000 ?h) (tan (/ ?fov 2))))
    (modify ?MWR (Horizontal-Spatial-Resolution# ?dx)  (Swath# ?sw) (factHistory (str-cat "{R" (?*rulesMap* get MANIFEST::compute-spatial-resolution-and-swath-nadir-looking-no-scanning-imagers) " " ?fh "}")))
    )
(defrule MANIFEST::compute-spatial-resolution-nadir-and-swath-looking-cross-track-scanning-imagers
    "calculates the spatial resolution and swath for a cross track scanning imager facing nadir using orbit altitude, angular resolution, and scanning angle. The equations used are: $ \theta_1 = \theta - \frac{\Delta\theta}{2} $, $ \theta_2 = \theta + \frac{\Delta\theta}{2} $, $ x_1 = 1000h \tan(\theta_1) $,  $ x_2 = 1000h \tan(\theta_2) $,  along = x_2 - x_1 $, $ cross = 2 \left(\frac{h}{\cos(\theta)} \tan\left(\frac{\Delta\theta}{2}\right)\right) $, $ swath = 2 \cdot 1000h \tan(\theta) $, where $h$ is the orbit altitude, $\theta$ is the scanning angle, and $\Delta\theta$ is the angular resolution."
    ?MWR <- (CAPABILITIES::Manifested-instrument  (Geometry nadir) (scanning cross-track) (Intent "Imaging multi-spectral radiometers -passive MW-"|"Imaging multi-spectral radiometers -passive optical-"|"High resolution optical imagers")
         (Angular-resolution# ?dtheta&~nil) (orbit-altitude# ?h&~nil) (Horizontal-Spatial-Resolution# nil) (scanning-angle-plus-minus# ?theta&~nil) (flies-in ?sat) (factHistory ?fh))
    =>
    (bind ?theta1 (- ?theta (/ ?dtheta 2)))
    (bind ?theta2 (+ ?theta (/ ?dtheta 2)))
    (bind ?x1 (* (* 1000 ?h) (tan ?theta1)))
    (bind ?x2 (* (* 1000 ?h) (tan ?theta2)))
    (bind ?along (- ?x2 ?x1))
    (bind ?cross (* 2 (* (/ ?h (cos ?theta)) (tan (/ ?dtheta 2)))))
    ;(printout t "(compute-swath-conical-MWR ?h ?alfa ?theta) = " (compute-swath-conical-MWR ?h ?alfa ?theta) crlf)
    (bind ?sw (* 2 (* 1000 ?h) (tan ?theta)))
    (modify ?MWR  (Horizontal-Spatial-Resolution# ?along) (Horizontal-Spatial-Resolution-Along-track# ?along) 
        (Horizontal-Spatial-Resolution-Cross-track# ?cross) (Swath# ?sw) (factHistory (str-cat "{R" (?*rulesMap* get MANIFEST::compute-spatial-resolution-nadir-and-swath-looking-cross-track-scanning-imagers) " " ?fh "}")))
    )
	
(defrule MANIFEST::compute-spatial-resolution-and-swath-side-looking-conical-scanning-imagers
    "calculates the spatial resolution and swath of side-looking conical scanning imagers using the satellite's altitude, aperture size, and scanning angle. Equations: $\theta_1 = \theta - \frac{\lambda}{D}$, $\theta_2 = \theta + \frac{\lambda}{D}$, $along = x_2 - x_1$, $cross = 2\times \frac{h}{cos(\theta)}\times tan(\frac{\lambda}{2D})$, where $\lambda$ is the wavelength of the sensor, $D$ is the aperture size, $\theta$ is the scanning angle, $h$ is the satellite altitude, $x_1$ and $x_2$ are the edges of the swath, and $along$ and $cross$ are the spatial resolutions along-track and cross-track, respectively"
    ?MWR <- (CAPABILITIES::Manifested-instrument  (Geometry side-looking) (scanning conical) (Intent "Imaging multi-spectral radiometers -passive MW-"|"Imaging multi-spectral radiometers -passive optical-"|"High resolution optical imagers")
         (frequency# ?f&~nil) (Aperture# ?D&~nil) (orbit-altitude# ?h&~nil) (Horizontal-Spatial-Resolution# nil) (off-axis-angle-plus-minus# ?alfa&~nil) (scanning-angle-plus-minus# ?theta&~nil) (flies-in ?sat) (factHistory ?fh))
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
    (modify ?MWR (Angular-resolution-elevation# ?dtheta) (Horizontal-Spatial-Resolution# ?along) (Horizontal-Spatial-Resolution-Along-track# ?along) 
        (Horizontal-Spatial-Resolution-Cross-track# ?cross) (Swath# ?sw)(factHistory (str-cat "{R" (?*rulesMap* get MANIFEST::compute-spatial-resolution-and-swath-side-looking-conical-scanning-imagers) " " ?fh "}")))
    )

(defrule MANIFEST::compute-SAR-spatial-resolution
    "calculates the horizontal spatial resolution and swath for an imaging MW radar-SAR given the instrument's bandwidth, off-axis angle, number of looks, scanning angle, frequency, orbit altitude, and aperture. Equations: $\theta_{D} = \frac{1}{\lambda/D}$, $\text{Range resolution} = \frac{c}{2B\sin\theta}$, $\text{Swath width} = 2h\tan\left(\frac{\alpha + \theta}{2}\right)$, where $\lambda/D$ is the angular resolution in elevation, $B$ is the bandwidth, $\theta$ is the off-axis angle, $c$ is the speed of light, $h$ is the orbit altitude, $\alpha$ is the scanning angle, and $D$ is the aperture"
    ?RAD <- (CAPABILITIES::Manifested-instrument  (bandwidth# ?B&~nil) (off-axis-angle-plus-minus# ?theta&~nil) (number-of-looks# ?nl&~nil)  (scanning-angle-plus-minus# ?alfa&~nil)
         (frequency# ?f&~nil) (orbit-altitude# ?h&~nil) (Aperture# ?D&~nil) (Horizontal-Spatial-Resolution# nil) (Intent "Imaging MW radars -SAR-") (off-axis-angle-plus-minus# ?theta&~nil) (flies-in ?sat) (factHistory ?fh))
    =>
    ;(printout t "b = " ?B " theta = " ?theta crlf)
    (bind ?dtheta (to-deg (/ 3e8 (* ?D ?f)))); lambda/D
    (bind ?range-res (/ 3e8 (* 2 ?B (sin ?theta))))
    (bind ?sw (* 2 ?h (tan (/ (+ ?alfa ?theta) 2))))
    (modify ?RAD (Angular-resolution-elevation# ?dtheta) (Horizontal-Spatial-Resolution# (* ?nl ?range-res)) 
        (Horizontal-Spatial-Resolution-Along-track# (/ ?range-res (sin ?theta))) 
        (Horizontal-Spatial-Resolution-Cross-track# ?range-res) (Swath# ?sw) (factHistory (str-cat "{R" (?*rulesMap* get MANIFEST::compute-SAR-spatial-resolution) " " ?fh "}")) 
     )
    )







(defrule compute-sensitivity-to-soil-moisture-in-vegetation
    "calculates the sensitivity of an instrument to soil moisture in the presence of vegetation as a function of frequency, using the equation: sensitivity = 10$\lambda$ - 0.4 in BT/SM%"
    
    ?instr <- (CAPABILITIES::Manifested-instrument (frequency# ?f&~nil)
          (sensitivity# nil) (factHistory ?fh))
    =>
    (modify ?instr (sensitivity# (- (* 10 (/ 3e8 ?f)) 0.4)) (factHistory (str-cat "{R" (?*rulesMap* get compute-sensitivity-to-soil-moisture-in-vegetation) " " ?fh "}")))
    )

(defrule CAPABILITIES::compute-image-distortion-in-side-looking-instruments
    "calculates the image distortion for side-looking instruments using the equation: $\text{image-distortion#} = \frac{\text{orbit-altitude#}}{\text{characteristic-orbit}}$"
    ?instr <- (CAPABILITIES::Manifested-instrument (orbit-altitude# ?h&~nil) 
        (Geometry slant)  (characteristic-orbit ?href&~nil) (image-distortion# nil) (factHistory ?fh))
    =>
       
    (modify ?instr (image-distortion# (/ ?h ?href)) (factHistory (str-cat "{R" (?*rulesMap* get CAPABILITIES::compute-image-distortion-in-side-looking-instruments) " " ?fh "}"))) 
        
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
    "calculates the soil penetration capability of an instrument based on its operating frequency using a predefined function that maps frequency to penetration depth. Equations: $\lambda = \frac{3e10}{f}$ where $\lambda$ is the wavelength in centimeters and $f$ is the operating frequency in Hertz, and a set of conditional statements mapping $\lambda$ to soil penetration depth"
    ?instr <- (CAPABILITIES::Manifested-instrument (frequency# ?f&~nil) 
        (soil-penetration# nil) (factHistory ?fh))
    =>
    (modify ?instr (soil-penetration# (get-soil-penetration ?f)) (factHistory (str-cat "{R" (?*rulesMap* get CAPABILITIES::compute-soil-penetration) " " ?fh "}")))
    )
;; **********************
;; SMAP EXAMPLE EMERGENCE RULES
;; ***************************

(defrule SYNERGIES::SMAP-spatial-disaggregation 
    "identifies how combining frequent coarse spatial resolution measurements with sparse high spatial resolution measurements can produce a frequent high spatial resolution measurement with average accuracy, using the equation Horizontal-Spatial-Resolution# (sqrt (* ?hs1 ?hs2)) to calculate the new horizontal spatial resolution and the fuzzy-max function to determine the joint product's accuracy"
    
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
            (taken-by (str-cat ?ins1 "-" ?ins2 "-disaggregated")) (factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::SMAP-spatial-disaggregation ) " D" (call ?m1 getFactId) " S" (call ?m2 getFactId) "}")));; fuzzy-max in accuracy is OK because joint product does provide 4% accuracy
)

;(defrule SYNERGIES::AM-PM-diurnal-cycle
;?m1 <- (REQUIREMENTS::Measurement (Parameter ?p) (diurnal-cycle AM-only) (Id ?id1) (taken-by ?ins1))
;(REQUIREMENTS::Measurement (Parameter ?p) (diurnal-cycle PM-only) (Id ?id2) (taken-by ?ins2));
;
;=>
;(modify ?m1 (diurnal-cycle AM-PM) (Id (str-cat ?id1 "-syn-" ?id2)) (taken-by (str-cat ?ins1 "-syn-" ?ins2))) 
;)

(defrule SYNERGIES-ACROSS-ORBITS::AM-PM-diurnal-cycle
"identifies synergies between two of the same measurements on durinal-cycle. If one measurement has AM-only and the other PM-only, both measurements get updated to AM-PM"
?m1 <- (REQUIREMENTS::Measurement (Parameter ?p) (diurnal-cycle AM-only) (Id ?id1) (taken-by ?ins1))
(REQUIREMENTS::Measurement (Parameter ?p) (diurnal-cycle PM-only) (Id ?id2) (taken-by ?ins2) (factHistory ?fh))

=>
(modify ?m1 (diurnal-cycle AM-PM) (Id (str-cat ?id1 "-syn-" ?id2)) (taken-by (str-cat ?ins1 "-syn-" ?ins2)) (factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES-ACROSS-ORBITS::AM-PM-diurnal-cycle) " " ?fh "}"))) 
)
(defrule SYNERGIES::ozone
"identifies synergies between cross-registered ozone measurements and updates their accuracy to 2.5 if their initial accuracy is 5.0"
?m1 <- (REQUIREMENTS::Measurement (Parameter "1.8.2 O3"|"1.8.26 O3 - lower troposphere"|"1.8.27 O3 - upper troposphere"|"1.8.28 O3 - lower stratosphere"|"1.8.29 O3 - upper stratosphere") (Accuracy# 5.0) (Id ?id1) (taken-by ?ins1) (factHistory ?fh1))
?m2 <- (REQUIREMENTS::Measurement (Parameter "1.8.2 O3"|"1.8.26 O3 - lower troposphere"|"1.8.27 O3 - upper troposphere"|"1.8.28 O3 - lower stratosphere"|"1.8.29 O3 - upper stratosphere") (Accuracy# 5.0) (Id ?id2&~?id1) (taken-by ?ins2&~?ins1) (factHistory ?fh2))
(SYNERGIES::cross-registered (measurements $?m)) (test (subsetp (create$ ?id1 ?id2) $?m))
=>
(modify ?m1 (Accuracy# 2.5)(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::ozone) " " ?fh1 " S" (call ?m2 getFactId) "}")))
(modify ?m2 (Accuracy# 2.5)(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::ozone) " " ?fh2 " S" (call ?m1 getFactId) "}")))
)
(defrule SYNERGIES::dry-atmosphere-correction-for-ocean-color
"identifies synergies between ocean color measurements and aerosol height/optical depth measurements, allowing for a dry atmosphere correction to be applied to the former, according to the equation: $RMS_{system-tropo-dry} \rightarrow RMS_{system-tropo-dry}^{Low}$"
?m1 <- (REQUIREMENTS::Measurement (Parameter "3.1.5 Ocean color - Dissolved Organic Matter"|"3.1.4 Ocean color - chlorophyl"|"3.1.6 Ocean color - Suspended Sediments") (rms-system-tropo-dry# High) (Id ?id1) (taken-by ?ins1) (factHistory ?fh))
?sub1 <- (REQUIREMENTS::Measurement (Parameter "1.1.1 aerosol height/optical depth") (Id ?id2&~?id1) (taken-by ?ins2&~?ins1))
?sub2 <- (SYNERGIES::cross-registered (measurements $?m)) (test (subsetp (create$ ?id1 ?id2) $?m))
=>
(modify ?m1 (rms-system-tropo-dry# Low)(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::dry-atmosphere-correction-for-ocean-color) " " ?fh " S" (call ?sub1 getFactId) " S" (call ?sub2 getFactId) "}")))
)
(defrule SYNERGIES::dry-atmosphere-correction-for-ocean-altimetry
"identifies a synergy between a sea level height measurement with a high RMS tropospheric dry correction and an aerosol height/optical depth measurement, and creates a new measurement with a low RMS tropospheric dry correction that combines both inputs"
?m1 <- (REQUIREMENTS::Measurement (Parameter "3.2.1 Sea level height") (rms-system-tropo-dry# High) (Id ?id1) (taken-by ?ins1) (factHistory ?fh))
?sub1 <-(REQUIREMENTS::Measurement (Parameter "1.1.1 aerosol height/optical depth") (Id ?id2&~?id1) (taken-by ?ins2&~?ins1))
?sub2 <-(SYNERGIES::cross-registered (measurements $?m)) (test (subsetp (create$ ?id1 ?id2) $?m))
=>
(modify ?m1 (rms-system-tropo-dry# Low) (taken-by (str-cat ?ins1 "-syn"  ?ins2))(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::dry-atmosphere-correction-for-ocean-altimetry) " " ?fh " S" (call ?sub1 getFactId) " S" (call ?sub2 getFactId) "}")))
)
;; A4.Clouds and aerosols
(defrule SYNERGIES::clouds-and-aerosols
"identifies a synergy between measurements of cloud amount/distribution and aerosol absorption optical depth, resulting in a new measurement"
?m1 <- (REQUIREMENTS::Measurement (Parameter "1.5.3 Cloud amount/distribution -horizontal and vertical-")  (Id ?id1) (taken-by ?ins1))
?sub1 <- (REQUIREMENTS::Measurement (Parameter "1.1.6 aerosol absorption optical depth") (Id ?id2&~?id1) (taken-by ?ins2&~?ins1))
?sub2 <- (SYNERGIES::cross-registered (measurements $?m)) (test (subsetp (create$ ?id1 ?id2) $?m))
=>
(duplicate ?m1 (Parameter "A12.Clouds and aerosols") (taken-by (str-cat ?ins1 "-syn"  ?ins2))(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::clouds-and-aerosols) " D" (call ?m1 getFactId) " S" (call ?sub1 getFactId) " S" (call ?sub2 getFactId) "}")))
)
;; A4.Clouds and radiation
(defrule SYNERGIES::clouds-and-radiation
"identifies synergies between measurements of cloud distribution and spectrally resolved shortwave radiance to produce new measurements, using the logic of cross-registration of measurements"
?m1 <- (REQUIREMENTS::Measurement (Parameter "1.5.3 Cloud amount/distribution -horizontal and vertical-")(Id ?id1) (taken-by ?ins1))
?sub1 <- (REQUIREMENTS::Measurement (Parameter "1.9.3 Spectrally resolved SW radiance -0.3-2um-") (Id ?id2&~?id1) (taken-by ?ins2&~?ins1))
?sub2 <- (SYNERGIES::cross-registered (measurements $?m)) (test (subsetp (create$ ?id1 ?id2) $?m))
=>
(duplicate ?m1 (Parameter "A4.Clouds and radiation") (taken-by (str-cat ?ins1 "-syn"  ?ins2))(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::clouds-and-radiation) " D" (call ?m1 getFactId) " S" (call ?sub1 getFactId) " S" (call ?sub2 getFactId) "}")))
)
;; A11. Tropospheric chemistry, pollution and aerosols
(defrule SYNERGIES::tropospheric-pollution-GHG-and-aerosols
"identifies synergies between tropospheric pollution, greenhouse gases, and aerosols by selecting two measurements of CO and O3 in the lower troposphere, and aerosol absorption optical depth, respectively, and uses the cross-registered measurements to produce a new measurement for tropospheric chemistry, pollution, and aerosols"
?m1 <- (REQUIREMENTS::Measurement (Parameter "1.8.5 CO"|"1.8.26 O3 - lower troposphere")  (Id ?id1) (taken-by ?ins1))
?sub1 <- (REQUIREMENTS::Measurement (Parameter "1.1.6 aerosol absorption optical depth") (Id ?id2&~?id1) (taken-by ?ins2&~?ins1))
?sub2 <- (SYNERGIES::cross-registered (measurements $?m)) (test (subsetp (create$ ?id1 ?id2) $?m))
=>
(duplicate ?m1 (Parameter "A11. Tropospheric chemistry, pollution and aerosols") (taken-by (str-cat ?ins1 "-syn"  ?ins2))(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::tropospheric-pollution-GHG-and-aerosols) " D" (call ?m1 getFactId) " S" (call ?sub1 getFactId) " S" (call ?sub2 getFactId) "}")))
)

(defrule SYNERGIES::carbon-net-ecosystem-exchange 
    "identifies synergies between soil moisture, land surface temperature, landcover classification, and vegetation gross primary productivity to produce carbon net ecosystem exchange data products"
    ?SM <- (REQUIREMENTS::Measurement (Parameter "2.3.2 soil moisture")  (Id ?id1) (taken-by ?ins1))
    ?sub1 <- (REQUIREMENTS::Measurement (Parameter "2.5.1 Surface temperature -land-") (Id ?id2) (taken-by ?ins2))
    ?sub2 <- (REQUIREMENTS::Measurement (Parameter "2.6.2 landcover status")  (Id ?id3) (taken-by ?ins3))
    ?sub3 <- (REQUIREMENTS::Measurement (Parameter "2.4.2 vegetation state") (Id ?id4) (taken-by ?ins4))
    ?sub4 <- (SYNERGIES::cross-registered (measurements $?m)) (test (subsetp (create$ ?id1 ?id2 ?id3 ?id4) $?m))
	=>

    (duplicate ?SM (Parameter "2.4.6 Soil carbon")  
            (Id (str-cat ?id1 "-syn" ?id2 "-syn" ?id3 "-syn" ?id4))
            (taken-by (str-cat ?ins1 "-syn" ?ins2 "-syn-" ?ins3 "-syn-" ?ins4)) (factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::carbon-net-ecosystem-exchange) " D" (call ?SM getFactId) " S" (call ?sub1 getFactId) " S" (call ?sub2 getFactId) " S" (call ?sub3 getFactId) " S" (call ?sub4 getFactId) "}")));; fuzzy-max in accuracy is OK because joint product does provide 4% accuracy
)

(defrule SYNERGIES::snow-cover-3freqs
    "identifies that combining measurements from Infrared (IR), X-band, and L-band frequencies results in a high accuracy snow cover product"
    
    ?IR <- (REQUIREMENTS::Measurement (Parameter "4.2.4 snow cover") (Spectral-region opt-VNIR+TIR)
         (Accuracy Low) (Id ?id1) (taken-by ?ins1))
    
    ?X <- (REQUIREMENTS::Measurement (Parameter "4.2.4 snow cover") (Spectral-region MW-X+Ka+Ku+mm)
         (Accuracy Low) (Id ?id2) (taken-by ?ins2))
    
    ?L <- (REQUIREMENTS::Measurement (Parameter "4.2.4 snow cover") (Spectral-region MW-L)
        (Accuracy Low) (Id ?id3) (taken-by ?ins3))
    
	(SYNERGIES::cross-registered (measurements $?m)) (test (subsetp (create$ ?id1 ?id2 ?id3) $?m))
    =>
    
    (duplicate ?X (Accuracy High) (Id (str-cat ?id1 "-syn-" ?id2 "-syn-" ?id3))
            (taken-by (str-cat ?ins1 "-syn-" ?ins2 "-syn-" ?ins3)) (factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::snow-cover-3freqs) " D" (call ?X getFactId) " S" (call ?IR getFactId) " S" (call ?L getFactId) "}")))
    )

(defrule SYNERGIES::snow-cover-2freqs
    "states that medium accuracy of snow cover product is obtained when infrared (IR) and microwave (MW) measurements are combined"

    
    ?IR <- (REQUIREMENTS::Measurement (Parameter "4.2.4 snow cover") (Spectral-region opt-VNIR+TIR)
         (Accuracy Low) (Id ?id1) (taken-by ?ins1))
    
    ?MW <- (REQUIREMENTS::Measurement (Parameter "4.2.4 snow cover") (Spectral-region ?sr&~nil)
         (Accuracy Low) (Id ?id2) (taken-by ?ins2))

    (test (neq (str-index MW ?sr) FALSE))
	
	(SYNERGIES::cross-registered (measurements $?m)) (test (subsetp (create$ ?id1 ?id2) $?m))
    =>
    ;(printout t "snow cover 2 freqs " crlf)
    (duplicate ?MW (Accuracy Medium) (Id (str-cat ?id1 "-syn-" ?id2 ))
            (taken-by (str-cat ?ins1 "-syn-" ?ins2))(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::snow-cover-2freqs) " D" (call ?MW getFactId) " S" (call ?IR getFactId) "}")))
    )

(defrule SYNERGIES::ice-cover-3freqs
    "states that high accuracy of ice cover product is obtained when IR, X, and L-band measurements are combined"

    
    ?IR <- (REQUIREMENTS::Measurement (Parameter "4.3.2 Sea ice cover") (Spectral-region opt-VNIR+TIR)
         (Accuracy Low) (Id ?id1) (taken-by ?ins1))
    
    ?X <- (REQUIREMENTS::Measurement (Parameter "4.3.2 Sea ice cover") (Spectral-region MW-X+Ka+Ku+mm)
        (Accuracy Low) (Id ?id2) (taken-by ?ins2))
    
    ?L <- (REQUIREMENTS::Measurement (Parameter "4.3.2 Sea ice cover") (Spectral-region MW-L)
         (Accuracy Low) (Id ?id3) (taken-by ?ins3))
    
	(SYNERGIES::cross-registered (measurements $?m)) (test (subsetp (create$ ?id1 ?id2 ?id3) $?m))
    =>
    
    (duplicate ?X (Accuracy High) (Id (str-cat ?id1 "-syn-" ?id2 "-syn-" ?id3))
            (taken-by (str-cat ?ins1 "-syn-" ?ins2 "-syn-" ?ins3))(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::ice-cover-3freqs) " D" (call ?X getFactId) " S" (call ?IR getFactId) " S" (call ?L getFactId) "}")))
    )

(defrule SYNERGIES::ice-cover-2freqs
    "states that medium accuracy is obtained for ice cover measurements when IR and MW measurements are combined"

    
    ?IR <- (REQUIREMENTS::Measurement (Parameter "4.3.2 Sea ice cover") (Spectral-region opt-VNIR+TIR)
        (Accuracy Low) (Id ?id1) (taken-by ?ins1))
    
    ?MW <- (REQUIREMENTS::Measurement (Parameter "4.3.2 Sea ice cover") (Spectral-region ?sr&~nil)
         (Accuracy Low) (Id ?id2) (taken-by ?ins2))

    (test (neq (str-index MW ?sr) FALSE))
	
	(SYNERGIES::cross-registered (measurements $?m)) (test (subsetp (create$ ?id1 ?id2) $?m))
    =>
    
    (duplicate ?MW (Accuracy Medium) (Id (str-cat ?id1 "-syn-" ?id2 ))
            (taken-by (str-cat ?ins1 "-syn-" ?ins2))(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::ice-cover-2freqs) " D" (call ?MW getFactId) " S" (call ?IR getFactId) "}")))
    )

(defrule SYNERGIES::ocean-salinity-space-average
    "states that L-band passive radiometer can yield 0.2psu data if we average in space (from SMAP applications report)"


    ?L <- (REQUIREMENTS::Measurement (Parameter "3.3.1 Ocean salinity") (Accuracy# ?a1&~nil) 
        (Horizontal-Spatial-Resolution# ?hsr1&~nil) (Id ?id1) (taken-by ?ins1&SMAP_MWR))    
    (test (eq (str-index averaged ?ins1) FALSE))
    =>
    (bind ?a2 (/ ?a1 3.0))
    (bind ?hsr2 (* ?hsr1 3.0))
    (duplicate ?L (Accuracy# ?a2) (Horizontal-Spatial-Resolution# ?hsr2) (Id (str-cat ?id1 "-space-averaged")) 
        (taken-by (str-cat ?ins1 "-space-averaged"))(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::spati) " D" (call ?L getFactId) "}")))
    )

(defrule SYNERGIES::ocean-wind-space-average
    "states that L-band passive radiometer can yield 1 m/s wind data if we average in space (from SMAP applications report)"

    ?L <- (REQUIREMENTS::Measurement (Parameter "3.4.1 Ocean surface wind speed") (Accuracy# ?a1&~nil) 
        (Horizontal-Spatial-Resolution# ?hsr1&~nil) (Id ?id1) (taken-by ?ins1&SMAP_MWR))    
    (test (eq (str-index averaged ?ins1) FALSE))
    =>
    (bind ?a2 (/ ?a1 2.0))
    (bind ?hsr2 (* ?hsr1 2.0))
    (duplicate ?L (Accuracy# ?a2) (Horizontal-Spatial-Resolution# ?hsr2) (Id (str-cat ?id1 "-space-averaged")) 
        (taken-by (str-cat ?ins1 "-space-averaged"))(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::ocean-wind-space-average) " D" (call ?L getFactId) "}")))
    )
;; **********************
;; SMAP VALUES BY DEFAULT
;; ***************************

(defrule MANIFEST::put-ADCS-values-by-default
"sets default values for various satellite parameters related to Attitude Determination and Control System (ADCS) of a space mission, including the ADCS requirement, ADCS type, propellant type and injection method, and slew angle."
?miss <- (MANIFEST::Mission  (ADCS-requirement nil) (factHistory ?fh))
=>
(modify ?miss (ADCS-requirement 0.01) (ADCS-type three-axis) (propellant-ADCS hydrazine)
 (propellant-injection hydrazine) (slew-angle 2.0) (factHistory (str-cat "{R" (?*rulesMap* get MANIFEST::put-ADCS-values-by-default) " " ?fh "}"))
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
    "accumulates measurements from cross-registered instruments, explodes them into individual measurements, and asserts a cross-registered fact with the degree of cross-registration being 'spacecraft'"
	(SYNERGIES::cross-registered-instruments (instruments $?ins) (platform ?sat) (factHistory ?fh))
	?c <- (accumulate (bind ?str "")                        ;; initializer
                (bind ?str (str-cat ?str " " $?m1))                    ;; action
                ?str                                        ;; result
                (CAPABILITIES::Manifested-instrument (Name ?ins1&:(contains$ $?ins ?ins1)) (flies-in ?sat) (measurement-ids $?m1) )
				) ;; CE
	=>
	(assert (SYNERGIES::cross-registered (measurements (explode$ ?c)) (degree-of-cross-registration spacecraft) (platform ?sat) (factHistory (str-cat "{R" (?*rulesMap* get CAPABILITIES-CROSS-REGISTER::cross-register-measurements-from-cross-registered-instruments) " " ?fh "}"))))
	;(printout t ?c crlf)
)

