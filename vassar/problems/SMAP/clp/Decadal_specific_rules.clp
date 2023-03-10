
;; ******************
;; SMAP specific rules
;; *******************

(defrule MANIFEST::put-ADCS-values-by-default
"sets default values for various satellite parameters related to Attitude Determination and Control System (ADCS) of a space mission, including the ADCS requirement, ADCS type, propellant type and injection method, and slew angle."
?miss <- (MANIFEST::Mission  (ADCS-requirement nil))
=>
(modify ?miss (ADCS-requirement 0.01) (ADCS-type three-axis) (propellant-ADCS hydrazine)
 (propellant-injection hydrazine) (slew-angle 2.0)
)
)


;(defrule SYNERGIES::SMAP-spatial-disaggregation "A frequent coarse spatial resolution measurement can be combined with a sparse high spatial resolution measurement to produce a frequent high spatial resolution measurement with average accuracy"
;    ?m1 <- (REQUIREMENTS::Measurement (Parameter "2.3.2 soil moisture") (Horizontal-Spatial-Resolution ?hsr1&~nil) (Accuracy ?a1&~nil) (Id ?id1) (taken-by ?ins1))
;    ?m2 <- (REQUIREMENTS::Measurement (Parameter "2.3.2 soil moisture") (Horizontal-Spatial-Resolution ?hsr2&~nil) (Accuracy ?a2&~nil) (Id ?id2) (taken-by ?ins2))
;    (SYNERGIES::cross-registered (measurements $?m))
;    (test (member$ ?id1 $?m))
;    (test (member$ ?id2 $?m))
;    (not (REASONING::stop-improving (Measurement ?p)))
;    (test (eq (str-index disaggregated ?ins1) FALSE))
;    (test (eq (str-index disaggregated ?ins2) FALSE))
;    (test (neq ?id1 ?id2))
;
;	=>
;
 ;   (duplicate ?m1 (Horizontal-Spatial-Resolution (eval (fuzzy-max Horizontal-Spatial-Resolution ?hsr1 ?hsr2))) 
  ;          (Accuracy (eval (fuzzy-max Accuracy ?a1 ?a2))) 
   ;         (Id (str-cat ?id1 "-disaggregated" ?id2))
    ;        (taken-by (str-cat ?ins1 "-" ?ins2 "-disaggregated")));; fuzzy-max in accuracy is OK because joint product does provide 4% accuracy
;)

(defrule SYNERGIES::SMAP-spatial-disaggregation 
    "identifies that a frequent coarse spatial resolution measurement combined with a sparse high spatial resolution measurement can produce a frequent high spatial resolution measurement with average accuracy"
    ?m1 <- (REQUIREMENTS::Measurement (Parameter "2.3.2 soil moisture") (Illumination Active) 
        (Horizontal-Spatial-Resolution# ?hs1) (Accuracy# ?a1)  (Id ?id1) (taken-by ?ins1))
    ?m2 <- (REQUIREMENTS::Measurement (Parameter "2.3.2 soil moisture") (Illumination Passive) 
        (Horizontal-Spatial-Resolution# ?hs2) (Accuracy# ?a2) (Id ?id2) (taken-by ?ins2))
    (SYNERGIES::cross-registered (measurements $?m))
    (test (member$ ?id1 $?m))
    (test (member$ ?id2 $?m))
	=>
	;(printout t hola crlf)
    (duplicate ?m1 (Horizontal-Spatial-Resolution# (sqrt (* ?hs1 ?hs2))) (Accuracy# ?a2)
            (Id (str-cat ?id1 "-disaggregated" ?id2))
            (taken-by (str-cat ?ins1 "-" ?ins2 "-disaggregated")));; fuzzy-max in accuracy is OK because joint product does provide 4% accuracy
)



(defrule SYNERGIES::carbon-net-ecosystem-exchange 
    "states measurements of soil moisture, surface temperature, land cover, and vegetation state can be combined to produce a new measurement of carbon net ecosystem exchange (NEE)"
    ?SM <- (REQUIREMENTS::Measurement (Parameter "2.3.2 soil moisture") (Horizontal-Spatial-Resolution ?hsr1&~nil) (Accuracy ?a1&~nil) (Id ?id1) (taken-by ?ins1))
    ?LST <- (REQUIREMENTS::Measurement (Parameter "2.5.1 Surface temperature -land-") (Horizontal-Spatial-Resolution ?hsr2&~nil) (Accuracy ?a2&~nil) (Id ?id2) (taken-by ?ins2))
    ?LC <- (REQUIREMENTS::Measurement (Parameter "2.6.2 landcover status") (Horizontal-Spatial-Resolution ?hsr3&~nil) (Accuracy ?a3&~nil) (Id ?id3) (taken-by ?ins3))
    ?VEG <- (REQUIREMENTS::Measurement (Parameter "2.4.2 vegetation state") (Horizontal-Spatial-Resolution ?hsr4&~nil) (Accuracy ?a4&~nil) (Id ?id4) (taken-by ?ins4))
    (SYNERGIES::cross-registered (measurements $?m)) (test (subsetp (create$ ?id1 ?id2 ?id3 ?id4) $?m))
    (not (REQUIREMENTS::Measurement (Parameter "2.3.3 Carbon net ecosystem exchange NEE")))
	=>

    (assert (REQUIREMENTS::Measurement (Parameter "2.3.3 Carbon net ecosystem exchange NEE") (Horizontal-Spatial-Resolution (eval (fuzzy-max Horizontal-Spatial-Resolution ?hsr1 ?hsr2))) 
            (Accuracy (eval (fuzzy-max Accuracy ?a1 ?a2))) 
            (Id (str-cat ?id1 "-disaggregated" ?id2))
            (taken-by (str-cat ?ins1 "-" ?ins2 "-disaggregated"))));; fuzzy-max in accuracy is OK because joint product does provide 4% accuracy
)
   

(defrule MANIFEST::SMAP-add-common-dish-to-MWR
    "adds the share dish instrument (SMAP_ANT) to the list of instruments if the SMAP radiometer (SMAP_MWR) is manifested"
    ?miss <- (MANIFEST::Mission (instruments $?list-of-instruments))
    (test (eq (subsetp (create$ SMAP_ANT) ?list-of-instruments) FALSE))
    (test (eq (subsetp (create$ SMAP_MWR) ?list-of-instruments) TRUE))
       =>
    (bind ?new-list (insert$ ?list-of-instruments (+ 1 (length$ ?list-of-instruments)) SMAP_ANT))
    ;(printout t "contains SMAP_ANT = " (eq (subsetp (create$ SMAP_ANT) ?list-of-instruments) FALSE) " new list = " ?new-list crlf)
    (modify ?miss (instruments ?new-list))
    
    ) 

(defrule MANIFEST::SMAP-add-common-dish-to-RAD
    "adds the share dish instrument (SMAP_ANT) to the list of instruments if the SMAP radar (SMAP_RAD) is manifested"
    ?miss <- (MANIFEST::Mission (instruments $?list-of-instruments))
    (test (eq (subsetp (create$ SMAP_ANT) ?list-of-instruments) FALSE))
    (test (eq (subsetp (create$ SMAP_RAD) ?list-of-instruments) TRUE))
       =>
    (bind ?new-list (insert$ ?list-of-instruments (+ 1 (length$ ?list-of-instruments)) SMAP_ANT))
    ;(printout t "contains SMAP_ANT = " (eq (subsetp (create$ SMAP_ANT) ?list-of-instruments) FALSE) " new list = " ?new-list crlf)
    (modify ?miss (instruments ?new-list))
    
    ) 

(defrule MANIFEST::compute-MWR-spatial-resolution
    "calculates the horizontal spatial resolution, swath, field-of-view and along/cross track resolution for an earth observing space mission's SMAP_MWR instrument based on the frequency, orbit altitude, off-axis angle and scanning angle, using the equations:
$$\frac{\lambda}{D} = \frac{c}{Df}$$
$$\theta_1 = \theta - \frac{\lambda}{2D}$$
$$\theta_2 = \theta + \frac{\lambda}{2D}$$
$$x_1 = 1000h \tan(\theta_1)$$
$$x_2 = 1000h \tan(\theta_2)$$
$$along = x_2 - x_1$$
$$cross = 2\left(\frac{h}{\cos(\theta)}\tan\left(\frac{\lambda}{2D}\right)\right)$$
$$sw = 2\left(\frac{h}{\cos(\theta)}\tan\left(\frac{\alpha}{2}\right)\right)$$"
    ?MWR <- (CAPABILITIES::Manifested-instrument  (Name SMAP_MWR) (Intent "Imaging multi-spectral radiometers -passive MW-")
         (frequency# ?f&~nil) (orbit-altitude# ?h&~nil) (Horizontal-Spatial-Resolution# nil) (off-axis-angle-plus-minus# ?theta) (scanning-angle-plus-minus# ?alfa) (flies-in ?sat))
    (CAPABILITIES::Manifested-instrument  (Name SMAP_ANT) (dimension-x# ?D) (flies-in ?sat))
    =>
    (bind ?dtheta (/ 3e8 (* ?D ?f))); lambda/D
    (bind ?theta1 (- (torad ?theta) (/ ?dtheta 2)))
    (bind ?theta2 (+ (torad ?theta) (/ ?dtheta 2)))
    (bind ?x1 (* (* 1000 ?h) (tan ?theta1)))
    (bind ?x2 (* (* 1000 ?h) (tan ?theta2)))
    (bind ?along (- ?x2 ?x1))
    (bind ?cross (* 2 (* (/ ?h (cos (torad ?theta))) (tan (/ ?dtheta 2)))))
    (bind ?sw (* 2 (* (/ ?h (cos (torad ?theta))) (tan (/ ?alfa 2)))))
    (modify ?MWR (Horizontal-Spatial-Resolution# ?along) (Horizontal-Spatial-Resolution-Along-track# ?along) 
        (Horizontal-Spatial-Resolution-Cross-track# ?cross) (Swath# ?sw) (Field-of-view# ?alfa))
    )

(defrule MANIFEST::compute-RAD-spatial-resolution
    "calculates the horizontal spatial resolution of a radar instrument using the bandwidth, off-axis angle, number of looks, frequency, and orbit altitude, as well as the dimensions of the SMAP_ANT instrument. Equations: Range resolution: $range\text{-}res = \frac{3\times10^8}{2B\sin(\theta)}$, Swath width: $sw = 2\cdot\frac{h}{\cos(\theta)}\tan\left(\frac{\alpha}{2}\right)$, Along-track spatial resolution: $h_spatial_res_alongtrack = \frac{range\text{-}res}{\sin(\theta)}$, Cross-track spatial resolution: $h_spatial_res_crosstrack = range\text{-}res$, Field of view: $fov = \alpha$"
    ?RAD <- (CAPABILITIES::Manifested-instrument  (Name SMAP_RAD) (bandwidth# ?B) (off-axis-angle-plus-minus# ?theta) (number-of-looks# ?nl&~nil)  (scanning-angle-plus-minus# ?alfa)
         (frequency# ?f&~nil) (orbit-altitude# ?h&~nil) (Horizontal-Spatial-Resolution# nil) (off-axis-angle-plus-minus# ?theta) (flies-in ?sat))
    (CAPABILITIES::Manifested-instrument  (Name SMAP_ANT) (dimension-x# ?D) (flies-in ?sat))
    =>
    ;(printout t "b = " ?B " theta = " ?theta crlf)
    (bind ?range-res (/ 3e8 (* 2 ?B (sin (torad ?theta)))))
    (bind ?sw (* 2 (* (/ ?h (cos (torad ?theta))) (tan (/ ?alfa 2)))))
    (modify ?RAD (Horizontal-Spatial-Resolution# (* ?nl ?range-res)) (Horizontal-Spatial-Resolution-Along-track# (/ ?range-res (sin (torad ?theta)))) 
        (Horizontal-Spatial-Resolution-Cross-track# ?range-res) (Swath# ?sw) (Field-of-view# ?alfa))
    )

;; number of looks hsr ==> hsr*sqrt(#looks) in each direction to increase relative error
 
;; **********************
;; DESDYNI
;; **********************

(defrule MANIFEST::compute-SAR-spatial-resolution
    "calculates the horizontal spatial resolution and swath of a radar instrument based on its bandwidth, off-axis angle, number of looks, scanning angle, frequency, orbit altitude, and other parameters. Equations: $$range\text{-}res = \frac{3 \times 10^8}{2 \times B \times sin(\theta)}$$ $$swath = 2 \times \frac{h}{cos(\theta)} \times tan(\frac{\alpha}{2})$$"
    ?RAD <- (CAPABILITIES::Manifested-instrument  (Name DESD_SAR) (bandwidth# ?B) (dimension-x# ?D)  (off-axis-angle-plus-minus# ?theta) (number-of-looks# ?nl&~nil)  (scanning-angle-plus-minus# ?alfa)
         (frequency# ?f&~nil) (orbit-altitude# ?h&~nil) (Horizontal-Spatial-Resolution# nil) (off-axis-angle-plus-minus# ?theta) (flies-in ?sat))
    =>
    ;(printout t "b = " ?B " theta = " ?theta crlf)
    (bind ?range-res (/ 3e8 (* 2 ?B (sin (torad ?theta)))))
    (bind ?sw (* 2 (* (/ ?h (cos (torad ?theta))) (tan (/ ?alfa 2)))))
    (modify ?RAD (Horizontal-Spatial-Resolution# (* ?nl ?range-res)) (Horizontal-Spatial-Resolution-Along-track# (/ ?range-res (sin (torad ?theta)))) 
        (Horizontal-Spatial-Resolution-Cross-track# ?range-res) (Swath# ?sw) (Field-of-view# ?alfa))
    )

 
;; **********************
;; HYSPIRI
;; **********************
(defrule MANIFEST::compute-HYSP-TIR-spatial-resolution 
    "calculates the field of view in degrees and the spatial resolution in meters per pixel of a square image for the HYSP_TIR instrument on an Earth observing spacecraft, using the instrument's angular resolutions, orbit altitude, number of pixels along and across the track, and scanning angle. Equations used: $fov = alfa$, $hsra = 1000htorad(ifova)$, $hsrc = 1000htorad(ifovc)$, $hsr = hsrc$, and $sw = (hsr*npixc)/1000$"
    (declare (salience 5))
    ?instr <- (CAPABILITIES::Manifested-instrument (Name HYSP_TIR) (Field-of-view# nil) 
        (Angular-resolution-azimuth# ?ifovc&~nil) (Angular-resolution-elevation# ?ifova&~nil) (orbit-altitude# ?h&~nil) 
        (num-pixels-along-track# ?npixa&~nil) (num-pixels-cross-track# ?npixc&~nil) 
        (scanning-angle-plus-minus# ?alfa)) 
    =>
	(bind ?fov ?alfa);for orbit calculations
    (bind ?hsra (* 1000 ?h (torad ?ifova))) (bind ?hsrc (* 1000 ?h (torad ?ifovc)))
    (bind ?hsr ?hsrc)
    (bind ?sw (/ (* ?hsr ?npixc) 1000)) 
    (modify ?instr (Field-of-view# ?fov) (Swath# ?sw) 
        (Horizontal-Spatial-Resolution# ?hsra) (Horizontal-Spatial-Resolution# ?hsrc)
        (Horizontal-Spatial-Resolution# ?hsr))
    ;(printout t "HYSP TIR compute hsr ang = " ?ifova " hsra = " ?hsra " hsrc = " ?hsrc " h = " ?h crlf)
    )

(defrule MANIFEST::compute-HYSP-VIS-spatial-resolution 
    "calculates the field of view and spatial resolution for the HYSP_VIS instrument based on its angular resolution, number of pixels, scanning angle, and orbit altitude. Equations: $fov = 5$, $hsra = 1000 * h * \tan(ifova)$, $hsrc = 1000 * h * \tan(ifovc)$, $hsr = hsrc$, and $sw = (hsr * npixc) / 1000$"
    (declare (salience 5))
    ?instr <- (CAPABILITIES::Manifested-instrument (Name HYSP_VIS) (Field-of-view# nil) 
        (Angular-resolution-azimuth# ?ifovc&~nil) (Angular-resolution-elevation# ?ifova&~nil) (orbit-altitude# ?h&~nil) 
        (num-pixels-along-track# ?npixa&~nil) (num-pixels-cross-track# ?npixc&~nil) 
        (scanning-angle-plus-minus# ?alfa)) 
    =>
	(bind ?fov 5);for orbit calculations
    (bind ?hsra (* 1000 ?h (torad ?ifova))) (bind ?hsrc (* 1000 ?h (torad ?ifovc)))
    (bind ?hsr ?hsrc)
    (bind ?sw (/ (* ?hsr ?npixc) 1000)) 
    (modify ?instr (Field-of-view# ?fov) (Swath# ?sw) 
        (Horizontal-Spatial-Resolution# ?hsra) (Horizontal-Spatial-Resolution# ?hsrc)
        (Horizontal-Spatial-Resolution# ?hsr))
    ;(printout t "HYSP VIS compute hsr ang = " ?ifova " hsra = " ?hsra " hsrc = " ?hsrc " h = " ?h crlf)
    )
;; *********************
;; LIDARS
;; **********************
(defrule CAPABILITIES::ice-lidar-sensitivity-through-optically-thin-clouds
        "modifies the sensitivity-in-cirrus parameter of an instrument to 'High' if the spectral bands include opt-NIR-1064nm or opt-nir-532nm, and the field of view is less than 400 urad"
        ?i <- (CAPABILITIES::Manifested-instrument (sensitivity-in-cirrus nil) (spectral-bands $?sb) (Field-of-view# ?fov&~nil))
        (or 
            (and (test (subsetp (create$ opt-NIR-1064nm) $?sb)) (test (< ?fov 400)))
            (test (subsetp (create$ opt-nir-532nm) $?sb))
            );; less than 400 urad)
        =>
        (modify ?i (sensitivity-in-cirrus High))
        
        )
