(**********************************************************************)
(* Equations                                                          *)
(* Copyright (c) 2009-2019 Matthieu Sozeau <matthieu.sozeau@inria.fr> *)
(**********************************************************************)
(* This file is distributed under the terms of the                    *)
(* GNU Lesser General Public License Version 2.1                      *)
(**********************************************************************)

(** Instances of [NoConfusion] for the standard datatypes. To be used by 
   [equations] when it needs applications of injectivity or discrimination
   on some equation. *)

Require Import Coq.Program.Tactics Bvector List.
From Equations Require Import Init Signature Tactics.
From Equations.Prop Require Import Classes EqDec Constants.
Require Export Equations.Prop.DepElim.

Ltac noconf H ::=
  blocked ltac:(noconf_ref H; simplify_dep_elim) ; auto 3.

(** Used by the [Derive NoConfusion] command. *)


Ltac destruct_sigma id :=
  match type of id with
    @sigma ?A ?P => let idx := fresh "idx" in
                   destruct id as [idx id];
                     repeat destruct_sigma idx; simpl in id
                                                         
  | _ => idtac
  end.

Ltac solve_noconf_prf := intros;
  on_last_hyp ltac:(fun id => destruct id) ; (* Subtitute a = b *)
  on_last_hyp ltac:(fun id =>
                      destruct_sigma id;
                      elim id) ; (* Destruct the inductive object a *)
  constructor.

Ltac destruct_tele_eq H :=
  match type of H with
    ?x = ?y =>
    let rhs := fresh in
    set (rhs := y) in *; pattern sigma rhs; clearbody rhs;
    destruct H; simpl
  end.

Ltac solve_noconf_inv_eq a b :=
  destruct_sigma a; destruct_sigma b;
  destruct a ; depelim b; simpl in * |-;
  on_last_hyp ltac:(fun id => hnf in id; destruct_tele_eq id || destruct id);
  solve [constructor].

Ltac solve_noconf_inv := intros;
  match goal with
    |- ?R ?a ?b => destruct_sigma a; destruct_sigma b; 
                   destruct a ; depelim b; simpl in * |-;
                 on_last_hyp ltac:(fun id => hnf in id; destruct_tele_eq id || destruct id);
                 solve [constructor]
  | |- @eq _ (?f ?a ?b _) _ => solve_noconf_inv_eq a b
  | |- @Id _ (?f ?a ?b _) _ => solve_noconf_inv_eq a b
  end.

Ltac solve_noconf_inv_equiv :=
  intros;
  (* Subtitute a = b *)
  on_last_hyp ltac:(fun id => destruct id) ;
  (* Destruct the inductive object a *)
  on_last_hyp ltac:(fun id => destruct_sigma id; elim id) ;
  simpl; constructor.

Ltac solve_noconf := simpl; intros;
    match goal with
      [ H : @eq _ _ _ |- @eq _ _ _ ] => try solve_noconf_inv_equiv
    | [ H : @eq _ _ _ |- _ ] => try solve_noconf_prf
    | [ |- @eq _ _ _ ] => try solve_noconf_inv
    | [ H : @Id _ _ _ |- @Id _ _ _ ] => try solve_noconf_inv_equiv
    | [ H : @Id _ _ _ |- _ ] => try solve_noconf_prf
    | [ |- @Id _ _ _ ] => try solve_noconf_inv
    end.

Ltac solve_noconf_hom_inv_eq a b :=
  destruct_sigma a; destruct_sigma b;
  destruct a ; depelim b; simpl in * |-;
  on_last_hyp ltac:(fun id => hnf in id; destruct_tele_eq id || depelim id);
  solve [constructor || simpl_equations; constructor].

Ltac solve_noconf_hom_inv := intros;
  match goal with
  | |- @eq _ (?f ?a ?b _) _ => solve_noconf_hom_inv_eq a b
  | |- @Id _ (?f ?a ?b _) _ => solve_noconf_hom_inv_eq a b
  | |- ?R ?a ?b =>
    destruct_sigma a; destruct_sigma b;
    destruct a ; depelim b; simpl in * |-;
    on_last_hyp ltac:(fun id => hnf in id; destruct_tele_eq id || depelim id);
    solve [constructor || simpl_equations; constructor]
  end.

Ltac solve_noconf_hom_inv_equiv :=
  intros;
  (* Subtitute a = b *)
  on_last_hyp ltac:(fun id => destruct id) ;
  (* Destruct the inductive object a using dependent elimination
     to handle UIP cases. *)
  on_last_hyp ltac:(fun id => destruct_sigma id; depelim id) ;
  simpl; simpl_equations; constructor.

Ltac solve_noconf_hom := simpl; intros;
    match goal with
      [ H : @eq _ _ _ |- @eq _ _ _ ] => try solve_noconf_hom_inv_equiv
    | [ H : @eq _ _ _ |- _ ] => try solve_noconf_prf
    | [ |- @eq _ _ _ ] => try solve_noconf_hom_inv
    | [ H : @Id _ _ _ |- @Id _ _ _ ] => try solve_noconf_hom_inv_equiv
    | [ H : @Id _ _ _ |- _ ] => try solve_noconf_prf
    | [ |- @Id _ _ _ ] => try solve_noconf_hom_inv
    end.

(** Simple of parameterized inductive types just need NoConfusion. *)
Derive NoConfusion for unit bool nat option sum Datatypes.prod list sigT sig.

(* FIXME should be done by the derive command *)
Extraction Inline noConfusion NoConfusionPackage_nat.


