;; **********************
;; SMAP EXAMPLE ENUMERATION RULES
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
    (printout t "get-instruments" ?res crlf)
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

(defrule MANIFEST0::SMAP-add-common-dish-to-MWR
    "manifests the SMAP share dish for the radiometer (SMAP_MWR)"
    (declare (salience 100))
    ?miss <- (MANIFEST::Mission (instruments $?list-of-instruments))
    (test (eq (contains$ ?list-of-instruments SMAP_ANT) FALSE))
    (test (eq (contains$ ?list-of-instruments SMAP_MWR) TRUE))

       =>
    ;(bind ?new-list (add-element$ ?list-of-instruments SMAP_ANT))
    ;printout t "contains SMAP_ANT = " (eq (subsetp (create$ SMAP_ANT) ?list-of-instruments) FALSE) " new list = " ?new-list crlf)
    (modify ?miss (instruments (add-element$ ?list-of-instruments SMAP_ANT)))
    )

(defrule MANIFEST0::SMAP-add-common-dish-to-RAD
    "manifests the SMAP share dish for the SMAP radar (SMAP_RAD)"
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






(deffunction compute-swath-conical-MWR (?h ?half-scan ?off-nadir)
    (return (* 2 (/ ?h (cos ?off-nadir)) (tan ?half-scan)))
    )



; -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;(defrule MANIFEST::compute-spatial-resolution-and-swath-nadir-looking-no-scanning-imagers
;    ?MWR <- (CAPABILITIES::Manifested-instrument
;                (Geometry nadir)
;                (scanning no-scanning)
;                (Intent "Imaging multi-spectral radiometers -passive MW-"|"Imaging multi-spectral radiometers -passive optical-"|"High resolution optical imagers")
;                (Angular-resolution# ?dtheta&~nil)
;                (orbit-altitude# ?h&~nil)
;                (Field-of-view# ?fov&~nil)
;                (Horizontal-Spatial-Resolution# nil)
;                (flies-in ?sat)(factHistory ?fh)
;    )
;    =>
;    (bind ?dx (* 2 (* 1000 ?h) (tan (/ ?dtheta 2))))
;    (bind ?sw (* 2 (* 1000 ?h) (tan (/ ?fov 2))))
;    (modify ?MWR
;        (Horizontal-Spatial-Resolution# ?dx)
;        (Swath# ?sw)
;        (factHistory (str-cat "{R" (?*rulesMap* get MANIFEST::compute-spatial-resolution-and-swath-nadir-looking-no-scanning-imagers) " " ?fh "}"))
;    )
;    )



(defrule MANIFEST::compute-VIIRS-spatial-resolution
    "calculates the horizontal spatial resolution of a manifested instrument called VIIRS for an earth observing space mission design using the equations: $ \lambda = \frac{3 \times 10^8}{f} $, $ x = \frac{1.22 \times 1000h\lambda}{a} $, where $f$, $h$, and $a$ are frequency, orbit altitude, and aperture respectively"
    ?VIIRS <- (CAPABILITIES::Manifested-instrument
                (Name VIIRS)
                (frequency# ?f&~nil)
                (orbit-altitude# ?h&~nil)
                (Aperture# ?a&~nil)
                (Horizontal-Spatial-Resolution# nil)
    )
    =>
    (printout t "ben gorr spatial calc:" crlf)
    (bind ?lambda (/ 3e8 ?f))
    (bind ?x (/ (* 1.22 (* (* 1000 ?h) ?lambda)) ?a))
    (bind ?along ?x)
    (bind ?cross ?x)
    (printout t "?x = " ?x crlf)
    (modify ?VIIRS
        (Horizontal-Spatial-Resolution# ?along)
        (Horizontal-Spatial-Resolution-Along-track# ?along)
        (Horizontal-Spatial-Resolution-Cross-track# ?cross)
    )
    )


(defrule CAPABILITIES::compute-image-distortion-in-nadir-looking-instruments
    "modifies the image distortion parameter of a manifested instrument with a nadir geometry to 0"
    ?instr <- (CAPABILITIES::Manifested-instrument
                    (orbit-altitude# ?h&~nil)
                    (Geometry nadir)
                    (characteristic-orbit ?href&~nil)
                    (image-distortion# nil)
    )
    =>
    (modify ?instr
        (image-distortion# 0)
    )
    )





(defrule MANIFEST::compute-CMIS-spatial-resolution
    "calculates the horizontal spatial resolution and swath of the CMIS instrument using its frequency, orbit altitude, dimension, off-axis and scanning angles. Equations: $d\theta = \frac{\lambda}{Df}$, $\theta_1 = \theta - \frac{d\theta}{2}$, $\theta_2 = \theta + \frac{d\theta}{2}$, $x_1 = 1000h\tan{\theta_1}$, $x_2 = 1000h\tan{\theta_2}$, $along = x_2 - x_1$, $cross = 2\cdot\frac{h}{\cos{\theta}}\tan{\frac{d\theta}{2}}$, $sw = 2\cdot\frac{h}{\cos{\theta}}\tan{\frac{\alpha}{2}}$ (where $d\theta$ is the angular resolution, $\theta$ is the off-axis angle, $x_1$ and $x_2$ are the cross-track distances, $along$ is the along-track distance, $cross$ is the cross-track spatial resolution, $sw$ is the swath, $h$ is the orbit altitude, $D$ is the dimension, $f$ is the frequency, and $\alpha$ is the scanning angle)"
    ?MWR <- (CAPABILITIES::Manifested-instrument
                (Name CMIS)
                (frequency# ?f&~nil)
                (orbit-altitude# ?h&~nil)
                (dimension-x# ?D&~nil)
                (Horizontal-Spatial-Resolution# nil)
                (off-axis-angle-plus-minus# ?theta&~nil)
                (scanning-angle-plus-minus# ?alfa&~nil)
                (flies-in ?sat)
    )
    =>
    (bind ?dtheta (to-deg (/ 3e8 (* ?D ?f)))); lambda/D
    (bind ?theta1 (- ?theta (/ ?dtheta 2)))
    (bind ?theta2 (+ ?theta (/ ?dtheta 2)))
    (bind ?x1 (* (* 1000 ?h) (tan ?theta1)))
    (bind ?x2 (* (* 1000 ?h) (tan ?theta2)))
    (bind ?along (- ?x2 ?x1))
    (bind ?cross (* 2 (* (/ ?h (cos  ?theta)) (tan (/ ?dtheta 2)))))
    (bind ?sw (compute-swath-conical-MWR ?h ?alfa ?theta))
    (modify ?MWR
        (Angular-resolution-elevation# ?dtheta)
        (Horizontal-Spatial-Resolution# ?along)
        (Horizontal-Spatial-Resolution-Along-track# ?along)
        (Horizontal-Spatial-Resolution-Cross-track# ?cross)
        (Swath# ?sw)
        (Field-of-view# ?alfa)
    )
    )


(defrule MANIFEST::compute-SMAP-MWR-spatial-resolution
    "calculates the horizontal spatial resolution, angular resolution, swath width, and field of view for the SMAP_MWR instrument, based on its frequency, orbit altitude, and off-axis scanning angle, using the equation for conical swath width. Equations: $\theta_1=\theta-\frac{\lambda}{D}$, $\theta_2=\theta+\frac{\lambda}{D}$, $\Delta\text{Along-Track}=\text{ }(\text{1000}\cdot h)\cdot\tan(\theta_2)-(\text{1000}\cdot h)\cdot\tan(\theta_1)$, $\Delta\text{Cross-Track}=2\cdot\frac{h}{\cos(\theta)}\cdot\tan\bigg(\frac{\lambda}{2}\bigg)$, and $\text{Swath}=2\cdot\frac{h}{\cos(\theta)}\cdot\tan\bigg(\frac{\alpha}{2}\bigg)$, where $\theta$ is the off-axis scanning angle, $\lambda$ is the wavelength of the signal, $D$ is the diameter of the antenna, $h$ is the orbit altitude, $\alpha$ is the scanning angle, and $\text{Swath}$ is the swath width"
    ?MWR <- (CAPABILITIES::Manifested-instrument
                (Name SMAP_MWR)
                (frequency# ?f&~nil)
                (orbit-altitude# ?h&~nil)
                (Horizontal-Spatial-Resolution# nil)
                (off-axis-angle-plus-minus# ?theta&~nil)
                (scanning-angle-plus-minus# ?alfa&~nil)
                (flies-in ?sat)
    )
    (CAPABILITIES::Manifested-instrument
                (Name SMAP_ANT)
                (dimension-x# ?D&~nil)
                (flies-in ?sat)
    )
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
    (modify ?MWR
        (Angular-resolution-elevation# ?dtheta)
        (Horizontal-Spatial-Resolution# ?along)
        (Horizontal-Spatial-Resolution-Along-track# ?along)
        (Horizontal-Spatial-Resolution-Cross-track# ?cross)
        (Swath# ?sw)
        (Field-of-view# ?alfa)
    )
    )




(defrule MANIFEST::compute-SMAP-RAD-spatial-resolution
    "calculates the angular resolution and horizontal spatial resolution of the SMAP-RAD instrument, given its bandwidth, off-axis angle, number of looks, scanning angle, frequency, orbit altitude, and the dimension of the SMAP-ANT instrument it flies with. Equations used include $\lambda/D$ to calculate $\Delta \theta$, $2h \tan((\alpha + \theta)/2)$ to calculate swath width, $c/(2B\sin(\theta))$ to calculate range resolution, $n_l \times (c/(2B\sin(\theta)))$ to calculate the horizontal spatial resolution, $c/(2B)$ to calculate the horizontal spatial resolution cross-track, and $(c/(2B\sin(\theta)))$ to calculate the horizontal spatial resolution along-track"
    ?RAD <- (CAPABILITIES::Manifested-instrument
                (Name SMAP_RAD)
                (bandwidth# ?B&~nil)
                (off-axis-angle-plus-minus# ?theta&~nil)
                (number-of-looks# ?nl&~nil)
                (scanning-angle-plus-minus# ?alfa&~nil)
                (frequency# ?f&~nil)
                (orbit-altitude# ?h&~nil)
                (Horizontal-Spatial-Resolution# nil)
                (off-axis-angle-plus-minus# ?theta&~nil)
                (flies-in ?sat)
    )
    (CAPABILITIES::Manifested-instrument
                (Name SMAP_ANT)
                (dimension-x# ?D&~nil)
                (flies-in ?sat)
    )
    =>
    ;(printout t "b = " ?B " theta = " ?theta crlf)
    (bind ?dtheta (to-deg (/ 3e8 (* ?D ?f)))); lambda/D
    (bind ?range-res (/ 3e8 (* 2 ?B (sin ?theta))))
    (bind ?sw (* 2 ?h (tan (/ (+ ?alfa ?theta) 2))))
    (modify ?RAD
        (Angular-resolution-elevation# ?dtheta)
        (Horizontal-Spatial-Resolution# (* ?nl ?range-res))
        (Horizontal-Spatial-Resolution-Along-track# (/ ?range-res (sin ?theta)))
        (Horizontal-Spatial-Resolution-Cross-track# ?range-res)
        (Swath# ?sw)
        (Field-of-view# ?alfa)
    )
    )



(defrule MANIFEST::compute-BIOMASS-spatial-resolution
    "calculates the angular resolution in elevation, horizontal spatial resolution, swath, and field of view for the BIOMASS instrument using the equations: $\theta_{d} = \frac{\lambda}{Df}$, $R_{range} = \frac{3e8}{2Bsin(\theta)}$, $R_{along-track} = \frac{R_{range}}{sin(\theta)}$, and $swath = 2\frac{h}{cos(\theta)}tan(\frac{\alpha}{2})$. Here, $\lambda$ is the wavelength of the electromagnetic signal, $D$ is the aperture diameter of the instrument, $f$ is the frequency of the signal, $B$ is the bandwidth of the instrument, $\theta$ is the off-axis angle, $h$ is the orbit altitude of the instrument, $\alpha$ is the scanning angle, and $n_{l}$ is the number of looks"
    ?RAD <- (CAPABILITIES::Manifested-instrument
                (Name BIOMASS)
                (dimension-x# ?D&~nil)
                (bandwidth# ?B&~nil)
                (off-axis-angle-plus-minus# ?theta&~nil)
                (number-of-looks# ?nl&~nil)
                (scanning-angle-plus-minus# ?alfa&~nil)
                (frequency# ?f&~nil)
                (orbit-altitude# ?h&~nil)
                (Horizontal-Spatial-Resolution# nil)
                (off-axis-angle-plus-minus# ?theta&~nil)
                (flies-in ?sat)
    )
    =>
    ;(printout t "b = " ?B " theta = " ?theta crlf)
    (bind ?dtheta (to-deg (/ 3e8 (* ?D ?f)))); lambda/D
    (bind ?range-res (/ 3e8 (* 2 ?B (sin ?theta))))
    (bind ?sw (compute-swath-conical-MWR ?h ?alfa ?theta))
    (modify ?RAD
        (Angular-resolution-elevation# ?dtheta)
        (Horizontal-Spatial-Resolution# (* ?nl ?range-res))
        (Horizontal-Spatial-Resolution-Along-track# (/ ?range-res (sin ?theta)))
        (Horizontal-Spatial-Resolution-Cross-track# ?range-res)
        (Swath# ?sw)
        (Field-of-view# ?alfa))
    )
; -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------












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
    "calculates the image distortion for side-looking instruments using the equation: $\text{image-distortion#} = \frac{\text{orbit-altitude#}}{\text{characteristic-orbit}}$"
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
    "calculates the soil penetration capability of an instrument based on its operating frequency using a predefined function that maps frequency to penetration depth. Equations: $\lambda = \frac{3e10}{f}$ where $\lambda$ is the wavelength in centimeters and $f$ is the operating frequency in Hertz, and a set of conditional statements mapping $\lambda$ to soil penetration depth"
    ?instr <- (CAPABILITIES::Manifested-instrument (frequency# ?f&~nil)
        (soil-penetration# nil))
    =>
    (modify ?instr (soil-penetration# (get-soil-penetration ?f)))
    )
;; **********************
;; SMAP EXAMPLE EMERGENCE RULES
;; ***************************


(defrule SYNERGIES::SMAP-spatial-disaggregation
    "identifies that a frequent coarse spatial resolution measurement combined with a sparse high spatial resolution measurement can produce a frequent high spatial resolution measurement with average accuracy"
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
    "states measurements of soil moisture, surface temperature, land cover, and vegetation state can be combined to produce a new measurement of carbon net ecosystem exchange (NEE)"
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
            (taken-by (str-cat ?ins1 "-syn-" ?ins2 "-syn-" ?ins3)))
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
            (taken-by (str-cat ?ins1 "-syn-" ?ins2)))
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
            (taken-by (str-cat ?ins1 "-syn-" ?ins2 "-syn-" ?ins3)))
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
            (taken-by (str-cat ?ins1 "-syn-" ?ins2)))
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
        (taken-by (str-cat ?ins1 "-space-averaged")))
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
        (taken-by (str-cat ?ins1 "-space-averaged")))
    )
;; **********************
;; SMAP VALUES BY DEFAULT
;; ***************************

(defrule MANIFEST::put-ADCS-values-by-default
"sets default values for certain satellite parameters, such as the ADCS requirement, type, propellant, and slew angle"
?miss <- (MANIFEST::Mission  (ADCS-requirement nil))
=>
(modify ?miss (ADCS-requirement 0.01) (ADCS-type three-axis) (propellant-ADCS hydrazine)
 (propellant-injection hydrazine) (slew-angle 2.0)
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
	(SYNERGIES::cross-registered-instruments (instruments $?ins))
	?c <- (accumulate (bind ?str "")                        ;; initializer
                (bind ?str (str-cat ?str " " $?m1))         ;; action
                ?str                                        ;; result
                (CAPABILITIES::Manifested-instrument (Name ?ins1&:(contains$ $?ins ?ins1)) (measurement-ids $?m1))
				) ;; CE
	=>
	(assert (SYNERGIES::cross-registered (measurements (explode$ ?c)) (degree-of-cross-registration spacecraft)))
	;(printout t ?c crlf)
)



