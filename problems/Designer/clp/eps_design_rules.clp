;(require* modules "C:\\Users\\dani\\Documents\\My Dropbox\\Marc - Dani\\SCAN\\clp\\modules.clp")
;(require* templates "C:\\Users\\dani\\Documents\\My Dropbox\\Marc - Dani\\SCAN\\clp\\templates.clp")
;(require* more-templates "C:\\Users\\dani\\Documents\\My Dropbox\\Marc - Dani\\SCAN\\clp\\more_templates.clp")
;(require* functions "C:\\Users\\dani\\Documents\\My Dropbox\\Marc - Dani\\SCAN\\clp\\functions.clp")


; ******************************************
;      ELECTRICAL POWER SUBSYSTEM DESIGN
;                  (2 rules)
; ******************************************

(defrule MANIFEST::catalog-data
    ?miss <- (MANIFEST::Mission (SA-component nil) (battery-component nil) (SA-orientation nil) (num-battery nil) (solar-array-area nil) (factHistory ?fh))
    =>
    (bind ?list (MatlabFunctions catalogEps 1))
    (bind ?array (nth$ 1 ?list)) (bind ?batt (nth$ 2 ?list)) (bind ?orient (nth$ 3 ?list))
    (bind ?num (nth$ 4 ?list)) (bind ?area (nth$ 5 ?list))
    (modify ?miss (SA-component ?array) (battery-component ?batt) (SA-orientation ?orient) (num-battery ?num) (solar-array-area ?area) (factHistory (str-cat "{R" (?*rulesMap* get MANIFEST::catalog-data) " " ?fh "}")))
    )


(defrule MASS-BUDGET::estimate-depth-of-discharge
    ?sat <- (MANIFEST::Mission (orbit-type ?typ&~nil) (orbit-RAAN ?raan&~nil)
        (depth-of-discharge nil) (factHistory ?fh))
    =>
    (modify ?sat (depth-of-discharge (get-dod ?typ ?raan)) (factHistory (str-cat "{R" (?*rulesMap* get MASS-BUDGET::estimate-depth-of-discharge) " " ?fh "}")))
    )

(defrule MASS-BUDGET::design-EPS
    ?miss<- (MANIFEST::Mission (payload-power# ?p&~nil) (payload-peak-power# ?pp&~nil) (comm-OBDH-power# ?obdh-power&~nil) (avionics-power# ?av-power&~nil)
    (depth-of-discharge ?dod&~nil) (orbit-semimajor-axis ?a&~nil) (orbit-type ?typ&~nil) (worst-sun-angle ?angle&~nil) (fraction-sunlight ?frac&~nil) (ADCS-power# ?adcs-pow&~nil)
    (EPS-mass# nil) (satellite-dry-mass ?m&~nil) (satellite-BOL-power# nil) (lifetime ?life&~nil) (bus-BOL-power ?bus) (battery-type ?batt) (SA-type ?array)
    (battery-mass ?mbatt) (num-battery ?nbatt) (cpu-mass ?mcpu) (reg-conv-mass ?mrc) (wiring-mass ?mwiring) (SA-component ?SA-component) 
    (battery-component ?battery-component) (solar-array-area ?area) (factHistory ?fh))

    =>
    ;(printout t "Payload power: " ?p " " ?pp crlf)
    ;(printout t "OBDH power: "  ?obdh-power  crlf)
    ;(printout t "AV power: "  ?obdh-power  crlf)
    ;(printout t "ADCS power: "  ?obdh-power  crlf)

    ;" "" " ?av-power " " ?adcs-pow " " ?frac " " ?angle " " (orbit-period ?a) " " ?life " " ?m " " ?dod " "

    ;(bind ?list (design-EPS ?p ?p ?frac ?angle (orbit-period ?a) ?life ?m ?dod)) ;<- original EPS design algorithm
    (bind ?list (MatlabFunctions newEPS ?p ?pp ?obdh-power ?av-power ?adcs-pow ?frac ?angle (orbit-period ?a) ?life ?m ?dod ?area ?SA-component ?battery-component ?nbatt))

    (bind ?epsm (nth$ 1 ?list)) (bind ?pow (nth$ 2 ?list)) (bind ?area (nth$ 3 ?list)) (bind ?samass (nth$ 4 ?list)) (bind ?batt (nth$ 5 ?list)) (bind ?array (nth$ 6 ?list))
    (bind ?mbatt (nth$ 7 ?list)) (bind ?nbatt (nth$ 8 ?list)) (bind ?mcpu (nth$ 9 ?list)) (bind ?mrc (nth$ 10 ?list)) (bind ?mwiring (nth$ 11 ?list))
    ;(printout t "BOL power: " ?pow crlf)
    (modify ?miss (EPS-mass# ?epsm) (bus-BOL-power 0) (satellite-BOL-power# ?pow) (solar-array-area ?area) (solar-array-mass ?samass) (battery-type ?batt) (SA-type ?array)
    (battery-mass ?mbatt) (num-battery ?nbatt) (cpu-mass ?mcpu) (reg-conv-mass ?mrc) (wiring-mass ?mwiring) (factHistory (str-cat "{R" (?*rulesMap* get MASS-BUDGET::design-EPS) " " ?fh "}")))
    )


; ******************************************
; SUPPORTING QUERIES AND FUNCTIONS
; ******************************************

(deffunction get-dod (?type ?raan) ; see SMAD Page 422
"This function estimates the depth of discharge of an orbit"

    (if (eq ?type GEO) then (bind ?dod 0.8)
        elif (and (eq ?type SSO) (eq ?raan DD)) then (bind ?dod 0.6)
        else (bind ?dod 0.4)
        )
    (return ?dod)
    )
