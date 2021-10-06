; ********************
; Payload cost (salience 20)
; ********************

(deffunction is-domestic (?who)
    (return (eq (sub-string 1 3 ?who) "DOM"))
    )

(deffunction sum$ (?list)
    (if (eq (length$ ?list) 1) then (return (nth$ 1 ?list))
        else (return (+ (nth$ 1 ?list) (sum$ (rest$ ?list)))))
    )


(deffunction apply-NICM (?m ?p ?rb ?name)

    (bind ?cost (* 25600 (** (/ ?p 61.5) 0.32) (** (/ ?m 53.8) 0.26)
            (** (/ (* 1000 ?rb) 40.4) 0.11))); in FY04$
    (bind ?cost (/ ?cost 1.097))
    ;(printout t apply-NICM " " ?name " = " ?m " " ?p " " ?rb " " ?cost crlf)
    (return ?cost)
    )

(defrule COST-ESTIMATION::estimate-instrument-cost
    "This rule estimates payload cost using a very simplified version of the
    NASA Instrument Cost Model available on-line"
    (declare (salience 25) (no-loop TRUE))
    ?instr <- (CAPABILITIES::Manifested-instrument (Name ?name) (cost# nil) (mass# ?m&~nil&:(> ?m 10)) (average-power# ?p&~nil) (average-data-rate# ?rb&~nil)
            (developed-by ?whom) (factHistory ?fh))
    =>

    (bind ?c0 (apply-NICM ?m ?p ?rb ?name))
    ;(printout t "Payload cost params: " ?m " " ?p " " ?rb " " ?name " " ?c0 crlf)
    (modify ?instr (cost# ?c0) (factHistory (str-cat "{R" (?*rulesMap* get COST-ESTIMATION::estimate-instrument-cost) " " ?fh "}")))
    )

(defrule COST-ESTIMATION::estimate-instrument-cost-small
    "This rule estimates payload cost using a very simplified version of the
    NASA Instrument Cost Model available on-line"
    (declare (salience 25) (no-loop TRUE))
    ?instr <- (CAPABILITIES::Manifested-instrument (Name ?name) (cost# nil) (mass# ?m&~nil&:(<= ?m 10)) (average-power# ?p&~nil) (average-data-rate# ?rb&~nil)
            (developed-by ?whom) (factHistory ?fh))
    =>

    (bind ?c0 4000)
    ;(printout t "Payload cost params: " ?m " " ?p " " ?rb " " ?name " " ?c0 crlf)
    (modify ?instr (cost# ?c0) (factHistory (str-cat "{R" (?*rulesMap* get COST-ESTIMATION::estimate-instrument-cost) " " ?fh "}")))
    )



(defrule COST-ESTIMATION::estimate-payload-cost2
    "This rule estimates payload cost using a very simplified version of the
    NASA Instrument Cost Model available on-line"
    (declare (salience 18))
    ?miss <- (MANIFEST::Mission (payload-cost# nil) (instruments $?payload)
        )
    =>
    (printout t "Instruments: " $?payload crlf)
    (bind ?costs (map get-instrument-cost-manifest ?payload)); in FY04$

    (bind ?cost (sum$ ?costs)); correct for inflation from FY04 to FY00, from http://oregonstate.edu/cla/polisci/faculty-research/sahr/cv2000.pdf
    ;(printout t "Payload cost: instrument cost = " (* ?cost 1e3) crlf)

        (modify ?miss (payload-cost# ?cost) (payload-non-recurring-cost# (* 0.8 ?cost))
        (payload-recurring-cost# (* 0.2 ?cost)))
    )

(defrule COST-ESTIMATION::estimate-payload-cost-cubesat
    "This rule estimates payload cost using a very simplified version of the
    NASA Instrument Cost Model available on-line"
    (declare (salience 18))
    ?miss <- (MANIFEST::Mission (payload-mass# ?m&~nil&:(<= ?m 10)) (instruments $?payload)
        )
    =>
    (bind ?cost 4000)
    (modify ?miss (payload-cost# ?cost) (payload-non-recurring-cost# 3000)
    (payload-recurring-cost# 1000))
    )

; ********************
; Bus cost (salience 10)
; ********************

; bus non recurring cost
(defrule COST-ESTIMATION::estimate-bus-non-recurring-cost
    "This rule estimates bus non-recurring cost using SMAD CERs"
    (declare (salience 10))
    ?miss <- (MANIFEST::Mission (bus-non-recurring-cost# nil)
        (satellite-BOL-power# ?p&~nil) (EPS-mass# ?epsm&~nil) (thermal-mass# ?thm&~nil)
        (structure-mass# ?strm &~nil) (propulsion-mass# ?prm&~nil) (avionics-mass# ?comm&~nil)
        (ADCS-mass# ?adcm&~nil) (standard-bus ?bus) (satellite-dry-mass ?m&~nil&:(> ?m 24))
        )
    (or (test (eq ?bus nil)) (test (eq ?bus dedicated-class)))
    =>
    ;(printout t "Mass" crlf)
    ;(printout t "Str " ?strm " kg" crlf)
    ;(printout t "Prop " ?prm " kg" crlf)
    ;(printout t "ADCS " ?adcm " kg" crlf)
    ;(printout t "Comm " ?comm " kg" crlf)
    ;(printout t "Therm " ?thm " kg" crlf)
    ;(printout t "Power " ?epsm " kg" crlf)

    (bind ?str-cost (str-cost-non-recurring ?strm))
    (bind ?prop-cost (prop-cost-non-recurring ?prm))
    (bind ?adcs-cost (adcs-cost-non-recurring ?adcm))
    (bind ?comm-cost (comm-cost-non-recurring ?comm))
    (bind ?therm-cost (therm-cost-non-recurring ?thm))
    (bind ?pow-cost (eps-cost-non-recurring ?epsm ?p))

    (printout t "Cost - NR" crlf)
    (printout t "Str $" (* ?str-cost 1e3) crlf)
    (printout t "Prop $" (* ?prop-cost 1e3) crlf)
    (printout t "ADCS $" (* ?adcs-cost 1e3) crlf)
    (printout t "Comm $" (* ?comm-cost 1e3) crlf)
    (printout t "Therm $" (* ?therm-cost 1e3) crlf)
    (printout t "Power $" (* ?pow-cost 1e3) crlf)

    (bind ?cost (+ ?str-cost ?prop-cost ?adcs-cost ?comm-cost ?therm-cost ?pow-cost)); correct for inflation from FY04 to FY00, from http://oregonstate.edu/cla/polisci/faculty-research/sahr/cv2000.pdf
    (modify ?miss (bus-non-recurring-cost# ?cost) (str-cost-nr# ?str-cost) (prop-cost-nr# ?prop-cost) (adcs-cost-nr# ?adcs-cost)
              (comm-cost-nr# ?comm-cost) (therm-cost-nr# ?therm-cost) (eps-cost-nr# ?pow-cost) )
    )

  (deffunction str-cost-non-recurring (?strm)
    (if (< ?strm (* 0.75 54)) then (return 0)
      else (return (* 157 (** ?strm 0.83)))
    )
  )

  (deffunction prop-cost-non-recurring (?prm)
    (if (< ?prm (* 0.75 81)) then (return 0)
      else (return (* 17.8 (** ?prm 0.75)))
    )
  )

  (deffunction adcs-cost-non-recurring (?adcm)
    (if (< ?adcm (* 0.75 20)) then (return 0)
      else (return (* 464 (** ?adcm 0.867)))
    )
  )

  (deffunction comm-cost-non-recurring (?comm)
    (if (< ?comm (* 0.75 12)) then (return 0)
      else (return (* 545 (** ?comm 0.761)))
    )
  )

  (deffunction therm-cost-non-recurring (?thm)
    (if (< ?comm (* 0.75 3)) then (return 0)
      else (return (* 394 (** ?thm 0.635)))
    )
  )

  (deffunction eps-cost-non-recurring (?epsm ?p)
    (if (< ?epsm (* 0.75 31)) then (return 0)
      elif (< ?epsm (* 0.75 100)) then (return (* 62.7 ?epsm))
      else (return (* 2.63 (** (* ?epsm ?p) 0.712)))
    )
  )

; bus recurring cost
(defrule COST-ESTIMATION::estimate-bus-TFU-recurring-cost
    "This rule estimates bus recurring cost (TFU) using SMAD CERs"
    (declare (salience 10))
    ?miss <- (MANIFEST::Mission (bus-recurring-cost# nil) (satellite-BOL-power# ?p&~nil)
        (EPS-mass# ?epsm&~nil) (thermal-mass# ?thm&~nil) (avionics-mass# ?comm&~nil)
        (structure-mass# ?strm &~nil) (propulsion-mass# ?prm&~nil)
        (ADCS-mass# ?adcm&~nil) (standard-bus ?bus) (satellite-dry-mass ?m&~nil&:(> ?m 24))
        )
    (or (test (eq ?bus nil)) (test (eq ?bus dedicated-class)))
    =>
    ;(printout t "Mass" crlf)
    ;(printout t "Str " ?strm " kg" crlf)
    ;(printout t "Prop " ?prm " kg" crlf)
    ;(printout t "ADCS " ?adcm " kg" crlf)
    ;(printout t "Comm " ?comm " kg" crlf)
    ;(printout t "Therm " ?thm " kg" crlf)
    ;(printout t "Power " ?epsm " kg" crlf)

    ;Calls recurring cost estimation relations from SMAD 3rd Edition. If subsystem mass is under the range of validity for large satellite relations, small sat CERs are used
    (bind ?str-cost (str-cost-recurring ?strm))
    (bind ?prop-cost (prop-cost-recurring ?prm ?strm ?adcm ?comm ?thm ?epsm))
    (bind ?adcs-cost (adcs-cost-recurring ?adcm))
    (bind ?comm-cost (comm-cost-recurring ?comm))
    (bind ?therm-cost (therm-cost-recurring ?thm))
    (bind ?pow-cost (eps-cost-recurring ?epsm ?p))

    ;(printout t "Cost - Rec" crlf)
    ;(printout t "Str $" (* ?str-cost 1e3) crlf)
    ;(printout t "Prop $" (* ?prop-cost 1e3) crlf)
    ;(printout t "ADCS $" (* ?adcs-cost 1e3) crlf)
    ;(printout t "Comm $" (* ?comm-cost 1e3) crlf)
    ;(printout t "Therm $" (* ?therm-cost 1e3) crlf)
    ;(printout t "Power $" (* ?pow-cost 1e3) crlf)
    ; TODO same as above

    (bind ?cost (+ ?str-cost ?prop-cost ?adcs-cost ?comm-cost ?therm-cost ?pow-cost)); correct for inflation from FY04 to FY00, from http://oregonstate.edu/cla/polisci/faculty-research/sahr/cv2000.pdf
    (modify ?miss (bus-recurring-cost# ?cost) (str-cost# ?str-cost) (prop-cost# ?prop-cost) (adcs-cost# ?adcs-cost)
              (comm-cost# ?comm-cost) (therm-cost# ?therm-cost) (eps-cost# ?pow-cost) )
    )

    (deffunction str-cost-recurring (?strm)
      (if (< ?strm (* 0.75 54)) then (return (+ 299 (* 14.2 (log ?strm))))
        else (return (* 13.1 ?strm))
      )
    )

    (deffunction prop-cost-recurring (?prm ?strm ?adcsm ?comm ?thm ?epsm)
      (bind ?busm (+ ?prm ?strm ?adcsm ?comm ?thm ?epsm))

      (printout t "Dry Mass: " ?busm crlf)

      (if (< ?prm (* 0.75 81)) then (return (+ 65.6 (* 2.19 (** ?busm 1.261))))
        else (return (* 4.97 (** ?prm 0.823)))
      )
    )

    (deffunction adcs-cost-recurring (?adcm)
      (if (< ?adcm (* 0.75 20)) then (return (+ 1358 (* 8.58 (** ?adcm 2))))
        else (return (* 293 (** ?adcm 0.777)))
      )
    )

    (deffunction comm-cost-recurring (?comm)
      (if (< ?comm (* 0.75 13)) then (return (+ 484 (* 55 (** ?comm 1.35))))
        else (return (* 635 (** ?comm 0.568)))
      )
    )

    (deffunction therm-cost-recurring (?thm)
      (if (< ?comm (* 0.75 3)) then (return (+ 299 (* 14.2 ?thm (log ?thm))))
        else (return (* 50.6 (** ?thm 0.707)))
      )
    )

    (deffunction eps-cost-recurring (?epsm ?p)
      ;(printout t "BOL Power: " ?p crlf)
      ; relations from 3rd edition of SMAD
      (if (< ?epsm (* 0.75 31)) then (return (+ 131 (* 401 (** ?p 0.452))))
        else (return (* 112 (** ?epsm 0.763)))
      )

    )

(defrule COST-ESTIMATION::cubesat-12U-cost
    "This rule assigns a rule of thumb 12U cost"
    (declare (salience 10))
    ?miss <- (MANIFEST::Mission (bus-recurring-cost# nil)
        (satellite-dry-mass ?m&~nil&:(<= ?m 24))
        )
    =>
    (bind ?cost 1500)

    (modify ?miss (bus-recurring-cost# ?cost) (bus-non-recurring-cost# 0.0))
    )

; ********************
; Total spacecraft cost (salience 5)
; ********************

; spacecraft recurring and non-recurring s/c cost
(defrule COST-ESTIMATION::estimate-spacecraft-cost-dedicated
    "This rule estimates s/c non recurring cost adding up bus and payload n/r cost"
    (declare (salience 5))
    ?miss <- (MANIFEST::Mission (spacecraft-non-recurring-cost# nil) (spacecraft-recurring-cost# nil)
        (bus-non-recurring-cost# ?busnr&~nil) (bus-recurring-cost# ?bus&~nil) (payload-cost# ?payl&~nil) (standard-bus ?sbus)
        )
    (or (test (eq ?sbus nil)) (test (eq ?sbus dedicated-class)))
    =>
    (bind ?spacecraftnr (+ ?busnr (* ?payl 0.6))) ; TODO source?
    (bind ?spacecraft (+ ?bus (* ?payl 0.4))) ; TODO source?
    (bind ?sat (+ ?spacecraftnr ?spacecraft))

    (printout t crlf "Spacecraft Cost $" (* (+ ?busnr ?bus) 1e3) crlf)

    (modify ?miss (spacecraft-non-recurring-cost# ?spacecraftnr)
         (spacecraft-recurring-cost# ?spacecraft) (bus-cost# (+ ?busnr ?bus)) (satellite-cost# ?sat))
    )


; ********************
; Integration, assembly and testing cost (salience 0)
; ********************

; IA&T cost
(defrule COST-ESTIMATION::estimate-integration-and-testing-cost ; TODO sources
    "This rule estimates Integration, assembly and testing non recurring and cost using SMAD CERs"
    ?miss <- (MANIFEST::Mission (IAT-non-recurring-cost# nil) (IAT-recurring-cost# nil) (IAT-cost# nil)
        (spacecraft-non-recurring-cost# ?scnr&~nil) (satellite-dry-mass ?m&~nil&:(> ?m 24))
        )
    =>
    (bind ?iatnr (+ 989 (* ?scnr 0.215)))
    (bind ?iatr (* 10.4 ?m))
    (bind ?iat (+ ?iatr ?iatnr))
    (modify ?miss (IAT-non-recurring-cost# ?iatnr)
         (IAT-recurring-cost# ?iatr) (IAT-cost# ?iat))
    )

(defrule COST-ESTIMATION::estimate-integration-and-testing-cost-cubesat
    "This rule estimates Integration, assembly and testing non recurring and cost for a cubesat"
    ?miss <- (MANIFEST::Mission (IAT-non-recurring-cost# nil) (IAT-recurring-cost# nil) (IAT-cost# nil)
        (spacecraft-non-recurring-cost# ?scnr&~nil) (satellite-dry-mass ?m&~nil&:(<= ?m 24))
        )
    =>
    (bind ?iatnr 500)
    (bind ?iatr 500)
    (bind ?iat (+ ?iatr ?iatnr))
    (modify ?miss (IAT-non-recurring-cost# ?iatnr)
         (IAT-recurring-cost# ?iatr) (IAT-cost# ?iat))
    )

; ********************
; Program overhead cost (salience 0)
; ********************
(defrule COST-ESTIMATION::estimate-program-overhead-cost ; TODO sources
    "This rule estimates program overhead non recurring and cost using SMAD CERs"
    ?miss <- (MANIFEST::Mission (program-non-recurring-cost# nil) (program-recurring-cost# nil) (program-cost# nil)
        (spacecraft-non-recurring-cost# ?scnr&~nil) (spacecraft-recurring-cost# ?scr&~nil) (satellite-dry-mass ?m&~nil&:(> ?m 24))
        )
    =>
    (bind ?prognr (* 1.963 (** ?scnr 0.841)))
    (bind ?progr (* 0.341 ?scr))
    (bind ?prog (+ ?progr ?prognr))
    (modify ?miss (program-non-recurring-cost# ?prognr)
         (program-recurring-cost# ?progr) (program-cost# ?prog))
    )

(defrule COST-ESTIMATION::estimate-program-overhead-cost-cubesat
    "This rule estimates program overhead non recurring and cost for a cubesat"
    ?miss <- (MANIFEST::Mission (program-non-recurring-cost# nil) (program-recurring-cost# nil) (program-cost# nil)
        (spacecraft-non-recurring-cost# ?scnr&~nil) (spacecraft-recurring-cost# ?scr&~nil) (satellite-dry-mass ?m&~nil&:(<= ?m 24))
        )
    =>
    (bind ?prognr 500)
    (bind ?progr 500)
    (bind ?prog (+ ?progr ?prognr))
    (modify ?miss (program-non-recurring-cost# ?prognr)
         (program-recurring-cost# ?progr) (program-cost# ?prog))
    )

; ********************
; Operations cost (salience -5)
; ********************

(defrule COST-ESTIMATION::estimate-operations-cost-std
    "This rule estimates operations cost using NASAs MOCM"
    (declare (salience -5))
    ?miss <- (MANIFEST::Mission (satellite-cost# ?sat&~nil) (operations-cost# nil)
        (lifetime ?life &~nil) (program-cost# ?prog&~nil) (IAT-cost# ?iat&~nil)
        (sat-data-rate-per-orbit# ?rbo&nil) (satellite-dry-mass ?m&~nil&:(> ?m 24)))
    =>
    (bind ?total-cost (+ ?sat ?prog ?iat))
    (bind ?total-cost (* ?total-cost 0.001097)); correct for inflation and transform to $M
    (bind ?ops-cost (* (* 0.035308 (** ?total-cost 0.928)) ?life)); NASA MOCM in FY04$M
    (bind ?ops-cost (/ ?ops-cost 0.001097)); back to FY00$k
    (modify ?miss (operations-cost# ?ops-cost))
    )


(defrule COST-ESTIMATION::estimate-operations-cost-with-ground-station-penalty
    "This rule estimates operations cost using NASAs MOCM"
    (declare (salience -5))
    ?miss <- (MANIFEST::Mission (satellite-cost# ?sat&~nil) (operations-cost# nil)
        (lifetime ?life &~nil) (program-cost# ?prog&~nil) (IAT-cost# ?iat&~nil)
        (sat-data-rate-per-orbit# ?rbo&~nil) (satellite-dry-mass ?m&~nil&:(> ?m 24)))
    =>
    (bind ?total-cost (+ ?sat ?prog ?iat))
    (bind ?total-cost (* ?total-cost 0.001097)); correct for inflation and transform to $M
    (bind ?ops-cost (* (* 0.035308 (** ?total-cost 0.928)) ?life)); NASA MOCM in FY04$M
    (bind ?ops-cost (/ ?ops-cost 0.001097)); back to FY00$k
    (if (> ?rbo (* 5 60 700 (/ 1 8192))) then (bind ?pen 10.0) else (bind ?pen 1.0))
    ;(printout t "penalty =" ?pen crlf)
    (modify ?miss (operations-cost# (* ?ops-cost ?pen)))
    )

(defrule COST-ESTIMATION::estimate-operations-cost-cubesat
    "This rule estimates operations cost for a cubesat using rules of thumb"
    (declare (salience -5))
    ?miss <- (MANIFEST::Mission (satellite-cost# ?sat&~nil) (operations-cost# nil)
        (lifetime ?life &~nil) (num-of-planes# ?np&~nil) (num-of-sats-per-plane# ?ns&~nil) (satellite-dry-mass ?m&~nil&:(<= ?m 24)))
    =>
    ;(bind ?N (* ?np ?ns))
    ;(bind ?salary (+ 200 (log ?N)))
    (bind ?salary 100)
    (bind ?groundpass 550)
    (bind ?cost (* (+ ?salary ?groundpass) ?life))
    (modify ?miss (operations-cost# ?cost))
    )

; ********************
; Total cost (salience -10)
; ********************
(defquery COST-ESTIMATION::search-instrument-TRL
    (declare (variables ?ins))
    (DATABASE::Instrument (Name ?ins) (Technology-Readiness-Level ?trl))
    )


(deffunction get-instrument-trl (?ins)
    (bind ?result (run-query* COST-ESTIMATION::search-instrument-TRL ?ins))
    (?result next)
    (bind ?trl (?result getDouble trl))
    (return ?trl)
    )

(deffunction get-instrument-list-trls (?list)
    (bind ?trls (new java.util.ArrayList))
    (foreach ?ins ?list
        (bind ?trl (get-instrument-trl ?ins))
        (?trls add ?trl)
        )
    (return ?trls)
    )

(deffunction p*$ (?x ?y)
    (printout t " p*$ " ?x ?y crlf)
    (if (not (listp ?x)) then (return (* ?x ?y)))
    (bind ?z (create$ ))
    (for (bind ?i 1) (<= ?i (length$ ?x)) (++ ?i)
    (printout t ?i crlf) (bind ?z (insert$ ?z ?i (* (eval (nth$ ?i ?x)) (eval (nth$ ?i ?y))))))

    (return ?z))

(defrule COST-ESTIMATION::estimate-total-mission-cost-with-overruns
    "This rule estimates total mission cost adding an overrun which is proportional to
    the expected schedule slippage, which in turn is a function of the TRL of the less
    mature instrument in the payload"

    (declare (salience -10))
    ?miss <- (MANIFEST::Mission (satellite-cost# ?sat&~nil) (operations-cost# ?ops&~nil)
        (launch-cost# ?launch&~nil) (program-cost# ?prog&~nil) (IAT-cost# ?iat&~nil)
        (mission-cost# nil) (instruments $?ins) (partnership-type $?prt&:(eq (length$ ?prt) 0))
        )
    =>
    ;(printout t $?ins crlf)
    (bind ?mission-cost (+ ?sat ?prog ?iat ?ops (* 1000 ?launch)))
    (bind ?mission-cost (/ ?mission-cost 1000)); to $M
    (bind ?over (compute-cost-overrun (get-instrument-list-trls ?ins)))
    (modify ?miss (mission-cost# (* ?mission-cost (+ 1 ?over))))
    )



(defrule COST-ESTIMATION::estimate-total-mission-cost-with-overruns-when-partnership
    "This rule estimates total mission cost adding an overrun which is proportional to
    the expected schedule slippage, which in turn is a function of the TRL of the less
    mature instrument in the payload. Partnerships with internationals are taken into
    account"

    (declare (salience -10))
    ?miss <- (MANIFEST::Mission (satellite-cost# ?sat&~nil) (operations-cost# ?ops&~nil)
        (launch-cost# ?launch&~nil) (program-cost# ?prog&~nil) (IAT-cost# ?iat&~nil)
        (payload-cost# ?payl&~nil) (bus-cost# ?bus&~nil)
        (mission-cost# nil) (instruments $?ins) (partnership-type $?prt&:(> (length$ ?prt) 0))
        )
    =>
    ;(printout t $?ins crlf)
    ;(bind ?costs (create$ ?sat ?prog ?iat ?ops (* 1000 ?launch)))
    (bind ?costs (create$ ?payl ?bus (* 1000 ?launch) ?prog ?iat ?ops))

    (bind ?mission-cost (dot-product$ ?costs ?prt))
    ;(bind ?mission-cost (+ ?sat ?prog ?iat ?ops (* 1000 ?launch)))
    (bind ?mission-cost (/ ?mission-cost 1000)); to $M

    (bind ?over (compute-cost-overrun (get-instrument-list-trls ?ins)))
    ;(printout t ?mission-cost " " ?over " " (* ?mission-cost (+ 1 ?over)) crlf)
    (modify ?miss (mission-cost# (* ?mission-cost (+ 1 ?over))))

    )


(defrule COST-ESTIMATION::estimate-total-mission-cost-non-recurring
    "Non recurring cost"

    (declare (salience -10))
    ?miss <- (MANIFEST::Mission (bus-non-recurring-cost# ?bus&~nil) (payload-non-recurring-cost# ?payl&~nil)
        (program-non-recurring-cost# ?prog&~nil) (IAT-non-recurring-cost# ?iat&~nil)
        (mission-non-recurring-cost# nil))

    =>
    (bind ?mission-cost (/ (+ ?bus ?payl ?prog ?iat) 1000)); to $M
    (modify ?miss (mission-non-recurring-cost# ?mission-cost))
    )

(defrule COST-ESTIMATION::launch-cost-cubesat-override
    "Overriding launch cost computation using rule of thumb"
    (declare (salience 10))
    ?miss <- (MANIFEST::Mission (launch-cost# ?launch&~nil) (num-of-planes# ?np&~nil) (num-of-sats-per-plane# ?ns&~nil) (satellite-dry-mass ?m&~nil&:(<= ?m 24)))
    =>
    (bind ?N (* ?np ?ns))
    (bind ?cost (* (* ?N 0.1) 12))
    (modify ?miss (launch-cost# ?cost))
    )

(defrule COST-ESTIMATION::estimate-total-mission-cost-recurring
    "Recurring cost"

    (declare (salience -10))
    ?miss <- (MANIFEST::Mission (bus-recurring-cost# ?bus&~nil) (payload-recurring-cost# ?payl&~nil)
        (program-recurring-cost# ?prog&~nil) (IAT-recurring-cost# ?iat&~nil) (operations-cost# ?ops&~nil)
        (launch-cost# ?launch&~nil) (num-of-planes# ?np&~nil) (num-of-sats-per-plane# ?ns&~nil)
        (mission-recurring-cost# nil) )

    =>
    (bind ?mission-cost (/ (+ ?bus ?payl ?prog ?iat ?ops) 1000)); to $M
	(bind ?S 0.95); 95% learning curve, means doubling N reduces average cost by 5% (See  SMAD p 809)
    (bind ?N (* ?np ?ns))
    (bind ?B (- 1 (/ (log (/ 1 ?S)) (log 2))))
    (bind ?L (** ?N ?B))
    (bind ?total-cost (* ?L ?mission-cost))
    (modify ?miss (mission-recurring-cost# (+ ?total-cost ?launch)))
    )

(defrule COST-ESTIMATION::estimate-lifecycle-mission-cost
    ?miss <- (MANIFEST::Mission (mission-recurring-cost# ?rec&~nil)
         (mission-non-recurring-cost# ?nr&~nil) (lifecycle-cost# nil))
    => (modify ?miss (lifecycle-cost# (+ ?rec ?nr)))
    )

(defrule INFLATION::inflate-all-cost-values
    (declare (no-loop TRUE))
    ?miss <- (MANIFEST::Mission (mission-recurring-cost# ?miss-r&~nil) (mission-non-recurring-cost# ?miss-nr&~nil)
                                (lifecycle-cost# ?lc&~nil) (bus-recurring-cost# ?bus-r&~nil)
                                (payload-recurring-cost# ?pay-r&~nil) (program-recurring-cost# ?prog-r&~nil)
                                (IAT-recurring-cost# ?iat-r&~nil) (operations-cost# ?ops-r&~nil)
                                (launch-cost# ?launch-r&~nil) (bus-non-recurring-cost# ?bus-nr&~nil)
                                (payload-non-recurring-cost# ?payl-nr&~nil) (program-non-recurring-cost# ?prog-nr&~nil)
                                (IAT-non-recurring-cost# ?iat-nr&~nil) (bus-cost# ?bus&~nil) (IAT-cost# ?iat&~nil)
                                (mission-cost# ?misscost&~nil)
                                (payload-cost# ?pay&~nil) (satellite-cost# ?sat&~nil) (str-cost# ?str&~nil)
                                (prop-cost# ?prop&~nil) (adcs-cost# ?adcs&~nil) (comm-cost# ?comm&~nil)
                                (therm-cost# ?therm&~nil) (eps-cost# ?eps&~nil) (launch-date ?ld&~nil))
    =>
    (bind ?miss-r (MatlabFunctions inflate ?miss-r 2000 ?ld))
    (bind ?miss-nr (MatlabFunctions inflate ?miss-nr 2000 ?ld))
    (bind ?lc (MatlabFunctions inflate ?lc 2000 ?ld))
    (bind ?bus-r (MatlabFunctions inflate ?bus-r 2000 ?ld))
    (bind ?pay-r (MatlabFunctions inflate ?pay-r 2004 ?ld))
    (bind ?prog-r (MatlabFunctions inflate ?prog-r 2000 ?ld))
    (bind ?iat-r (MatlabFunctions inflate ?iat-r 2000 ?ld))
    (bind ?ops-r (MatlabFunctions inflate ?ops-r 2000 ?ld))
    (bind ?launch-r (MatlabFunctions inflate ?launch-r 2000 ?ld))
    (bind ?payl-nr (MatlabFunctions inflate ?payl-nr 2004 ?ld))
    (bind ?prog-nr (MatlabFunctions inflate ?prog-nr 2000 ?ld))
    (bind ?iat-nr (MatlabFunctions inflate ?iat-nr 2000 ?ld))
    (bind ?bus (MatlabFunctions inflate ?bus 2000 ?ld))
    (bind ?iat (MatlabFunctions inflate ?iat 2000 ?ld))
    (bind ?misscost (MatlabFunctions inflate ?misscost 2000 ?ld))
    (bind ?pay (MatlabFunctions inflate ?pay 2000 ?ld))
    (bind ?sat (MatlabFunctions inflate ?sat 2000 ?ld))
    (bind ?str (MatlabFunctions inflate ?str 2000 ?ld))
    (bind ?prop (MatlabFunctions inflate ?prop 2000 ?ld))
    (bind ?adcs (MatlabFunctions inflate ?adcs 2000 ?ld))
    (bind ?comm (MatlabFunctions inflate ?comm 2000 ?ld))
    (bind ?therm (MatlabFunctions inflate ?therm 2000 ?ld))
    (bind ?eps (MatlabFunctions inflate ?eps 2000 ?ld))
    (modify ?miss (mission-recurring-cost# ?miss-r) (mission-non-recurring-cost# ?miss-nr)
                                      (lifecycle-cost# ?lc) (bus-recurring-cost# ?bus-r)
                                      (payload-recurring-cost# ?pay-r) (program-recurring-cost# ?prog-r)
                                      (IAT-recurring-cost# ?iat-r) (operations-cost# ?ops-r)
                                      (launch-cost# ?launch-r) (bus-non-recurring-cost# ?bus-nr)
                                      (payload-non-recurring-cost# ?payl-nr)
                                      (program-non-recurring-cost# ?prog-nr)
                                      (IAT-non-recurring-cost# ?iat-nr) (bus-cost# ?bus) (IAT-cost# ?iat)
                                      (mission-cost# ?misscost)
                                      (payload-cost# ?pay) (satellite-cost# ?sat) (str-cost# ?str)
                                      (prop-cost# ?prop) (adcs-cost# ?adcs) (comm-cost# ?comm)
                                      (therm-cost# ?therm) (eps-cost# ?eps))

    )

(defquery COST-ESTIMATION::search-cost-breakdown
    (declare (variables ?name))
    (MANIFEST::Mission (Name ?name) (mission-cost# ?total) (payload-cost# ?payl)
        (bus-cost# ?bus)  (launch-cost# ?launch)  (program-cost# ?prog) (IAT-cost# ?iat) (operations-cost# ?ops))
    )

(deffunction get-cost-breakdown (?miss)
    (bind ?results (run-query* COST-ESTIMATION::search-cost-breakdown ?miss))
    (while (?results next)
        (bind ?list (create$ (?results getDouble payl) (?results getDouble bus)
                (* 1000 (?results getDouble launch)) (?results getDouble prog)
                 (?results getDouble iat) (?results getDouble ops)
                (* 1000 (?results getDouble total))))
        )
    (return (map (lambda (?x) (return (/ ?x 1000))) ?list))
    )
