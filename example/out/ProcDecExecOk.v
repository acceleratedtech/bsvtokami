Require Import Kami.
Require Import Lib.FinNotations.
Require Import Bsvtokami.
Require Import FIFO.
Require Import ProcMemSpec PipelinedProc ProcDecExec.

Set Implicit Arguments.

(*! Specifying, implementing, and verifying a very simple processor !*)

(** You may want to take a look at the code in the following order:
 * - ProcMemSpec.v: the spec of processors and memory systems
 * - PipelinedProc.v: a 3-stage pipelined processor implementation
 * - DecExec.v: a pipeline stage that merges the first two stages,
 *   [decoder] and [executer].
 * - DecExecOk.v (you are here!): correctness of [decexec] in DecExec.v
 * - ProcMemInterm.v: an intermediate 2-stage pipelined processor 
 * - ProcMemOk.v: a complete refinement proof
 *)

(* Here we prove that merging the first two stages ([decoder] and [executer])
 * is correct by providing a refinement from [decexecSep] to [decexec]. *)
Section DecExec.

  Local Definition dataK := Bit ProcMemSpec.DataSz.
  Local Definition instK := Bit ProcMemSpec.InstrSz.

  Variables (dec: ProcMemSpec.Decoder)
            (exec: ProcMemSpec.Executer)
            (tohost: ProcMemSpec.ToHost)
            (pcInit : ConstT (Bit ProcMemSpec.PgmSz))
            (pgm : RegFile).


  Local Definition decexecSep : Modules := (Empty'modules (ProcDecExec.mkDecExecSep  "decexec" pgm dec exec tohost)).
  Lemma decexecSep_PhoasWf: ModPhoasWf decexecSep.
  Proof. kequiv. Qed.
  Lemma decexecSep_RegsWf: ModRegsWf decexecSep.
  Proof. kvr. Qed.
  Hint Resolve decexecSep_PhoasWf decexecSep_RegsWf.

  Hint Unfold decexecSep: ModuleDefs.

  Local Definition decexecSepInl: {m: Modules & decexecSep <<== m}.
  Proof.
    kinline_refine decexecSep.
  Defined.

  Local Definition decexecSepInl := decexecSepInl dec exec pcInit pgmInit.

  (* What would be good invariants to prove the correctness of stage merging?
   * For two given stages, we usually need to provide relations among states in
   * the two stages and elements in the fifo between them.
   *
   * Here we describe two invariants: the first one [decexec_pc_inv] states a
   * relation between the [pc] value and the fifo element, and the second one
   * [decexec_d2e_inv] states that the fifo element is valid with respect to the
   * current instruction. *)
  Definition decexec_pc_inv
             (pcv: fullType type (SyntaxKind (Bit PgmSz)))
             (d2efullv: fullType type (SyntaxKind Bool))
             (d2eeltv: fullType type (SyntaxKind (Struct D2E))) :=
    d2efullv = true -> pcv = d2eeltv F7 ^+ $1.
  
  Definition decexec_d2e_inv
             (pgmv: fullType type (SyntaxKind (Vector instK PgmSz)))
             (d2efullv: fullType type (SyntaxKind Bool))
             (d2eeltv: fullType type (SyntaxKind (Struct D2E))) :=
    d2efullv = true ->
    let pc := d2eeltv F7 in
    let inst := evalExpr (#pgmv@[#pc])%kami_expr in
    d2eeltv F1 = evalExpr (getOp dec inst) /\
    d2eeltv F2 = evalExpr (getArithOp dec inst) /\
    d2eeltv F3 = evalExpr (getSrc1 dec inst) /\
    d2eeltv F4 = evalExpr (getSrc2 dec inst) /\
    d2eeltv F5 = evalExpr (getDst dec inst) /\
    d2eeltv F6 = evalExpr (getAddr dec inst).

  Record decexec_inv (o: RegsT): Prop :=
    { pcv: fullType type (SyntaxKind (Bit PgmSz));
      Hpcv: M.find "pc"%string o = Some (existT _ _ pcv);
      pgmv: fullType type (SyntaxKind (Vector instK PgmSz));
      Hpgmv: M.find "pgm"%string o = Some (existT _ _ pgmv);
      d2efullv: fullType type (SyntaxKind Bool);
      Hd2efullv: M.find "full.d2e"%string o = Some (existT _ _ d2efullv);
      d2eeltv: fullType type (SyntaxKind (Struct D2E));
      Hd2eeltv: M.find "elt.d2e"%string o = Some (existT _ _ d2eeltv);

      Hpcinv: decexec_pc_inv pcv d2efullv d2eeltv;
      Hdeinv: decexec_d2e_inv pgmv d2efullv d2eeltv
    }.

  (* Make sure to register all invariant-related definitions in the [InvDefs]
   * hint database, in order for Kami invariant-solving tactics to unfold them
   * automatically. *)
  Hint Unfold decexec_pc_inv decexec_d2e_inv: InvDefs.

  (* In order to prove invariants, we need to provide two customized tactics:
   * one is for destructing invariants for the current state
   * ([decexec_inv_dest_tac]), and the other is for constructing invariants for
   * the next state ([decexec_inv_constr_tac]). *)
  Ltac decexec_inv_dest_tac :=
    unfold getRegInits, decexecSepInl, projT1;
    try match goal with
        | [H: decexec_inv _ |- _] => destruct H
        end.

  Ltac decexec_inv_constr_tac :=
    econstructor; intros;
    repeat (kinv_eq; kinv_red; eauto).

  Ltac decexec_inv_tac :=
    decexec_inv_dest_tac; decexec_inv_constr_tac.

  (* Now we are ready to prove the invariant!
   * Thanks to some Kami tactics, the proof will be highly automated. *)
  Lemma decexec_inv_ok':
    forall init n ll,
      init = initRegs (getRegInits (projT1 decexecSepInl)) ->
      Multistep (projT1 decexecSepInl) init n ll ->
      decexec_inv n.
  Proof.
    (* Induction on [Multistep] is the natural choice. *)
    induction 2.
    - (* Our custom destruction-construction tactic is used 
       * for the initial case as well. *)
      decexec_inv_tac; cbn in *; kinv_red.
    - (* [kinvert] is for inverting Kami steps. 
       * It may generate multiple subgoals corresponding to possible steps 
       * by a rule or a method. *)
      kinvert.
      + (* [kinv_dest_custom] is a tactic for proving invariants, and it takes
         * our customized tactic as a parameter. *)
        kinv_dest_custom decexec_inv_tac.
      + kinv_dest_custom decexec_inv_tac.
      + kinv_dest_custom decexec_inv_tac.
      + kinv_dest_custom decexec_inv_tac.
      + kinv_dest_custom decexec_inv_tac.
      + kinv_dest_custom decexec_inv_tac.
      + kinv_dest_custom decexec_inv_tac.
  Qed.

  Lemma decexec_inv_ok:
    forall o,
      reachable o (projT1 decexecSepInl) ->
      decexec_inv o.
  Proof.
    intros; inv H; inv H0.
    eapply decexec_inv_ok'; eauto.
  Qed.

  (* Equipped with invariants, it is time to prove refinement.
   * Following the Kami verification flow, we will use a decomposition theorem.
   * Register and rule mappings are required to use the theorem. *)
  Definition decexec_regMap (r: RegsT): RegsT :=
    (mlet pcv : (Bit PgmSz) <- r |> "pc";
       mlet pgmv : (Vector instK PgmSz) <- r |> "pgm";
       mlet d2efullv : Bool <- r |> "d2e"--"full";
       mlet d2eeltv : (Struct D2E) <- r |> "d2e"--"elt";
       (["pgm" <- existT _ _ pgmv]
        +["pc" <- existT _ (SyntaxKind (Bit PgmSz))
               (if d2efullv then d2eeltv F7 else pcv)])%fmap)%mapping.
  Hint Unfold decexec_regMap: MethDefs.
  
  Definition decexec_ruleMap (o: RegsT): string -> option string :=
    "executeArith" |-> "decexecArith";
      "executeLd" |-> "decexecLd";
      "executeSt" |-> "decexecSt";
      "executeTh" |-> "decexecTh"; ||.
  Hint Unfold decexec_ruleMap: MethDefs.
  
  (* Finally the correctness proof!
   * The proof is highly automated as well, following a typical verification
   * flow and using the Kami tactics.
   *)
  Theorem decexec_ok:
    decexecSep dec exec pcInit pgmInit <<== decexec dec exec pcInit pgmInit.
  Proof.
    (* 1) Inlining: we already have an inlined module. 
     *    Let's use [kinline_refine_left] to substitute the LHS module 
     *    to the inlined one. *)
    kinline_refine_left decexecSepInl.

    (* 2) Decomposition: [kdecompose_nodefs] is mostly used for decomposition;
     *    it requires a target module without any methods. Indeed the module
     *    has no methods, since it is inlined. The tactic takes register and
     *    rule mappings as arguments. *)
    kdecompose_nodefs decexec_regMap decexec_ruleMap.

    (* 3) Simulation: we can add invariants using [kinv_add] and [kinv_add_end]
     *    before proving simulation. [kinvert] is used to invert Kami steps as
     *    well. [kinv_magic_with] is a high-level tactic to prove simulation for
     *    each possible step. It takes custom destruction and construction 
     *    tactics as arguments. For this proof, no construction tactics are
     *    required.
     *)
    kinv_add decexec_inv_ok.
    kinv_add_end.
    kinvert.
    - kinv_magic_with decexec_inv_dest_tac idtac.
    - kinv_magic_with decexec_inv_dest_tac idtac.
    - kinv_magic_with decexec_inv_dest_tac idtac.
    - kinv_magic_with decexec_inv_dest_tac idtac.
    - kinv_magic_with decexec_inv_dest_tac idtac.
  Qed.

End DecExec.
