(deftemplate MODELER::consumed-end
    (slot end-fact (type FACT-ADDRESS))
    (slot rule-system-serial (type INTEGER))
    (slot output-table (type INTEGER))
)
(defrule MODELER::purge-consumed-ends
    ?f <- (consumed-end)  ;; clean up all transient facts for the next RECORDER pass
    =>
    (retract ?f)
)

(deftemplate MODELER::open-start-interval
    (slot time (type INTEGER))
    (slot identifier (type INTEGER))
    (slot subsystem (type STRING))
    (slot category (type STRING))
    (slot name (type STRING))
    (slot thread (type EXTERNAL-ADDRESS SYMBOL) (allowed-symbols sentinel) (default ?NONE))
    (slot process (type EXTERNAL-ADDRESS SYMBOL) (allowed-symbols sentinel) (default ?NONE))
    (multislot message$)
    (slot message (type EXTERNAL-ADDRESS SYMBOL) (allowed-symbols sentinel) (default sentinel))
    (slot user-backtrace (type EXTERNAL-ADDRESS SYMBOL) (allowed-symbols sentinel))
    (slot rule-system-serial (type INTEGER))
    (slot output-table (type INTEGER))
    (multislot layout-category (default ?NONE))
    (slot layout-id (type INTEGER SYMBOL))
)
(deftemplate MODELER::matched-interval
    (slot open-fact (type FACT-ADDRESS))
    (slot end-fact (type FACT-ADDRESS))
    (slot rule-system-serial (type INTEGER))
    (slot output-table (type INTEGER))
)

(defrule MODELER::start-interval-for-system-1 
    (table-attribute (table-id ?autoOutput_) (has schema component-layout-schema))
    (table (table-id ?autoOutput_) (side append))
    (or (table-attribute (table-id ?autoOutput_) (has target-pid ?target-pid))
        (and (not (table-attribute (table-id ?autoOutput_) (has target-pid $?)))
             (modeler-constants (sentinel-symbol ?target-pid))
        )
    )
    (os-signpost 
        (event-type "Begin")
        (category "UIComponent")
        (thread ?autoThreadBinding_)
        (time ?autoStartTimeBinding_&~0)
        (subsystem "com.lapse.UIComponent")
        (message$ "Component:" ?component-name)
        (identifier ?autoSignpostIdentifier_)
        (process ?autoProcessBinding_)
        (name "ComponentBuilder")
    )

    =>

    (bind ?autoLayoutCat_ (create$ global ?autoOutput_))
    (assert (open-start-interval 
               (category "UIComponent")
               (thread ?autoThreadBinding_)
               (time ?autoStartTimeBinding_)
               (subsystem "com.lapse.UIComponent")
               (message$ ?component-name)
               (identifier ?autoSignpostIdentifier_)
               (process ?autoProcessBinding_)
               (name "ComponentBuilder")
               (rule-system-serial 1)
               (output-table ?autoOutput_)
               (layout-category ?autoLayoutCat_)
               (layout-id (reserve-layout-lane ?autoLayoutCat_))
            ))
)

(defrule RECORDER::end-interval-for-system-1 
    (table (table-id ?autoOutput_) (side append))
    (or (table-attribute (table-id ?autoOutput_) (has target-pid ?target-pid))
        (and (not (table-attribute (table-id ?autoOutput_) (has target-pid $?)))
             (modeler-constants (sentinel-symbol ?target-pid))
        )
    )
    ?o <- (open-start-interval 
                (category "UIComponent")
                (thread ?autoThreadBinding_)
                (time ?autoStartTimeBinding_)
                (subsystem "com.lapse.UIComponent")
                (message$ ?component-name)
                (identifier ?autoSignpostIdentifier_)
                (process ?autoProcessBinding_)
                (name "ComponentBuilder")
                (rule-system-serial 1)
                (layout-id ?layout-id_)
                (layout-category $?autoLayoutCat_)
                (output-table ?autoOutput_)
    )
    ?f <- (os-signpost 
        (event-type "End")
        (subsystem "com.lapse.UIComponent")
        (message$ "Complete")
        (identifier ?autoSignpostIdentifier_)
        (name "ComponentBuilder")
        (category "UIComponent")
        (time ?autoEndTimeBinding_&~0)
    )
    (not (consumed-end (end-fact ?f) (output-table ?autoOutput_) (rule-system-serial 1)))
    (matched-interval (rule-system-serial 1) (open-fact ?o) (end-fact ?f) (output-table ?autoOutput_))

    =>

    (retract ?o)
    (assert (consumed-end (end-fact ?f) (output-table ?autoOutput_) (rule-system-serial 1)))
    (close-layout-lane-reservation ?layout-id_ $?autoLayoutCat_)
    (create-new-row ?autoOutput_)

    (set-column start ?autoStartTimeBinding_)
    (set-column duration (- ?autoEndTimeBinding_ ?autoStartTimeBinding_))
    (set-column layout-qualifier ?layout-id_)
    (set-column component-name-event ?component-name)
)

(defrule RECORDER::speculation-for-system-1
    (speculate (event-horizon ?autoHorizonBinding_))
    (open-start-interval (output-table ?autoOutput_) (layout-id ?autoLayoutID_)
                         (category "UIComponent")
                         (thread ?autoThreadBinding_)
                         (time ?autoStartTimeBinding_)
                         (subsystem "com.lapse.UIComponent")
                         (message$ ?component-name)
                         (identifier ?autoSignpostIdentifier_)
                         (process ?autoProcessBinding_)
                         (name "ComponentBuilder")
                         (rule-system-serial 1)
    )
    =>
    (create-new-row ?autoOutput_)
    (set-column start ?autoStartTimeBinding_)
    (set-column duration (- ?autoHorizonBinding_ ?autoStartTimeBinding_))
    (set-column layout-qualifier ?autoLayoutID_)
    (set-column component-name-event ?component-name)
    (if (< ?autoStartTimeBinding_ ?*modeler-horizon*) then (bind ?*modeler-horizon* ?autoStartTimeBinding_))
)

(defrule MODELER::signpost-match-detected-1
    (logical ?o <- (open-start-interval (time ?start) (rule-system-serial 1) (thread ?thread) (process ?process)
                                        (name ?name) (identifier ?signpost-id) (output-table ?autoOutput_)
          )
    (or
      (and ?f <- (os-signpost (time ?end&~?start) (name ?name) (identifier ?signpost-id) (event-type "End") (scope "Thread") (thread ?thread))
           (not (open-start-interval (time ?other-start&:(> ?other-start ?start)) (name ?name) (identifier ?signpost-id) (rule-system-serial 1)
                                     (output-table ?autoOutput_) (thread ?thread)))
      )
      (and ?f <- (os-signpost (time ?end&~?start) (name ?name) (identifier ?signpost-id) (event-type "End") (scope "Process"|"") (process ?process))
           (not (open-start-interval (time ?other-start&:(> ?other-start ?start)) (name ?name) (identifier ?signpost-id) (rule-system-serial 1)
                                     (output-table ?autoOutput_) (process ?proc)))
      )
      (and ?f <- (os-signpost (time ?end&~?start) (name ?name) (identifier ?signpost-id) (event-type "End") (scope "System"))
           (not (open-start-interval (time ?other-start&:(> ?other-start ?start)) (name ?name) (identifier ?signpost-id) (rule-system-serial 1)
                                     (output-table ?autoOutput_)))
      )
    ))
    (not (matched-interval (rule-system-serial 1) (open-fact ?o) (output-table ?autoOutput_)))
    =>
    (assert (matched-interval (rule-system-serial 1) (open-fact ?o) (end-fact ?f) (output-table ?autoOutput_)))
)

(defrule MODELER::start-interval-for-system-2 
    (table-attribute (table-id ?autoOutput_) (has schema component-render-schema))
    (table (table-id ?autoOutput_) (side append))
    (or (table-attribute (table-id ?autoOutput_) (has target-pid ?target-pid))
        (and (not (table-attribute (table-id ?autoOutput_) (has target-pid $?)))
             (modeler-constants (sentinel-symbol ?target-pid))
        )
    )
    (os-signpost 
        (event-type "Begin")
        (category "UIComponent")
        (thread ?autoThreadBinding_)
        (time ?autoStartTimeBinding_&~0)
        (subsystem "com.lapse.UIComponent")
        (message$ "Render:" ?component-name)
        (identifier ?autoSignpostIdentifier_)
        (process ?autoProcessBinding_)
        (name "ComponentEngine")
    )

    =>

    (bind ?autoLayoutCat_ (create$ global ?autoOutput_))
    (assert (open-start-interval 
               (category "UIComponent")
               (thread ?autoThreadBinding_)
               (time ?autoStartTimeBinding_)
               (subsystem "com.lapse.UIComponent")
               (message$ ?component-name)
               (identifier ?autoSignpostIdentifier_)
               (process ?autoProcessBinding_)
               (name "ComponentEngine")
               (rule-system-serial 2)
               (output-table ?autoOutput_)
               (layout-category ?autoLayoutCat_)
               (layout-id (reserve-layout-lane ?autoLayoutCat_))
            ))
)

(defrule RECORDER::end-interval-for-system-2 
    (table (table-id ?autoOutput_) (side append))
    (or (table-attribute (table-id ?autoOutput_) (has target-pid ?target-pid))
        (and (not (table-attribute (table-id ?autoOutput_) (has target-pid $?)))
             (modeler-constants (sentinel-symbol ?target-pid))
        )
    )
    ?o <- (open-start-interval 
                (category "UIComponent")
                (thread ?autoThreadBinding_)
                (time ?autoStartTimeBinding_)
                (subsystem "com.lapse.UIComponent")
                (message$ ?component-name)
                (identifier ?autoSignpostIdentifier_)
                (process ?autoProcessBinding_)
                (name "ComponentEngine")
                (rule-system-serial 2)
                (layout-id ?layout-id_)
                (layout-category $?autoLayoutCat_)
                (output-table ?autoOutput_)
    )
    ?f <- (os-signpost 
        (event-type "End")
        (subsystem "com.lapse.UIComponent")
        (message$ "Rendered")
        (identifier ?autoSignpostIdentifier_)
        (name "ComponentEngine")
        (category "UIComponent")
        (time ?autoEndTimeBinding_&~0)
    )
    (not (consumed-end (end-fact ?f) (output-table ?autoOutput_) (rule-system-serial 2)))
    (matched-interval (rule-system-serial 2) (open-fact ?o) (end-fact ?f) (output-table ?autoOutput_))

    =>

    (retract ?o)
    (assert (consumed-end (end-fact ?f) (output-table ?autoOutput_) (rule-system-serial 2)))
    (close-layout-lane-reservation ?layout-id_ $?autoLayoutCat_)
    (create-new-row ?autoOutput_)

    (set-column start ?autoStartTimeBinding_)
    (set-column duration (- ?autoEndTimeBinding_ ?autoStartTimeBinding_))
    (set-column layout-qualifier ?layout-id_)
    (set-column rendered-name-event ?component-name)
)

(defrule RECORDER::speculation-for-system-2
    (speculate (event-horizon ?autoHorizonBinding_))
    (open-start-interval (output-table ?autoOutput_) (layout-id ?autoLayoutID_)
                         (category "UIComponent")
                         (thread ?autoThreadBinding_)
                         (time ?autoStartTimeBinding_)
                         (subsystem "com.lapse.UIComponent")
                         (message$ ?component-name)
                         (identifier ?autoSignpostIdentifier_)
                         (process ?autoProcessBinding_)
                         (name "ComponentEngine")
                         (rule-system-serial 2)
    )
    =>
    (create-new-row ?autoOutput_)
    (set-column start ?autoStartTimeBinding_)
    (set-column duration (- ?autoHorizonBinding_ ?autoStartTimeBinding_))
    (set-column layout-qualifier ?autoLayoutID_)
    (set-column rendered-name-event ?component-name)
    (if (< ?autoStartTimeBinding_ ?*modeler-horizon*) then (bind ?*modeler-horizon* ?autoStartTimeBinding_))
)

(defrule MODELER::signpost-match-detected-2
    (logical ?o <- (open-start-interval (time ?start) (rule-system-serial 2) (thread ?thread) (process ?process)
                                        (name ?name) (identifier ?signpost-id) (output-table ?autoOutput_)
          )
    (or
      (and ?f <- (os-signpost (time ?end&~?start) (name ?name) (identifier ?signpost-id) (event-type "End") (scope "Thread") (thread ?thread))
           (not (open-start-interval (time ?other-start&:(> ?other-start ?start)) (name ?name) (identifier ?signpost-id) (rule-system-serial 2)
                                     (output-table ?autoOutput_) (thread ?thread)))
      )
      (and ?f <- (os-signpost (time ?end&~?start) (name ?name) (identifier ?signpost-id) (event-type "End") (scope "Process"|"") (process ?process))
           (not (open-start-interval (time ?other-start&:(> ?other-start ?start)) (name ?name) (identifier ?signpost-id) (rule-system-serial 2)
                                     (output-table ?autoOutput_) (process ?proc)))
      )
      (and ?f <- (os-signpost (time ?end&~?start) (name ?name) (identifier ?signpost-id) (event-type "End") (scope "System"))
           (not (open-start-interval (time ?other-start&:(> ?other-start ?start)) (name ?name) (identifier ?signpost-id) (rule-system-serial 2)
                                     (output-table ?autoOutput_)))
      )
    ))
    (not (matched-interval (rule-system-serial 2) (open-fact ?o) (output-table ?autoOutput_)))
    =>
    (assert (matched-interval (rule-system-serial 2) (open-fact ?o) (end-fact ?f) (output-table ?autoOutput_)))
)

