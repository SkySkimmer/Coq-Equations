(** * General recursive functions

  This file explores a way to formalize general recursive functions
  without worrying about termination proofs, counters or monads.

  The definitions are actually defined by well-founded recursion on the
  total relation (which isn't well-founded).  Using fueling of the
  accessibility proof, we can however compute with these definitions
  inside Coq and reason on them independently of the termination
  proof. *)


(* begin hide *)
(** printing elimination %\coqdoctac{elimination}% *)
(** printing noconf %\coqdoctac{noconf}% *)
(** printing simp %\coqdoctac{simp}% *)
(** printing by %\coqdockw{by}% *)
(** printing rec %\coqdockw{rec}% *)
(** printing Coq %\Coq{}% *)
(** printing funelim %\coqdoctac{funelim}% *)
(** printing Derive %\coqdockw{Derive}% *)
(** printing Signature %\coqdocclass{Signature}% *)
(** printing Subterm %\coqdocclass{Subterm}% *)
(** printing NoConfusion %\coqdocclass{NoConfusion}% *)
Require Import Equations.Equations.
Require Import ZArith.
Require Import Program.
Require Import Psatz.
Require Import NPeano.
Require Import Nat.
Require Import Coq.Vectors.VectorDef.
Require Import Relations.
(* end hide *)

(** The total relation. *)
Definition total_relation {A : Type} : A -> A -> Prop := fun x y => True.

(** We assume an inconsistent axiom here, one should be added function per function. *)
Axiom wf_total_init : forall {A}, WellFounded (@total_relation A).
Remove Hints wf_total_init : typeclass_instances.

(** We fuel it with some Acc_intro constructors so that definitions relying on it
    can unfold a fixed number of times still. *)
Instance wf_total_init_compute : forall {A}, WellFounded (@total_relation A).
  exact (fun A => Acc_intro_generator 10 wf_total_init).
Defined.

(** Now we define an obviously non-terminating function. *)
Equations? nonterm (n : nat) : nat by wf n (@total_relation nat) :=
  nonterm 0 := 0;
  nonterm (S n) := S (nonterm (S n)).
Proof.
  (* Every pair of arguments is in the total relation: so
     [total_relation (S n) (S n)] *)
  constructor.
Defined.

  (** The automation has a little trouble here as it assumes
      well-founded definitions implicitely.  We show the second
      equation: [nonterm (S n) = S (nonterm (S n))] using the
      unfolding equation. *)
  Next Obligation.
    now rewrite nonterm_unfold_eq at 1.
  Defined.

  (* Note this is a dangerous rewrite rule, so we should remove it from the hints *)
  (* Print Rewrite HintDb nonterm. *)

  (** Make nonterm transparent anyway so we can compute with it *)
  Transparent nonterm.

(** We can compute with it (for closed natural numbers) *)
Fixpoint at_least_five (n : nat) : bool :=
  match n with
  | S (S (S (S (S x)))) => true
  | _ => false
  end.

(** Indeed it unfolds enough so that [at_least_five] gives back a result. *)
Example check_10 := eq_refl : at_least_five (nonterm 10) = true.
Example check_0 := eq_refl : at_least_five (nonterm 0) = false.

(** The elimination principle completely abstracts away from the
    termination argument as well *)
Lemma nonterm_ge n : n <= nonterm n.
Proof.
  funelim (nonterm n).
  reflexivity.
  omega.
Defined.
