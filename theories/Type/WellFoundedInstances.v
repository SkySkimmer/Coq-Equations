Set Warnings "-notation-overridden".
From Equations.Type Require Import Loader Relation WellFounded.
Import Id_Notations.

Section Lt.
  Inductive le : nat -> nat -> Set :=
    | le_0 x : le 0 x
    | le_S {x y} : le x y -> le (S x) (S y).

  Definition lt x y := le (S x) y.

  Lemma le_eq_lt x y : le x y -> (x = y) + (lt x y).
  Proof.
    induction 1. destruct x. left; constructor.
    right; constructor. constructor.
    dependent elimination IHle as [inl id_refl|inr Hlt].
    left; constructor. right; now constructor.
  Defined.

  Global Instance lt_wf : WellFounded lt.
  Proof.
    intros x. induction x.
    constructor. intros y Hy. depelim Hy.
    constructor. intros y Hy.
    dependent elimination Hy as [@le_S y x Hle].
    apply le_eq_lt in Hle.
    dependent elimination Hle as [inl id_refl|inr Hlt].
    assumption.
    destruct IHx. now apply a.
  Defined.

  Lemma lt_n_Sn n : lt n (S n).
  Proof.
    constructor.
    induction n; now constructor.
  Defined.
End Lt.

#[global]
Hint Resolve lt_n_Sn : rec_decision.

(** Define non-dependent lexicographic products *)

Import Sigma_Notations.
Local Open Scope equations_scope.

Section Lexicographic_Product.

  Variable A : Type.
  Variable B : Type.
  Variable leA : relation A.
  Variable leB : relation B.

  Inductive lexprod : A * B -> A * B -> Type :=
    | left_lex :
      forall {x x':A} {y:B} {y':B},
        leA x x' -> lexprod (x, y) (x', y')
    | right_lex :
      forall {x:A} {y y':B},
        leB y y' -> lexprod (x, y) (x, y').

  Lemma acc_A_B_lexprod :
    forall x:A, Acc leA x -> (well_founded leB) ->
                forall y:B, Acc leB y -> Acc lexprod (x, y).
  Proof.
    induction 1 as [x _ IHAcc]; intros H2 y.
    induction 1 as [x0 H IHAcc0].
    apply Acc_intro.
    destruct y as [x2 y1]; intro Hlex.
    depelim Hlex. apply IHAcc; auto with relations.
    now apply IHAcc0.
  Defined.

  Theorem wf_lexprod :
    well_founded leA ->
    well_founded leB -> well_founded lexprod.
  Proof.
    intros wfA wfB; unfold well_founded.
    destruct x.
    apply acc_A_B_lexprod; auto with relations; intros.
  Defined.

End Lexicographic_Product.

#[export]
Instance wellfounded_lexprod A B R S `(wfR : WellFounded A R, wfS : WellFounded B S) :
  WellFounded (lexprod A B R S) := wf_lexprod A B R S wfR wfS.

#[global]
Hint Constructors lexprod : rec_decision.
