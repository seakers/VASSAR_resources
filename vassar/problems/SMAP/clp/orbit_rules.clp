;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  	   orbit rules
;;           7 rules
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defrule MANIFEST::calculate-orbit-semimajor-axis-sat
	"calculates the semimajor axis of a satellite's orbit based on its altitude using the equation: $a = r_{earth} + h$, where $r_{earth}$ is the radius of the Earth and $h$ is the altitude of the satellite"
    (declare (salience 20))
    ?f <- (MANIFEST::Mission (orbit-altitude# ?orb-alt&~nil)
        						   (orbit-semimajor-axis nil) (factHistory ?fh))
    =>
    (bind ?orb-sa (+ 6378 ?orb-alt))
    (modify ?f (orbit-semimajor-axis (* 1000 ?orb-sa)) (factHistory (str-cat "{R" (?*rulesMap* get MANIFEST::calculate-orbit-semimajor-axis-sat) " " ?fh "}")))
)

(defrule MANIFEST::calculate-orbit-period
	"calculates the orbital period of a constellation based on its semimajor axis using the equation: $T=2\pi\sqrt{\frac{a^3}{\mu}}$, where $T$ is the orbital period, $a$ is the semimajor axis, and $\mu$ is the gravitational parameter of the Earth"
    (declare (salience 20))
    ?f <- (MANIFEST::Mission (orbit-semimajor-axis ?a&~nil)
        						   (orbit-period# nil) (factHistory ?fh))
    =>
    (modify ?f (orbit-period# (orbit-period ?a))(factHistory (str-cat "{R" (?*rulesMap* get MANIFEST::calculate-orbit-period) " " ?fh "}")))
)


(defrule MANIFEST::estimate-sun-angle
    (declare (salience 20))
    ?sat <- (MANIFEST::Mission (worst-sun-angle nil) (factHistory ?fh) )
    =>
    (modify ?sat (worst-sun-angle 0.0) (factHistory (str-cat "{R" (?*rulesMap* get MANIFEST::estimate-sun-angle) " " ?fh "}")))
    )

(defrule MANIFEST::estimate-fraction-of-sunlight
    "calculates the estimated fraction of sunlight for an Earth observing space mission in a circular orbit using the Earth-subtend-angle function and equation $\phi = 2\cdot\arccos\left(\frac{\cos(\rho)}{\cos(B_s)}\right)$, where $\rho$ is the angle subtended by the Earth and $B_s$ is the spacecraft's solar beta angle"
    (declare (salience 20))
    ?sat <- (MANIFEST::Mission (orbit-semimajor-axis ?a&~nil) (fraction-sunlight nil) (factHistory ?fh))
    =>
    (modify ?sat (fraction-sunlight (estimate-fraction-sunlight ?a))(factHistory (str-cat "{R" (?*rulesMap* get MANIFEST::estimate-fraction-of-sunlight) " " ?fh "}")))
    )

;;;; SUPPORTING QUERIES AND FUNCTIONS


(deffunction orbit-velocity (?r ?a)
    (return (sqrt (* 3.986e14 (- (/ 2 ?r) (/ 1 ?a)))))
    )

(deffunction orbit-period (?a)
    (return (* 2 (pi) (sqrt (/ (** ?a 3) 3.986e14))))
    )

(deffunction r-to-h (?r)
    (return (- ?r 6378000))
    )

(deffunction h-to-r (?h)
    (return (+ ?r 6378000))
    )

(deffunction to-km (?m)
    (return (/ ?m 1000))
    )

(deffunction Earth-subtend-angle (?r)
    "This function returns the angle in degrees subtended by the Earth from 
    the orbit"
    (return (asin (/ 6378000 ?r)))
    )

(deffunction atmospheric-density (?h)
    "Calculates rho in kg/m^3 as a function of h in m"
    (return (* 1e-5 (exp (/ (- (/ ?h 1000) 85) -33.387))))
    )
(deffunction estimate-fraction-sunlight (?a)
    "Estimate fraction of sunlight based on circular orbit"
	(if (< ?a 7000000) then 
		(bind ?rho (Earth-subtend-angle ?a))
		(bind ?Bs 25)
		(bind ?phi (* 2 (acos (/ (cos ?rho) (cos ?Bs)))))
		(return (- 1 (/ ?phi 360)))
	else (return 0.99))
    )


	
(deffunction get-orbit-altitude (?orbit-str)
	(bind ?orb (new seakers.vassar.Orbit ?orbit-str))
	(return (?orb getAltitude))
    )
