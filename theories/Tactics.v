(**********************************************************************)
(* Equations                                                          *)
(* Copyright (c) 2009-2019 Matthieu Sozeau <matthieu.sozeau@inria.fr> *)
(**********************************************************************)
(* This file is distributed under the terms of the                    *)
(* GNU Lesser General Public License Version 2.1                      *)
(**********************************************************************)

(** Tactics supporting equations *)

Require Import Coq.Program.Tactics.
Require Export Equations.Init.
Require Import Equations.Signature.

Import Sigma_Notations.
Local Open Scope equations_scope.

Ltac is_ground_goal :=
  match goal with
    |- ?T => is_ground T
  end.

(** Try to find a contradiction. *)

(* Hint Extern 10 => is_ground_goal ; progress (elimtype False). *)

(** We will use the [block] definition to separate the goal from the
   equalities generated by the tactic. *)

Definition block := tt.

Ltac intros_until_block :=
  match goal with
    |- let _ := block in _ => intros _
  | |- _ => try (intro; intros_until_block)
  end.

Ltac block_goal :=
  match goal with
    | [ |- ?T ] => change (let _ := block in T)
  end.

Ltac unblock_goal := unfold block in *; cbv zeta.

Ltac blocked t := block_goal ; t ; unblock_goal.

Definition hide_pattern {A : Type} (t : A) := t.

Definition add_pattern {B} (A : Type) (b : B) := A.

Ltac add_pattern t :=
  match goal with
    |- ?T => change (add_pattern T t)
  end.

(** To handle sections, we need to separate the context in two parts:
   variables introduced by the section and the rest. We introduce a dummy variable
   between them to indicate that. *)

CoInductive end_of_section := the_end_of_the_section.

Ltac set_eos := let eos := fresh "eos" in
  assert (eos:=the_end_of_the_section).

Ltac with_eos_aux tac :=
  match goal with
   [ H : end_of_section |- _ ] => tac H
  end.

Ltac with_eos tac orelse :=
  with_eos_aux tac + (* No section variables *) orelse.

Ltac clear_nonsection :=
  repeat match goal with
    [ H : ?T |- _ ] =>
    match T with
      end_of_section => idtac
    | _ => clear H
    end
  end.


(** We have a specialized [reverse_local] tactic to reverse the goal until the begining of the
   section variables *)

Ltac reverse_local :=
  match goal with
    | [ H : ?T |- _ ] =>
      match T with
        | end_of_section => idtac
        | _ => revert H ; reverse_local
      end
    | _ => idtac
  end.

Ltac clear_local :=
  match goal with
    | [ H : ?T |- _ ] =>
      match T with
        | end_of_section => idtac
        | _ => clear H ; clear_local
      end
    | _ => idtac
  end.

(** The [pi] tactic solves an equality between applications of the same function *)

Ltac pi := repeat progress (f_equal || reflexivity).

(** Internally used constants *)

Register block as equations.internal.block.
Register hide_pattern as equations.internal.hide_pattern.
Register add_pattern as equations.internal.add_pattern.
Register the_end_of_the_section as equations.internal.the_end_of_the_section.
Register end_of_section as equations.internal.end_of_section.

(* Generic NoConfusion derivation *)
(** Apply [noConfusion] on a given hypothsis. *)

(** Used by the [Derive NoConfusion] command. *)

Ltac destruct_sigma id :=
  match type of id with
    @sigma ?A ?P => let idx := fresh "idx" in
                   destruct id as [idx id];
                     repeat destruct_sigma idx; simpl in id

  | _ => idtac
  end.

Ltac simp_sigmas := repeat destruct_one_sigma ; simpl in *.

Ltac eapply_hyp :=
  match goal with
    [ H : _ |- _ ] => eapply H
  end.

Ltac destruct_tele_eq H :=
  match type of H with
    ?x = ?y =>
    let rhs := fresh in
    set (rhs := y) in *; pattern sigma rhs; clearbody rhs;
    destruct H; simpl
  end.

(** Used by funelim *)

Ltac apply_args c elimc k :=
    match c with
    | _ ?a ?b ?c ?d ?e ?f ?g ?h ?i ?j ?k ?l ?m => k uconstr:(elimc a b c d e f g h i j k l m)
    | _ ?a ?b ?c ?d ?e ?f ?g ?h ?i ?j ?k ?l => k uconstr:(elimc a b c d e f g h i j k l)
    | _ ?a ?b ?c ?d ?e ?f ?g ?h ?i ?j ?k => k uconstr:(elimc a b c d e f g h i j k)
    | _ ?a ?b ?c ?d ?e ?f ?g ?h ?i ?j => k uconstr:(elimc a b c d e f g h i j)
    | _ ?a ?b ?c ?d ?e ?f ?g ?h ?i => k uconstr:(elimc a b c d e f g h i)
    | _ ?a ?b ?c ?d ?e ?f ?g ?h => k uconstr:(elimc a b c d e f g h)
    | _ ?a ?b ?c ?d ?e ?f ?g => k uconstr:(elimc a b c d e f g)
    | _ ?a ?b ?c ?d ?e ?f => k uconstr:(elimc a b c d e f)
    | _ ?a ?b ?c ?d ?e => k uconstr:(elimc a b c d e)
    | _ ?a ?b ?c ?d => k uconstr:(elimc a b c d)
    | _ ?a ?b ?c => k uconstr:(elimc a b c)
    | _ ?a ?b => k uconstr:(elimc a b)
    | _ ?a => k uconstr:(elimc a)
    end.
