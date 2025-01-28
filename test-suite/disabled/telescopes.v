From Equations Require Import Equations.
From Stdlib Require Import Utf8.
Set Universe Polymorphism.
Import Sigma_Notations.
Open Scope equations_scope.
Polymorphic
Definition pr1_seq {A} {P : A -> Type} {p q : sigma P} (e : p = q) : p.1 = q.1.
Proof. destruct e. apply eq_refl. Defined.

Require Vector.
Derive NoConfusion for Vector.t.

Notation " 'rew' H 'in' c " := (@eq_rect _ _ _ c _ H) (at level 20).

Definition J {A} {x : A} (P : forall y : A, x = y -> Type)
           (p : P x eq_refl) (y : A) (e : x = y) : P y e.
  destruct e. exact p.
Defined.

Lemma J_on_refl {A} (x y : A) (e : x = y) : J (λ (y : A) _, x = y) eq_refl y e = e.
Proof. destruct e. constructor. Defined.

Definition subst {A : Type} {x : A} {P : A -> Type} {y : A} (e : x = y) (f : P x) : P y :=
  J (fun x _ => P x) f y e.

Definition subst2 {A : Type} {x : A} {P : A -> Type} (f : P x) (y : A) (e : x = y) : P y :=
  J (fun x _ => P x) f y e.

Definition cong@{i j} {A : Type@{i}} {B : Type@{j}} (f : A -> B) {x y : A} (e : x = y) : f x = f y :=
  J@{i j} (fun y _ => f x = f y) (@eq_refl _ (f x)) y e.
(* aka ap *)

Lemma cong_iter {A B C} (f : A -> B) (g : B -> C) (x y : A) (e : x = y) :
  cong g (cong f e) = cong (fun x => g (f x)) e.
Proof. revert y e. refine (J _ _). reflexivity. Qed.

Lemma cong_subst2 {A B C} (f : C -> B) (x y : A) (e : x = y) (z w : A -> C) (p : z x = w x) :
  cong f (subst2 (P:=fun x : A => z x = w x) p y e) =
  subst2 (P := fun x : A => f (z x) = f (w x)) (cong f p) y e.
Proof. revert y e. refine (J _ _). simpl. reflexivity. Defined.
  
Definition congd {A} {B : A -> Type} (f : forall x : A, B x) {x y : A} (p : x = y) :
  subst p (f x) = f y :=
  J (fun y p => subst p (f x) = f y) (@eq_refl _ (f x)) y p.
(* aka apd *)

Notation " 'rew' H 'in' c " := (@subst _ _ _ _ H c) (at level 20).

Notation "p =_{ P ; e } q" := (subst (P:=P) e p = q) (at level 90, format "p  =_{ P ; e }  q").

Definition subst_expl {A : Type} {x : A} {P : A -> Type} {y : A} (e : x = y) (f : P x) : P y :=
  subst e f.
Notation " 'rewP' H 'at' P 'in' c " := (@subst_expl _ _ P _ H c) (at level 20).

Definition Sect {A B : Type} (s : A -> B) (r : B -> A) :=
  forall x : A, r (s x) = x.

(** A typeclass that includes the data making [f] into an adjoin equivalence*)
Set Printing Universes.
Cumulative Class IsEquiv@{i} {A : Type@{i}} {B : Type@{i}} (f : A -> B) := BuildIsEquiv {
  equiv_inv : B -> A ;
  eisretr : Sect equiv_inv f;
  eissect : Sect f equiv_inv;
  eisadj : forall x : A, eisretr (f x) = cong f (eissect x)
}.
Arguments eisretr {A B} f {_} _.
Arguments eissect {A B} f {_} _.
Arguments eisadj {A B} f {_} _.

Record Equiv@{i} (A B : Type@{i}) := { equiv :> A -> B ; is_equiv :> IsEquiv equiv }.
Arguments equiv {A B} e.

Instance Equiv_IsEquiv {A B} (e : Equiv A B) : IsEquiv (equiv e).
Proof. apply is_equiv. Defined.

Definition inv_equiv {A B} (E: Equiv A B) : B -> A :=
  equiv_inv (IsEquiv:=is_equiv _ _ E).

Definition equiv_inv_equiv@{i} {A B : Type@{i}} {E: Equiv A B} (x : A) : inv_equiv _ (equiv E x) = x := eissect _ x.
Definition inv_equiv_equiv@{i} {A B : Type@{i}} {E: Equiv A B} (x : B) : equiv E (inv_equiv _ x) = x := eisretr _ x.
Definition equiv_adj@{i} {A B : Type@{i}} {E: Equiv A B} (x : A)
  : inv_equiv_equiv (equiv E x) = cong (equiv E) (equiv_inv_equiv x)
  := eisadj _ x.

Notation " X <~> Y " := (Equiv X Y) (at level 90, no associativity, Y at next level).

Definition equiv_id A : A <~> A.
Proof.
  intros.
  refine {| equiv a := a |}.
  unshelve refine {| equiv_inv e := e |}.
  - red. reflexivity.
  - red; intros. reflexivity.
  - intros. simpl. reflexivity.
Defined.

Axiom axiom_triangle : forall {A : Prop}, A.

Definition equiv_sym {A B} : A <~> B -> B <~> A.
Proof.
  intros.
  refine {| equiv a := inv_equiv X a |}.
  unshelve refine {| equiv_inv e := equiv X e |}.
  - red; intros. apply eissect.
  - red; intros. apply eisretr.
  - intros x. simpl. destruct X. simpl. unfold inv_equiv. simpl.
    apply axiom_triangle.
Defined.

(* Unset Equations OCaml Splitting. *)
(* BUG *)
(* Equations tel_eq (Δ : Tel) (t s : Tuple Δ) : Type :=  *)
(* tel_eq nil nil nil := unit; *)
(* tel_eq (consTel A f) (cons t ts) (cons s ss) := *)
(*   sigma (t = s) (fun e : t = s => tel_eq (f s) (rewP e at fun x => Tuple (f x) in ts) ss). *)
Set Equations Transparent.

Set Refolding Reduction.

Ltac rewrite_change c :=
  match type of c with
    ?foo = ?bar => change foo with bar in *
  end.
Set Printing Universes.

Arguments sigmaI {A} {B} pr1 pr2.

Section pathsigmauncurried.
  Universe i.
Equations path_sigma_uncurried {A : Type@{i}} {P : A -> Type@{i}} (u v : sigma@{i} A P)
  (pq : sigma@{Set} _ (fun p => subst p u.2 = v.2))
  : u = v :=
path_sigma_uncurried (sigmaI _ u1 u2) (sigmaI _ ?(u1) ?(u2)) (sigmaI _ eq_refl eq_refl) :=
  eq_refl.
End pathsigmauncurried.


Definition pr1_path@{i} {A : Type@{i}} {P : A -> Type@{i}} {u v : sigma@{i} A P} (p : u = v)
: u.1 = v.1
  := cong@{i i} (@pr1 _ _) p.

Notation "p ..1" := (pr1_path p) (at level 3).

Definition pr2_path@{i} {A : Type@{i}} `{P : A -> Type@{i}} {u v : sigma A P} (p : u = v)
: rew (p..1) in u.2 = v.2.
  destruct p. apply eq_refl.
Defined.

Notation "p ..2" := (pr2_path p) (at level 3).

Definition eta_path_sigma_uncurried@{i} {A : Type@{i}} {P : A -> Type@{i}} {u v : sigma A P}
           (p : u = v) : path_sigma_uncurried _ _ (sigmaI@{i} p..1 p..2) = p.
  destruct p. apply eq_refl.
Defined.

Section pathsigma.
  Universe i.
  Equations path_sigma {A : Type@{i}} {P : A -> Type@{i}} {u v : sigma A P}
            (p : u.1 = v.1) (q : rew p in u.2 = v.2)
    : u = v :=
    path_sigma (u:=sigmaI _ _ _) (v:=sigmaI _ _ _) eq_refl eq_refl := eq_refl.
End pathsigma.

Definition eta_path_sigma A `{P : A -> Type} {u v : sigma A P} (p : u = v)
: path_sigma (p..1) (p..2) = p
  := eta_path_sigma_uncurried p.

Instance path_sigma_equiv@{i} {A : Type@{i}} (P : A -> Type@{i}) (u v : sigma A P):
  IsEquiv@{i} (path_sigma_uncurried u v).
  unshelve refine (BuildIsEquiv _ _ _ _ _ _ _).
  - exact (fun r => &(r..1 & r..2)).
  - intro. apply eta_path_sigma_uncurried.
  - destruct u, v; intros [p q]; simpl in *.
    destruct p. simpl in *. destruct q.
    reflexivity.
  - destruct u, v; intros [p q]; simpl in *;
    destruct p. simpl in *. destruct q; simpl in *.
    apply eq_refl.
Defined.

Definition path_sigma_equivalence@{i} {A : Type@{i}} (P : A -> Type@{i}) (u v : sigma A P):
  sigma@{i} _ (fun p : u.1 = v.1 => u.2 =_{P;p} v.2) <~> u = v.
Proof.
  exists (path_sigma_uncurried u v).
  apply path_sigma_equiv.
Defined.

Module Telescopes.

  Cumulative Inductive t@{i} : Type :=
  | inj : Type@{i} -> t
  | ext (A : Type@{i}) : (A -> t) -> t.
  Notation Tel := t.
  
  Delimit Scope telescope with telescope.
  Notation "[]" := (inj unit) : telescope.
  Bind Scope telescope with t.

  Example onetel :=
    ext Type (fun A => ext nat (fun n => inj (vector A n))).
  
  Fixpoint telescope@{i} (T : Tel@{i}) : Type@{i} :=
    match T with
    | inj A => A
    | ext A f => sigma A (fun x => telescope (f x))
    end.

  Coercion telescope : Tel >-> Sortclass.

  (** Telescopic equality: an iterated sigma of dependent equalities *)
  Fixpoint eq@{i} (Δ : Tel@{i}) : forall (t s : Δ), Tel@{i} :=
    match Δ return forall t s : Δ, Tel@{i} with
    | inj A => fun a b => inj@{i} (a = b)
    | ext A f => fun a b =>
                   ext (a.1 = b.1) (fun e => eq (f b.1) (rew e in a.2) b.2)
    end.
  Reserved Notation "x == y" (at level 70, y at next level, no associativity).
  Reserved Notation "x =={ Δ } y" (at level 70, y at next level, no associativity,
                                   format "x  =={ Δ } '/ '  y").
  Infix "==" := (eq _) : telescope.

  Definition eq_expl := eq.
  Infix "=={ Δ }" := (eq_expl Δ) : telescope.

  Equations refl {Δ : Tel} (t : telescope Δ) : eq Δ t t :=
    refl (Δ:=inj A) a := eq_refl;
    refl (Δ:=ext A f) (sigmaI t ts) := &(eq_refl & refl ts).

  Local Open Scope telescope.
  
  Equations J {Δ : Tel} (r : Δ) (P : forall s : Δ, eq Δ r s -> Type)
            (p : P r (refl r)) (s : Δ) (e : eq _ r s) : P s e :=
    J (Δ:=inj A) a P p b e := J P p b e;
    J (Δ:=ext A f) a P p b e :=
(* (sigmaI _ r rs) P p (sigmaI _ s ss) (sigmaI _ e es) :=                                 *)
     J (x:=a.1)
       (fun (s' : A) (e' : a.1 = s') =>
        forall (ss' : f s') (es' : eq (f s') (rewP e' at f in a.2) ss'),
          P &(s' & ss') &(e' & es'))
       (fun ss' es' =>
          J _ (fun ss'' (es'' : eq (f a.1) a.2 ss'') => P &(a.1 & ss'') &(eq_refl & es''))
              p ss' es')
       b.1 e.1 b.2 e.2.

  Lemma J_refl {Δ : Tel} (r : Δ) (P : forall s : Δ, eq Δ r s -> Type) 
          (p : P r (refl r)) : J r P p r (refl r) = p.
  Proof.
    induction Δ. simpl. reflexivity.
    simpl. destruct r. refine (H pr1 pr2 _ _).
  Defined.

  Lemma J_on_refl {Δ : Tel} (x y : Δ) (e : x == y) :
    J _ (λ (y : Δ) _, x == y) (refl _) y e = e.
  Proof. revert y e. refine (J _ _ _). refine (J_refl _ _ _). Defined.

  Equations subst {Δ : Tel} (P : Δ -> Type) {u v : Δ} (e : u =={Δ} v) (p : P u) : P v :=
    subst (v:=v) (u:=u) P e p := J u (fun v _ => P v) p v e.

  Definition cong@{i j k} {Δ : Tel@{i}} {T : Type@{j}} (f : Δ -> T) (u v : Δ) (e : u =={Δ} v) : f u = f v :=
    J@{j k i} u (fun v _ => f u = f v) (@eq_refl T (f u)) v e.

  Notation "p ==_{ P ; e } q" := (subst P e p = q) (at level 70, q at next level, no associativity) : telescope.

  Reserved Notation "x =={ T ; e } y" (at level 70, y at next level, no associativity, only parsing,
                                   format "x  =={ T ; e } '/ '  y").
  Notation "x =={ P ; e } y" := (subst P e x == y) (only parsing) : telescope.

  Lemma eq_over_refl {Δ : Tel} {T} (f : forall x : Δ, T x) (u : Δ) :
    f u ==_{T;refl u} f u.
  Proof.
    unfold subst. refine (J_refl _ _ _).
  Defined.

  Equations dcong {Δ : Tel} {T} (f : forall x : Δ, T x) (u v : Δ) (e : u =={Δ} v) :
    f u ==_{T;e} f v :=
    dcong (T:=T) f u v e := J u (fun v e => f u ==_{T;e} f v) (eq_over_refl f u) v e.

  Equations cong_tel {Δ : Tel} {Γ : Tel}
            (f : Δ -> Γ) {u v : Δ} (e : u =={Δ} v) : f u =={Γ} f v :=
    cong_tel (v:=v) f e := J _ (fun v _ => f _ =={_} f v) (refl _) v e.

  Equations dcong_tel {Δ : Tel} {T : Δ -> Tel}
            (f : forall x : Δ, T x) {u v : Δ} (e : u =={Δ} v) :
    f u =={T;e} f v :=
    dcong_tel f e := J _ (fun v e => f _ =={_;e} f v) _ _ e.
  Next Obligation.
    clear. unfold subst. rewrite J_refl. apply refl.
  Defined.
    
  Notation "'tele' x .. y 'in' z " := (@ext _ (fun x => .. (@ext _ (fun y => inj z)) ..))
  (at level 0, x binder, right associativity, z at level 60,
   format "'[' 'tele'  '/  ' x  ..  y '/ '  'in' '/ '  z ']'")
  : type_scope.

  Local Open Scope telescope.

  Notation "'telei' x .. y 'in' z " := (@sigmaI _ _ x .. (@sigmaI _ _ y z) ..)
                                     (at level 0, right associativity, y at next level, 
                                      format "'[' 'telei'  '/  ' x  ..  y  'in'  z ']'", only parsing)
                                   : telescope.
  
  Lemma solution@{i} {A : Type@{i}} (t : A) : Equiv@{i} (sigma@{i} A (fun x : A => x = t)) unit.
  Proof.
    refine {| equiv a := tt |}.
    unshelve refine {| equiv_inv e := telei t in eq_refl |}.
    - red; intros. destruct x. reflexivity.
    - red; intros. destruct x. now destruct pr2.
    - intros [x eq]. revert t eq. refine (J@{i i} _ _). constructor.
  Defined.
  
  Fixpoint eq_eq_equiv@{i} (Δ : Tel@{i}) : forall (u v : Δ) (e : u = v), u == v :=
    match Δ as Δ return forall (u v : Δ) (e : u = v), u == v with
    | inj A => fun a b e => e
    | ext A f => fun u v e =>
      let p := equiv_inv@{i} (IsEquiv:=path_sigma_equiv _ u v) e in
      &(p.1 & eq_eq_equiv _ _ _ p.2)
    end.

  Fixpoint extend_tele@{i} (Δ : Tel@{i}) : forall (Γ : telescope Δ -> t@{i}), t@{i} :=
    match Δ with
    | inj A => fun Γ => ext A Γ
    | ext A f => fun Γ => ext A (fun a => extend_tele (f a) (fun fa => Γ &(a & fa)))
    end.

  (* Equations extend_tele (Δ : t) (Γ : telescope Δ -> t) : t := *)
  (* extend_tele (inj A) Γ := ext A Γ; *)
  (* extend_tele (ext A f) Γ := ext A (fun a => extend_tele (f a) (fun fa => Γ &(a & fa))). *)
  
  Equations inj_extend_tel (Δ : t) (Γ : telescope Δ -> t) (s : Δ) (t : Γ s) :
    extend_tele Δ Γ :=
  inj_extend_tel (inj A) Γ s t := &(s & t) ;
  inj_extend_tel (ext A f) Γ (sigmaI _ t ts) e :=
    &(t & inj_extend_tel (f t) (fun fa => Γ &(t & fa)) ts e).
  
  Lemma reorder_tele@{i +} (Δ : t@{i}) (Γ : telescope Δ -> t@{i}) :
    telescope (extend_tele Δ Γ) <~> tele (x : telescope Δ) in Γ x.
  Proof.
    unshelve econstructor. 
    - induction Δ; simpl extend_tele in *; simpl; intros. trivial.
      simpl in Γ. specialize (X X0.1 _ X0.2).
      refine &(&(X0.1 & X.1)&X.2).
    - unshelve econstructor.
      + induction Δ; simpl extend_tele in *; intros; simpl in *; trivial.
        specialize (X X0.1.1). exists X0.1.1.
        apply X. exact &(X0.1.2 & X0.2).
    + red. intro. induction Δ; simpl. destruct x. constructor.
      destruct x. simpl. rewrite H. reflexivity.
    + red. intro. induction Δ; simpl. destruct x. constructor.
      destruct x. simpl. rewrite H. reflexivity.
    + apply axiom_triangle.
  Defined.    
    
  Lemma eq_eq_equiv_refl {Δ : Tel} (u : Δ) : eq_eq_equiv Δ u u eq_refl = refl u.
  Proof.
    induction Δ; simpl. reflexivity.
    simpl. now rewrite H.
  Defined.

  Fixpoint eq_eq_equiv_inv@{i} (Δ : Tel@{i}) : forall (u v : Δ) (e : u == v), u = v :=
    match Δ with
    | inj A => fun a b e => e
    | ext A f => fun  u v e =>
      let e' := eq_eq_equiv_inv _ _ _ e.2 in
      equiv@{i} (path_sigma_equivalence _ u v) &(e.1 & e')
    end.

  Lemma eq_eq_equiv_inv_refl@{i} (Δ : Tel@{i}) (u : Δ) :
    eq_eq_equiv_inv Δ u u (refl@{i} u) = eq_refl.
  Proof.
    induction Δ; simpl. reflexivity.
    simpl. now rewrite H.
  Defined.
    
  Lemma sect@{i} : forall (Δ : Tel@{i}) (u v : Δ), Sect@{i i} (eq_eq_equiv_inv Δ u v) (eq_eq_equiv Δ u v).
  Proof.
    induction Δ. simpl. intros. intro. constructor.
    intros u v. intros He. simpl in * |-.
    Opaque path_sigma_uncurried path_sigma path_sigma_equivalence path_sigma_equiv.
    pose proof (eissect (path_sigma_uncurried u v)). simpl. red in H0.
    Transparent path_sigma_uncurried path_sigma path_sigma_equivalence path_sigma_equiv.
    match goal with
      |- context[equiv _ ?x] => set (foo:=x)
    end.
    specialize (H0 foo).
    set (bar := (equiv_inv@{i} (equiv@{i} _ foo))) in *.
    change (bar = foo) in H0. symmetry in H0.
    unfold foo in H0. subst foo. clearbody bar. revert bar H0.
    refine (@subst2@{i i} _ _ _ _). simpl.
    simpl. red in H. specialize (H _ _ _ He.2). destruct He. simpl. apply cong. apply H.
  Defined.

From Equations.Prop Require Import EqDecInstances.

  Typeclasses Transparent telescope.
  Transparent path_sigma_equiv path_sigma_uncurried.
  Lemma retr@{i} : forall (Δ : Tel@{i}) (u v : Δ), Sect@{i i} (eq_eq_equiv Δ u v) (eq_eq_equiv_inv Δ u v).
  Proof.
    induction Δ.
    + simpl. intros. intro. constructor.
    + intros u v e.
      simpl.
      specialize (H v.1 (rew (equiv_inv (IsEquiv := path_sigma_equiv _ _ _) e).1 in u.2) v.2
                    (equiv_inv (IsEquiv := path_sigma_equiv _ _ _) e).2).
      set (foo := eq_eq_equiv_inv _ _ _ _) in *.
      symmetry in H. clearbody foo. revert foo H.
      refine (subst2@{i i} _).
      refine (eisretr (path_sigma_uncurried u v) _).
  Defined.

  Lemma eq_sym_dep {A} (x y : A) (P : x = y -> Type)
        (G : forall e : y = x, P (eq_sym e)) :
    forall e : x = y, P e.
  Proof.
    intros. destruct e. apply (G eq_refl).
  Defined.

  Global Instance eq_points_isequiv@{i} (Δ : Tel@{i}) (u v : Δ) : IsEquiv@{i} (eq_eq_equiv Δ u v) :=
    {| equiv_inv := eq_eq_equiv_inv Δ u v |}.
  Proof.
    - apply sect.
    - apply retr. 
    - revert v.
      induction Δ as [ | A t IH].
      + refine (J@{i i} _ _). constructor.
      + simpl in u; refine (J@{i i} _ _).
        simpl sect. rewrite (IH u.1 u.2 u.2 eq_refl).
        simpl eq_eq_equiv. simpl retr.
        set (r:=retr@{i} _ _ _ _) in *.
        set(lhs' := eq_eq_equiv _ _ _).
        set(lhs:=eq_eq_equiv_inv _ _ _ _) in *.
        clearbody r.
        revert r. refine (eq_sym_dep@{i i} _ _ _ _).
        apply axiom_triangle.
        (* clearbody lhs. *)
        (* clearbody lhs. *)
        (* revert lhs. now refine (J _ _). *)
  Defined.
  
  (** Telescopic equality is equivalent to equality of the sigmas. *)
  Definition eq_points_equiv@{i} (Δ : Tel@{i}) (u v : Δ) : Equiv@{i} (u = v) (u == v) :=
    {| equiv := eq_eq_equiv Δ u v |}.

  (* Goal (forall n : nat, True). *)
  (*   intros. *)
  (*   pose (tele (n' : nat) in (S n' =={ inj nat } S n)). *)


  (** Necessary as the telescope structure is not easy for Coq to infer *)
  Global Hint Extern 0 (Equiv (?x = ?y) (telescope (eq ?Δ ?x' ?y'))) =>
    exact (eq_points_equiv Δ x' y') : typeclass_instances.

  Definition NoConf@{i} :=
    fun (A : Type@{i}) (x : sigma@{i} _ (fun index : nat => vector A index)) =>
      match x.2 with
      | Vector.nil =>
        fun y : &{ index : nat & vector A index} =>
          match y.2 with
          | Vector.nil => True
          | Vector.cons _ _ => False
          end
      | @Vector.cons _ h n x0 =>
        fun y : &{ index : nat & vector A index} =>
          match y.2 with
          | Vector.nil => False
          | @Vector.cons _ h0 n0 x1 => telei (h) (n) in (x0) = telei (h0) (n0) in (x1) :> tele (_ : A) (n : nat) in vector A n
          end
      end.
  
  Lemma noconf@{i +} :
    forall (A : Type@{i}) (a b : &{ index : nat & vector A index}), a = b -> NoConf@{i} A a b.
  Proof.
    intros. destruct H. destruct a. simpl. destruct pr2. simpl. exact I.
    simpl. reflexivity.
  Defined.

  Lemma noconf_inv@{i +} :
    forall (A : Type@{i}) (a b : &{ index : nat & vector A index}), NoConf@{i} A a b -> a = b.
  Proof.
    intros. destruct a, b. destruct pr2, pr3; try constructor || contradiction.
    simpl in H.
    NoConfusion.destruct_tele_eq H. reflexivity.
  Defined.
  
  Import NoConfusion.

  Global Instance noconf_isequiv@{i} (A : Type@{i}) (a b : sigma@{i} _ _) : IsEquiv@{i} (noconf A a b).
  Proof.
    unshelve refine {| equiv_inv := noconf_inv A a b |}.
    intro.
    - destruct_sigma a; destruct_sigma b; 
      destruct a ; destruct b; simpl in * |-;
      on_last_hyp ltac:(fun id => destruct_tele_eq id || destruct id);
      solve [constructor].
    - intro. solve_noconf_inv_equiv.
    - intros. destruct x. destruct a. destruct pr2; simpl; constructor.
  Defined.

  Definition noconf_equiv@{i} (A : Type@{i}) a b : Equiv (a = b) (NoConf@{i} A a b) :=
    {| equiv := noconf A a b |}.
  
  Global Hint Extern 0 (@IsEquiv (?x = ?y) (telescope (eq ?Δ ?x' ?y')) _) =>
    exact (@eq_points_isequiv Δ x' y') : typeclass_instances.

  Global Hint Extern 0 (@IsEquiv (?x = ?y) _ _) =>
    exact (@noconf_isequiv _ x y) : typeclass_instances.

  Global Hint Extern 0 (@Equiv (?x = ?y) _) =>
    exact (@noconf_equiv _ x y) : typeclass_instances.

  Arguments noconf_equiv : simpl never.
  Arguments noconf_isequiv : simpl never.
  Arguments equiv : simpl never.
  Arguments equiv_inv : simpl never.

  Notation "f ^-1" := (@equiv_inv _ _ f _) (at level 3).
  Infix "@" := eq_trans (at level 80).

  (** The composition of equivalences is an equivalence. *)
  Instance isequiv_compose A B f C g {E : @IsEquiv A B f} {E' : @IsEquiv B C g}
    : IsEquiv (compose g f) | 1000
    := BuildIsEquiv A C (compose g f)
                    (compose f^-1 g^-1) _ _ _ .
  Proof.
    exact
      (fun c => cong g (eisretr f (g^-1 c)) @ eisretr g c).
    exact
      (fun a => cong (f^-1) (eissect g (f a)) @ eissect f a).
    intro.
    simpl.
    apply axiom_triangle.
  Defined.
  
  Definition equiv_compose {A B C} (E : Equiv A B) (E' : Equiv B C) : Equiv A C :=
    Build_Equiv A C (compose (@equiv _ _ E') (@equiv _ _ E)) _.
  
  Definition injectivity_cons {A} (u v : tele (x : A) (n : nat) in vector A n)
    : (&(S u.2.1 & @Vector.cons A u.1 u.2.1 u.2.2) =
       &(S v.2.1 & @Vector.cons A v.1 v.2.1 v.2.2)) <~> u == v :=
    equiv_compose (noconf_equiv A &(S u.2.1 & @Vector.cons A u.1 u.2.1 u.2.2)
                   &(S v.2.1 & @Vector.cons A v.1 v.2.1 v.2.2))
                  (eq_points_equiv (tele (x : A) (n : nat) in vector A n) _ _).

End Telescopes.

Module Example_cons.

Notation " 'rewP' H 'at' B 'in' c " := (@subst _ _ B _ H c) (at level 20, only parsing).

Import Telescopes.

Lemma inj_dep {A} (P : A -> Type)
      (G : forall e : inj A, P e) :
  forall e : A, P e.
Proof. apply G. Defined.

Polymorphic
Definition pr1_seq@{i} {A : Type@{i}} {P : A -> Type@{i}} {p q : sigma A P} (e : p = q) : p.1 = q.1.
Proof. destruct e. apply eq_refl. Defined.

Notation " 'rew' H 'in' c " := (@eq_rect _ _ _ c _ H) (at level 20).

Polymorphic
Definition pr2_seq@{i} {A : Type@{i}} {P : A -> Type@{i}} {p q : sigma A P} (e : p = q) :
  rew (pr1_seq e) in p.2 = q.2.
Proof. destruct e. apply eq_refl. Defined.

Polymorphic Definition rewh@{i} {A : Type@{i}} {B : A -> Type@{i}} {x : A} {p q : B x}
    (e : &(x & p) = &(x & q)) (e' : pr1_seq e = eq_refl) : p = q :=
  (@eq_rect _ (pr1_seq e) (fun f : x = x => rew f in p = q)
            (pr2_seq e) eq_refl e').

Polymorphic
Lemma solution_inv@{i j} {A : Type@{i}}
      (B : A -> Type@{i}) (x : A) (p q : B x) (G : p = q -> Type@{j}) :
  (forall (e : &(x & p) = &(x & q)) (e' : pr1_seq e = eq_refl),
      G (rewh e e')) ->
  (forall e : p = q, G e).
Proof.
  intros H. intros e. destruct e. specialize (H eq_refl eq_refl). simpl in H. apply H.
Defined.

  Definition uncurry {A} {B : A -> Type} {C : forall x : A, B x -> Type}
  (f : forall s : &{ x : A & B x }, C s.1 s.2) :
  forall (x : A) (b : B x), C x b :=
  fun x b => f &(x & b).


  Lemma rewrite_in {A} {x y z : A} (e : x = y) (e' : x = z) : y = z.
  Proof. destruct e. apply e'. Defined.
  Lemma rewrite_inr {A} {x y z : A} (e : x = y) (e' : y = z) : x = z.
  Proof. destruct e. apply e'. Defined.
  Open Scope telescope.

  Lemma cong_equiv_inv@{i} (Δ : Tel@{i}) (T : Type@{i}) (f : Δ -> T) (u v : Δ) :
    IsEquiv f -> f u = f v ->  u =={Δ} v.
  Proof. 
    intros.
    apply eq_points_equiv.
    apply (cong equiv_inv) in H.
    transitivity (f ^-1 (f u)). symmetry. apply (eissect f u).
    transitivity (f ^-1 (f v)). apply H. apply (eissect f v).
  Defined.
  
  Instance cong_is_equiv@{i} (Δ : Tel@{i}) (T : Type@{i}) (f : Δ -> T) (u v : Δ) (I : IsEquiv f) :
    IsEquiv (cong f u v) :=
    { equiv_inv := _ }.
  Proof.
    intros.
    - eapply cong_equiv_inv; eauto.
    - red.
      intros x. unfold cong_equiv_inv.
      apply axiom_triangle.
    - apply axiom_triangle.
    - apply axiom_triangle.
  Defined.
    
  Definition cong_equiv (Δ : Tel) (u v : Δ) (T : Type) (f : Δ -> T) (E : IsEquiv f) :
    u =={Δ} v <~> f u = f v :=
   {| equiv := cong f u v |}.

  Notation "'telei' x .. y 'in' z " := (@sigmaI _ _ x .. (@sigmaI _ _ y z) ..)
                                     (at level 0, right associativity, y at next level, 
                                      format "'[' 'telei'  '/  ' x  ..  y  'in'  z ']'", only parsing)
                                   : telescope.

  Notation " a '={' P ; e } b " := (subst (P:=P) e a = b) (at level 90).

  Notation " a '==={' P ; e } b " := (subst P _ _ e a = b) (at level 90, only parsing) : telescope.

  Lemma equiv_cong_subst {A B} (P : B -> Type) (f : A -> B)
        (s t : A) (e : s = t) (u : P (f s))
        (v : P (f t)) : u =_{(fun x => P (f x)); e} v <~> (u =_{P; cong f e} v).
  Proof.
    unfold subst.
    destruct e. simpl. apply equiv_id.
  Defined.

  Lemma equiv_cong_subst_dep {A} {B : A -> Type}
        (P : forall x : A, B x -> Type) (f : forall x : A, B x)
        (s t : A) (e : s = t) (u : P s (f s))
        (v : P t (f t)) : u =_{(fun x => P x (f x)); e} v <~>
                              (J (fun y e => P y (rew e in (f s)))
                                     u _ e =_{(fun x => P _ x); congd f e} v).
  Proof.
    unfold subst.
    destruct e. simpl. apply equiv_id.
  Defined.
  
  Lemma equiv_cong_subst_tel {Δ Γ : Tel} (P : Γ -> Tel) (f : Δ -> Γ)
        (s t : Δ) (e : s =={Δ} t) (u : P (f s)) :
    subst P (cong_tel f e) u = subst (fun x => P (f x)) e u.
  Proof.
    unfold subst. revert t e. refine (J _ _ _). intros.
    rewrite J_refl. unfold cong_tel. simpl. rewrite !J_refl. reflexivity.
  Defined.

  Lemma equiv_tele_l {A} {A'} {B : A' -> Type} (e : Equiv A A') :
    tele (x : A) in B (equiv e x) <~> tele (x : A') in B x.
  Proof.
    simpl.
    unshelve refine {| equiv a := &(e a.1 & _) |}. exact a.2.
    unshelve refine {| equiv_inv a := &(e ^-1 a.1 & _) |}. destruct a. simpl.
    rewrite eisretr. exact pr2.
    
    red; intros. simpl. destruct x. simpl.
    pose (eisretr e pr1).
    apply path_sigma_uncurried. simpl.
    exists e0. simpl. unfold eq_rect_r. clearbody e0. 

    apply axiom_triangle.
    apply axiom_triangle.
    apply axiom_triangle.
    
    (* apply eisretr. *)
    (* red; intros. simpl. destruct x. simpl. apply cong. *)
    (* apply eissect. *)

    (* intros [x bx]. *)
    (* simpl. rewrite eisadj. simpl. *)
    (* destruct (eissect (e x) bx). simpl. reflexivity. *)
  Defined.

  Lemma equiv_tele_r@{i} {A : Type@{i}} {B B' : A -> Type@{i}} (e : forall x : A, Equiv (B x) (B' x)) :
    tele (x : A) in B x <~> tele (x : A) in (B' x).
  Proof.
    simpl.
    unshelve refine {| equiv a := &(a.1 & e a.1 a.2) |}.
    unshelve refine {| equiv_inv a := &(a.1 & inv_equiv (e a.1) a.2) |}.
    red; intros. simpl. destruct x. simpl. apply cong.
    apply eisretr.
    red; intros. simpl. destruct x. simpl. apply cong.
    apply eissect.

    intros [x bx].
    simpl. rewrite eisadj. simpl.
    destruct (eissect (e x) bx). simpl. reflexivity.
  Defined.

  Lemma eq_sym_equiv@{i} {A : Type@{i}} {x y : A} : Equiv@{i} (x = y) (y = x).
  Proof.
    unshelve refine {| equiv a := eq_sym a |}.
    unshelve refine {| equiv_inv a := eq_sym a |}.
    intro e; destruct e. apply eq_refl.
    intro e; destruct e. apply eq_refl.
    intro e; destruct e. apply eq_refl.
  Defined.

  Lemma eq_tele_sym_equiv@{i} {Δ : Tel@{i}} {x y : Δ} : x == y <~> y == x.
  Proof.
    refine (equiv_compose _ _).
    refine (equiv_sym _).
    refine (eq_points_equiv _ _ _).
    refine (equiv_compose _ _).
    refine eq_sym_equiv.
    refine (eq_points_equiv _ _ _).
  Defined.

  Lemma subst_subst@{i} (Δ : Tel@{i}) (a b : Δ) (r s : a =={Δ} b) :
    subst (λ y : Δ, b == y) s (subst (λ x : Δ, x == a) r (refl a)) == refl b
    <~> r =={a =={Δ} b} s.
  Proof.
    induction Δ.
    + simpl in *. destruct r.
      unfold subst. simpl.
      edestruct (eq_sym (J_on_refl@{i i} _ _ s)).
      apply eq_sym_equiv.
    + unfold subst.
      revert b r s. refine (J@{i i i} _ _ _).
      intros s. edestruct (eq_sym (J_refl@{i i i} _ (fun v _ => v == a) (refl a))).
      edestruct (eq_sym (J_on_refl@{i i i} _ _ s)).
      refine (eq_tele_sym_equiv@{i}).
  Defined.
  (** This is the square we get (almost) by applying congruence: 
      it is dependent over e. *)
  Definition dep_square {Γ : Tel} (Δ : Γ -> Tel) u v (e : u =={Γ} v)
             (a b : forall ρ, Δ ρ)
             (eqΔ := λ ρ, a ρ =={Δ ρ} b ρ)
             (r : eqΔ u) (s : eqΔ v) :=
      (subst (fun y => telescope (b u =={Δ;e} y)) s
             (subst (fun y => telescope (y =={Δ;e} a v)) r (dcong_tel a e))
       =={b u =={Δ;e} b v} (dcong_tel b e)).

  Definition square_tel {Δ : Tel} {w x y z : Δ} (t : w =={Δ} x)
             (b : y == z) (l : w == y) (r : x == z) : Tel :=
    subst (fun x : Δ => x == y) t l =={fun y => x == y;b} r.

  Arguments telescope : simpl never.

  (** This is the square we want: we already simplified the dependency on 
      of the endpoints types. *)
  Lemma inj_extend_tel_equiv@{i} (Γ : Tel@{i}) (u v : Γ) (Δ : Tel@{i}) (a b : Γ → Δ)
        (eqΔ:=λ ρ : Γ, a ρ =={Δ} b ρ) (r : eqΔ u) (s : eqΔ v) :
    inj_extend_tel Γ eqΔ u r =={extend_tele Γ eqΔ} inj_extend_tel Γ eqΔ v s <~>
          extend_tele (u =={Γ} v)
          (λ x : u =={Γ} v,
                 square_tel r s (cong_tel a x) (cong_tel b x)).
    induction Γ.
    Transparent telescope eq.

    - simpl extend_tele.
      simpl inj_extend_tel.
      refine (equiv_tele_r _). intros x.
      unfold square_tel.
      simpl in x.
      revert v x s. refine (J@{i i} _ _). intros s.
      simpl. unfold square_tel. unfold cong_tel. simpl.
      subst eqΔ. simpl in *.
      refine (equiv_sym _). apply subst_subst.

    - simpl. refine (equiv_tele_r _). intros.
      destruct v. simpl in *. subst eqΔ. simpl in *.
      revert pr1 x pr2 s. 
      refine (J@{i i} _ _).
      simpl. intros. specialize (X u.1 u.2 pr2).
      specialize (X (fun ρ => a &(u.1 & ρ))).
      simpl in X. specialize (X (fun ρ => b &(u.1 & ρ))).
      simpl in X. destruct u. simpl in *.
      specialize (X r s).
      apply X.
  Defined.
    
  Definition lifted_solution@{i j} (Γ : Tel@{i}) (u v : Γ) (Γ' : Tel@{i})
        (Δ : Tel@{i})
        (a b : Γ -> Δ)
        (eqΔ := λ ρ, a ρ =={Δ} b ρ)
        (r : eqΔ u) (s : eqΔ v)
        (f : extend_tele Γ eqΔ <~> Γ') :
    tele (e : u =={Γ} v) in square_tel r s (cong_tel a e) (cong_tel b e)
    <~>
    f (inj_extend_tel Γ eqΔ u r) =={Γ'} f (inj_extend_tel Γ eqΔ v s).
  Proof.
    refine (equiv_compose _ _).
    Focus 2.
    refine (equiv_compose _ _).
    refine (cong_equiv@{i i i} (extend_tele Γ eqΔ)
                       (inj_extend_tel Γ eqΔ u r) (inj_extend_tel Γ eqΔ v s) _ f _).
    Show Universes.
    refine (eq_points_equiv _ _ _).
    unfold square_tel.
    refine (equiv_compose _ _).
    refine (equiv_sym _).
    refine (reorder_tele@{i j} (u =={Γ} v) (fun x => _)).
    refine (equiv_sym _).
    apply inj_extend_tel_equiv.
  Defined.

  Lemma lower_solution@{i +} :
    forall (A : Type@{i}) n,
      Equiv@{i} (tele (x' : A) (n' : nat) (v : vector A n') in (S n' = S n))
           (tele (x : A) in vector A n).
  Proof.
    intros A n.
    unshelve refine {| equiv a := _ |}.
    refine &(a.1 & _).
    destruct a. destruct pr2. destruct pr2.
    simpl in pr3. noconf pr3. exact pr2.
    
    unshelve eapply BuildIsEquiv@{i}.
    intros a.
    refine &(a.1, n & _).
    refine &(a.2 & eq_refl).

    intro.
    simpl. unfold solution_left. simpl. reflexivity.
    intro.
    simpl. unfold solution_left.
    unfold NoConfusion.noConfusion_nat_obligation_1. simpl.
    destruct x. destruct pr2. destruct pr2. simpl.
    refine (cong@{i i} _ _).
    revert pr3. simplify_one_dep_elim.
    simplify_one_dep_elim. intros.
    reflexivity.

    intros.
    simpl. destruct x as (x&n'&v&e).
    unfold solution_left_dep, apply_noConfusion. simpl.
    unfold cong.
    revert e. simpl.
    simplify_one_dep_elim.
    simplify_one_dep_elim.
    intros. reflexivity.
  Defined.

  Definition telu A := tele (x' : A) (n' : nat) in vector A n'.
  Definition telv A n := tele (x : A) in vector A n.
  Lemma apply_equiv_dom {A B} (P : B -> Type) (e : Equiv A B) :
    (forall x : A, P (equiv e x)) -> forall x : B, P x.
  Proof.
    intros.
    specialize (X (e ^-1 x)).
    rewrite inv_equiv_equiv in X. exact X.
  Defined.

  Lemma apply_equiv_codom {A} {B B' : A -> Type} (e : forall x, Equiv (B x) (B' x)) :
    (forall x : A, B x) <~> forall x : A, B' x.
  Proof.
    intros.
    unshelve refine {| equiv f := fun x => e x (f x) |}.
    unshelve refine {| equiv_inv f := fun x => (e x)^-1 (f x) |}.
    red; intros.
    extensionality y. apply inv_equiv_equiv.
    intro. extensionality y. apply equiv_inv_equiv.
    intros.
    apply axiom_triangle.
  Defined.

  Polymorphic
    Lemma equiv_switch_indep {A : Type} {B : Type} :
    (tele (_ : A) in B <~> tele (_ : B) in A).
  Proof.
    unshelve refine {| equiv a := _ |}. simpl. exact &(a.2 & a.1).
    unshelve refine {| equiv_inv a := _ |}. simpl. exact &(a.2 & a.1).

    - intro a. simpl. reflexivity.
    - intro a. simpl. reflexivity.
    - intro a. simpl. reflexivity.
  Defined.

  Polymorphic
    Lemma equiv_elim_unit {A : Type} : (tele (_ : []) in A) <~> inj A.
  Proof.
    unshelve refine {| equiv a := _ |}. simpl. exact a.2.
    unshelve refine {| equiv_inv a := _ |}. simpl. exact &(tt & a).

    - intro a. simpl. reflexivity.
    - intros [[ ] t]. simpl. reflexivity.
    - intros [[ ] t]. simpl. reflexivity.
  Defined.
  Set Printing Universes.
  Arguments telescope : simpl never.
  Polymorphic
    Lemma solution_inv_tele@{i j +} {A : Type@{i}} (B : A -> Type@{i}) (x : A) (p q : B x) :
    (Equiv@{i} (p = q)
     (sigma@{i} _ (fun x0 : x = x => sigma@{i} _ (fun _ : p ={ B; x0} q => x0 = eq_refl)))).
  Proof.
    refine (equiv_compose
              (B:=sigma@{i} _ (fun x0 : x = x => sigma@{i} _ (fun _ : x0 = eq_refl => p ={ B; x0} q))) _ _).
    all:cycle 1.
    refine (equiv_tele_r _); intro e.
    refine (equiv_switch_indep@{i i i}).
    refine (equiv_sym _).
    refine (equiv_compose _ _).
    refine (reorder_tele@{i j}
              (tele (e : x = x) in ((e = eq_refl) : Type@{i})) (fun ρ => inj (p ={B;ρ.1} q))).
    simpl.
    refine (equiv_compose _ _).
    refine (equiv_sym (equiv_tele_l@{i i i} _)).
    refine (equiv_sym _).
    refine (@solution (x = x) eq_refl).
    simpl.
    refine equiv_elim_unit.
  Defined.

  Definition NoConf@{i} :=
    fun (A : Type@{i}) (x : sigma@{i} _ (fun index : nat => vector A index)) =>
      match x.2 with
      | Vector.nil =>
        fun y : &{ index : nat & vector A index} =>
          match y.2 with
          | Vector.nil => inj@{i} unit
          | Vector.cons _ _ => inj@{i} False
          end
      | @Vector.cons _ h n x0 =>
        fun y : &{ index : nat & vector A index} =>
          match y.2 with
          | Vector.nil => inj@{i} False
          | @Vector.cons _ h0 n0 x1 =>
            telei (h) (n) in (x0) =={tele (x : A) (n : nat) in vector A n}
                                      telei (h0) (n0) in (x1)
          end
      end.
Inductive Iseq2 {A : Type} : forall x y: A, x = y -> y = x -> Type :=
  iseq2 w : Iseq2 w w eq_refl eq_refl.



Lemma invIseq2' {A} (x : A) (e : x = x) (iseq : Iseq2 x x e eq_refl) :
  &{ H : eq_refl = e &
         (subst (P:=fun e => Iseq2 x x e eq_refl) H (iseq2 x)) = iseq }.
  generalize_eqs_sig iseq.
  destruct iseq.


  intros H; symmetry in H. revert H.
  refine (eq_simplification_sigma1_dep_dep _ _ _ _ _).
  intros. subst iseq0.
  revert e'.
  intros e'.
  set (eos := the_end_of_the_section). move eos before A.
  uncurry_hyps pack. pattern sigma pack.
  clearbody pack. clear.

  set(vartel := tele (x : A) (e : x = x) (w : A)
        (e : (&(w, w, eq_refl & eq_refl) = &(x, x, e & eq_refl)
                                              :> (tele (x : A) (y : A) (e : x = y) in (y = x)))) in unit).


  change (telescope vartel) in pack.
  unfold vartel in pack.
  clear vartel.
  revert pack.
  unshelve refine (apply_equiv_dom _ _ _).
  shelve.
  refine (equiv_sym _).
  - refine (equiv_compose _ _).



  set(vartel := tele (x : A) (e : x = x) in A).
  set(eqtel' :=  (fun x : vartel =>
                    tele (_ : &(x.2.2, x.2.2, eq_refl & eq_refl) = &(x.1, x.1, x.2.1 & eq_refl) :>
     tele (x : A) (y : A) (e : x = y) in (y = x))  in unit)).

  pose (reorder_tele vartel eqtel'). simpl in e.
  unfold eqtel' in e. simpl in e. refine e.
  refine (equiv_compose _ _).
  refine (equiv_compose _ _).
  refine (equiv_tele_r _).
  intros x.
  set(eqtel := (tele (x : A) (y : A) (e : x = y) in (y = x))).
  set(vartel := tele (x : A) (e : x = x) in A).
  set(eqtel'' :=  (fun x : vartel =>
                     tele (_ : &(x.2.2, x.2.2, eq_refl & eq_refl) =={eqtel} &(x.1, x.1, x.2.1 & eq_refl)) in unit)).
  refine (equiv_compose _ _).
  refine (equiv_tele_l (B := fun _ => unit) _).
  apply (@eq_points_equiv eqtel).
  refine (equiv_id _).
  cbn.
  simpl. refine (equiv_id _).
  refine (equiv_id _).
  simpl.

    refine (con




  simpl.








  simplify ?. simpl.

  Lemma noconf :
    forall (A : Type) (a b : &{ index : nat & vector A index}),
      a =={ext nat (fun n => inj (vector A n))} b -> NoConf A a b.
  Proof.
    intros. destruct X. destruct a, b. simpl in pr1, pr2.
    destruct pr1. simpl in pr2. destruct pr2.
    simpl.
    destruct pr3. simpl. simpl. exact tt.
    simpl. exists eq_refl. exists eq_refl. simpl. constructor.
  Defined.

  Lemma noconf_inv :
    forall (A : Type) (a b : &{ index : nat & vector A index}),
      NoConf A a b -> a =={ext nat (fun n => inj (vector A n))} b.
  Proof.
    intros. destruct a, b. destruct pr2, pr3; try constructor || contradiction.
    simpl in X. exists eq_refl. constructor. unfold NoConf in X.
    cbv beta iota delta -[telescope eq_expl] in X.
    apply (@cong_tel (tele (x : A) (n : nat) in (vector A n))
                    (tele (n1 : nat) in vector A n1)
                    (fun x => &(S x.2.1 & Vector.cons x.1 x.2.2))
                    _ _ X).
  Defined.
  
  Import NoConfusion.

  Global Instance noconf_isequiv A a b : IsEquiv (noconf A a b).
  Proof.
    unshelve refine {| equiv_inv := noconf_inv A a b |}.
    intro.
    - destruct_sigma a; destruct_sigma b.
      destruct a ; destruct b; simpl in * |-. simpl.
      on_last_hyp ltac:(fun id => destruct_tele_eq id || destruct id);
        solve [constructor].
      simpl. bang. simpl. bang.
      simpl. unfold telescope in x.
      destruct_sigma x. 
      destruct_sigma x. destruct idx, idx0. simpl in x. destruct x.
      simpl. reflexivity.
      
    - intro.
      destruct_sigma a; destruct_sigma b.
      destruct x. simpl in *. destruct pr1, pr2.
      destruct a; simpl in * |-; constructor.

    - intros. destruct x, a, b. simpl in *; destruct pr1, pr2; simpl. destruct pr3; constructor.
  Defined.

  Definition noconf_equiv A a b :
    Equiv (a =={tele (n : nat) in vector A n} b) (NoConf A a b) :=
    {| equiv := noconf A a b |}.
  
  Definition injectivity_cons2 {A} (u v : tele (x : A) (n : nat) in vector A n)
    : tele (e : S u.2.1 = S v.2.1) in
      (@Vector.cons A u.1 u.2.1 u.2.2 ==_{fun x : telescope (inj nat) => Vector.t A x;e} @Vector.cons A v.1 v.2.1 v.2.2)
        <~> u == v.
  Proof.
    refine (noconf_equiv A &(S u.2.1 & @Vector.cons A u.1 u.2.1 u.2.2)
          &(S v.2.1 & @Vector.cons A v.1 v.2.1 v.2.2)). 
  Defined.

  Ltac intros_tele :=
    match goal with
      |- Equiv (telescope (ext _ ?F)) _ =>
      refine (equiv_tele_r _);
      match F with
        (fun x => @?F x) =>
        intros ?x;
        match goal with
          id : _ |- Equiv _ ?y =>
          let f' := eval simpl in (F id) in
              change (Equiv (telescope f') y)
        end
      end
    | |- Equiv (sigma _ (fun x => _)) _ =>
      refine (equiv_tele_r _); intros ?x
    end.

  Lemma rew_sym@{i} (A : Type@{i}) {Δ : A -> Tel@{i}} (x y : A) (px : Δ x) (py : Δ y)
        (e : y = x) :
    px =={Δ x} subst (P:=Δ) e py ->
    subst (P:=Δ) (eq_sym e) px =={Δ y} py.
  Proof. destruct e. simpl. trivial. Defined.

  Equations sym {Δ : Tel} {s t : Δ} (e : s =={Δ} t) : t =={Δ} s :=
    sym {Δ:=(inj A)} e := eq_sym e ;
    sym {Δ:=(ext A f)} e := &(eq_sym e.1 & rew_sym _ _ _ _ _ _ (sym e.2)).

  Lemma cong_tel_proj@{i} (Δ : Tel@{i}) (A : Type@{i}) (Γ : A -> Tel@{i})
        (f : Δ → ext A Γ) (u v : Δ) (e : u =={Δ} v) :
    (cong_tel f e).1 = cong_tel (Γ:=inj A) (fun x => (f x).1) e.
  Proof.
    induction Δ.
    
    + revert v e. refine (J@{i i i} _ _ _).
      simpl. unfold cong_tel. simpl. reflexivity.
    + revert v e. refine (J@{i i i} _ _ _).
      simpl.
      specialize (H u.1 (fun t => f &(u.1 & t)) u.2 u.2 (refl _)).
      unfold cong_tel at 1. simpl. unfold cong_tel in H.
      rewrite H. reflexivity.
  Defined.

  Lemma cong_tel_nondep@{i} {Δ Γ : Tel@{i}} (T : Γ) (u v : Δ) (e : u =={Δ} v) :
    cong_tel (fun _ => T) e == refl T.
  Proof.
    revert v e. refine (J _ _ _).
    unfold cong_tel. rewrite J_refl. apply refl.
  Defined.
  
  Arguments eq : simpl never.
  Lemma example@{i j +} {A : Type@{i}} :
    sigma@{j} (Tel@{i}) (fun Γ' : Tel@{i} =>
                           Equiv@{i}
                                (tele (n : nat) (x y : A) (v v' : Vector.t A n) in
                       (Vector.cons x v = Vector.cons y v')) Γ').
  Proof.
    intros. eexists.
    refine (equiv_compose _ _).
    do 5 intros_tele.
    2:simpl.
    refine (equiv_compose _ _).
    refine (solution_inv_tele (A:=nat) (Vector.t A) _ _ _).

    refine (equiv_compose _ _).
    refine (reorder_tele@{i j} (ext@{i} _ (fun e0 : S n = S n => inj@{i} (Vector.cons x v ={ vector A ; e0} (Vector.cons y v')))) (fun ρ => inj@{i} (ρ.1 = eq_refl))).
    simpl.
    refine (equiv_compose _ _).
    refine (equiv_sym _).
    refine (equiv_tele_l _).
    refine (equiv_sym _).
    refine (injectivity_cons2@{i i} &(x, n & v) &(y, n & v')). cbn.
    pose (lower_solution@{i i} A n).
    pose (inv_equiv e &(x & v)).
    simpl in e.
    pose (sol:=lifted_solution@{i j} (tele (_ : A) (n' : nat) in vector A n')).
    simpl in sol.
    simpl in t0.
    unfold e, lower_solution, equiv, equiv_inv, inv_equiv in t0. simpl in t0.
    unfold e, lower_solution, equiv, equiv_inv, inv_equiv in t0. simpl in t0.
    set (solinst :=
           sigmaI@{i} (fun x => sigma@{i} nat (fun n => vector A n)) t0.1 &(t0.2.1 & t0.2.2.1)).
    specialize (sol solinst).
    specialize (sol &(y, n & v')).
    (* specialize (sol solinst). (*&(y, n & v')).*) *)
    specialize (sol (telv@{i i} A n)).
    specialize (sol (inj@{i}  nat)).
    simpl in sol.
    specialize (sol (fun x => S x.2.1) (fun x => S n) eq_refl eq_refl). simpl in sol.
    specialize (sol e). subst e.
    simpl in sol.
    unfold solution_left in *.
    simpl in *.
    unfold inv_equiv in sol. unfold eq_points_equiv in sol. simpl in *.
    unfold equiv_inv in *. simpl in *.
    unfold cong in sol. simpl in *.
    
    refine (equiv_compose
              (C:=tele (e : x = y) in (v ={ (λ _ : A, inj (vector A n)); e} v'))
              _ sol). simpl.
    refine (equiv_tele_r _).
    intros.

    unfold equiv_sym. 
    unfold injectivity_cons2. simpl.
    unfold noconf_equiv, equiv, inv_equiv, equiv_inv. simpl.
    unfold square_tel.
    simpl.
    Transparent eq telescope.
    simpl.
  
    clear sol. subst solinst.
    unfold subst. simpl.
    rewrite (cong_tel_proj@{i} _ _ (fun x : nat => inj (vector A x))
                           (λ x0 : tele (_ : A) (n0 : nat) in vector A n0,
                             &(S (x0.2).1 & Vector.cons x0.1 (x0.2).2))
                           _ _ x0).
    simpl.
    Transparent telescope.
    unfold telescope at 1. simpl telescope.
    rewrite (cong_tel_nondep@{i} (Γ:=inj nat) (S n) _ _ x0).
    refine (equiv_id _). simpl.
    refine (equiv_id _).
  Defined.
  Print Assumptions example.
  Eval compute in (pr1 (@example nat)).
  
  Definition uncurry4 {A} {B : A -> Type} {C : forall x : A, B x -> Type}
           {D : forall (a : A) (b : B a) (c : C a b), Type}
           {E : forall (a : A) (b : B a) (c : C a b) (d : D a b c), Type}
           (f : forall s : tele (a : A) (b : B a) (c : C a b) in (D a b c),
               E s.1 s.2.1 s.2.2.1 s.2.2.2) :
  forall (x : A) (b : B x) (c : C x b) (d : D x b c), E x b c d :=
  fun x b c d => f &(x , b , c & d).

  Definition uncurry5 {A} {B : A -> Type} {C : forall x : A, B x -> Type}
           {D : forall (a : A) (b : B a) (c : C a b), Type}
           {E : forall (a : A) (b : B a) (c : C a b) (d : D a b c), Type}
           {F : forall (a : A) (b : B a) (c : C a b) (d : D a b c) (e : E a b c d), Type}
           (f : forall s : tele (a : A) (b : B a) (c : C a b) (d : D a b c) in E a b c d,
               F s.1 s.2.1 s.2.2.1 s.2.2.2.1 s.2.2.2.2) :
    forall (x : A) (b : B x) (c : C x b) (d : D x b c) (e : E x b c d),
           F x b c d e :=
  fun x b c d e => f &(x , b , c , d & e).
  (* Lemma apply_equiv_dom {A B} (P : B -> Type) (e : Equiv A B) : *)
  (*   (forall x : A, P (equiv e x)) -> forall x : B, P x. *)
  (* Proof. *)
  (*   intros. *)
  (*   specialize (X (e ^-1 x)). *)
  (*   rewrite inv_equiv_equiv in X. exact X. *)
  (* Defined. *)

  Definition uncurry6 {A} {B : A -> Type} {C : forall x : A, B x -> Type}
           {D : forall (a : A) (b : B a) (c : C a b), Type}
           {E : forall (a : A) (b : B a) (c : C a b) (d : D a b c), Type}
           {F : forall (a : A) (b : B a) (c : C a b) (d : D a b c) (e : E a b c d), Type}
           {G : forall (a : A) (b : B a) (c : C a b) (d : D a b c) (e : E a b c d) (f : F a b c d e), Type}
           (fn : forall s : tele (a : A) (b : B a) (c : C a b) (d : D a b c)
                                (e : E a b c d)
               in F a b c d e,
               G s.1 s.2.1 s.2.2.1 s.2.2.2.1 s.2.2.2.2.1 s.2.2.2.2.2) :
    forall (x : A) (b : B x) (c : C x b) (d : D x b c) (e : E x b c d)
      (f : F x b c d e), G x b c d e f :=
  fun x b c d e f => fn &(x , b , c , d , e & f).

  Goal forall {A} n (x y : A) (v v' : Vector.t A n)
              (e : Vector.cons x v = Vector.cons y v')
              (P : forall n x y v v' (e : Vector.cons x v = Vector.cons y v'), Type),
      (P n x x v v eq_refl) -> P n x y v v' e.
  Proof.
    intros. revert e P X.
    revert n x y v v'.
    refine (uncurry6 _).
    unshelve refine (apply_equiv_dom _ _ _).
    shelve.
    refine (equiv_sym _).
    refine (pr2 (@example A)).
    intros.
    Transparent telescope eq.
    simpl in x.
    destruct x as (n&x&y&v&v'&e&e').
    vm_compute in X. simpl in e'.
    destruct e. destruct e'.
    vm_compute.
    unfold cong_tel_proj.
    exact X.
  Defined.

  Lemma NoConfusionPackage_isequiv {A} (a b : A) {e : NoConfusionPackage A} : Equiv (a = b) (NoConfusion a b).
  Proof.
    unshelve refine {| equiv := noConfusion |}.
    unshelve refine {| equiv_inv := noConfusion_inv |}.
    red; intros.
    apply axiom_triangle.
    red. apply noConfusion_is_equiv.
    apply axiom_triangle.
  Defined.

  (* Lemma equiv_K A {NC : NoConfusionPackage A} (x y : A) : forall p q : NoConfusion x y, p = q. *)
  (* Proof. *)
  (*   intros. *)
  (*   pose (NoConfusionPackage_isequiv x y). *)
  (*   destruct x, y; simpl in *. *)
  (*   destruct p, q. reflexivity. *)
  (*   destruct p. *)
  (*   destruct p. *)
  (*   destruct p. *)

  Equations noConf_nat (x y : nat) : Type :=
    noConf_nat 0 0 := True;
    noConf_nat (S x) (S y) := noConf_nat x y;
    noConf_nat _ _ := False.
  (* BUG if with ind *)
  Equations(noind) noConf_nat_inv (x y : nat) (e : x = y) : noConf_nat x y :=
    noConf_nat_inv x ?(x) eq_refl <= x =>
    { | 0 => I;
      | S n => (noConf_nat_inv n n eq_refl) }.

  Next Obligation.
    Transparent noConf_nat_inv.
    unfold noConf_nat_inv.
    destruct x.
    simpl. apply eq_refl.
    apply eq_refl.
  Defined.

  Lemma noConfusion_nat_k (x y : nat) (p : noConf_nat x y) : x = y.
  Proof.
    induction x in y, p |- *; destruct y.
    destruct p. reflexivity.
    destruct p.
    destruct p.
    apply cong. apply IHx.
    apply p.
  Defined.

  Lemma iseq x y : IsEquiv (noConfusion_nat_k x y).
  Proof.
    unshelve refine {| equiv_inv := noConf_nat_inv x y |}.
    apply axiom_triangle.
    apply axiom_triangle.
    apply axiom_triangle.
  Defined.

  Definition equiv' x y : Equiv (noConf_nat x y) (x = y) .
  Proof.
    refine {| equiv := noConfusion_nat_k x y |}.
    apply iseq.
  Defined.

  Lemma noConfusion_nat_k3 (x : nat) (p : noConf_nat x x) : noConfusion_nat_k x x p = eq_refl.
  Proof.
    induction x.
    simpl. destruct p. reflexivity.
    simpl. rewrite IHx.
    reflexivity.
  Defined.

  Lemma equiv_unit A (x : A) : inj (@eq_refl A x = eq_refl) <~> inj unit.
  Proof.
    refine {| equiv x := tt |}.
    unshelve refine {| equiv_inv x := eq_refl |}.
    red; intros.
    destruct x0.
    reflexivity.

    red; intros.
    revert x0.
    set (foo:=@eq_refl A x).
    clearbody foo.
    intros x0.
    apply axiom_triangle.
    apply axiom_triangle.
  Defined.

  Lemma noConf_nat_refl_true n : noConf_nat n n <~> inj unit.
  Proof.
    refine {| equiv x := tt |}.
    unshelve refine {| equiv_inv x := _ |}.
    induction n. constructor.
    apply IHn.

    red; intros.
    destruct x.
    reflexivity.
    red; intros.
    induction n.
    destruct x.
    reflexivity.
    simpl.
    apply IHn.

    simpl. intros.
    induction n ; simpl.
    destruct x. reflexivity.
    simpl.
    apply IHn.
  Defined.



  Lemma example' {A} :
    &{ Γ' : Tel &
           tele (n : nat) (x y : A) (v v' : Vector.t A n) in
        (Vector.cons x v = Vector.cons y v') <~> Γ' }.
  Proof.
    intros. eexists.
    refine (equiv_compose _ _).
    do 5 intros_tele.
    2:simpl.
    refine (equiv_compose _ _).
    refine (solution_inv_tele (A:=nat) (Vector.t A) _ _ _).

    refine (equiv_compose _ _).
    refine (reorder_tele (tele (e0 : S n = S n) in (Vector.cons x v ={ vector A ; e0} (Vector.cons y v'))) (fun ρ => inj (ρ.1 = eq_refl))).
    simpl.
    refine (equiv_compose _ _).
    refine (equiv_sym _).
    refine (equiv_tele_l _).
    refine (equiv_sym _).
    refine (injectivity_cons2 &(x, n & v) &(y, n & v')).
    refine (equiv_compose
              (C:=tele (e : x = y) in (v ={ (λ _ : A, inj (vector A n)); e} v'))
              _ _).
    refine (equiv_tele_r _).
    intros.

    unfold telescope in x0. simpl in x0.

    destruct x0.

    destruct pr2.
    destruct pr1.

    simpl in *.
    unfold injectivity_cons2.
    simpl.
    unfold noconf_equiv, equiv, equiv_sym, inv_equiv, equiv_inv.
    simpl.


    simpl.
    intros. eexists.
    refine (equiv_compose _ _).
    do 5 intros_tele.
    2:simpl.
    refine (equiv_compose _ _).
    refine (solution_inv_tele (A:=nat) (Vector.t A) _ _ _).


    refine (reorder_tele (tele (e0 : S n = S n) in (Vector.cons x v ={ vector A ; e0} (Vector.cons y v'))) (fun ρ => inj (ρ.1 = eq_refl))).
    simpl.
    refine (equiv_compose _ _).
    refine (equiv_sym _).
    refine (equiv_tele_l _).
    refine (equiv_sym _).
    refine (injectivity_cons2 &(x, n & v) &(y, n & v')).



    refine (equiv_compose _ _).
    refine (equiv_sym _).
    refine (equiv_tele_l _).
    refine (equiv' _ _).
    simpl.
    unfold equiv', equiv.
    simpl.
    refine (equiv_compose _ _).
    intros_tele.
    rewrite noConfusion_nat_k3. simpl.
    unfold telescope. intros_tele.
    refine (equiv_unit _ _).
    simpl.
    refine (equiv_compose _ _).
    refine (equiv_sym _).
    refine (equiv_tele_l _).
    refine (equiv_sym _).
    refine (noConf_nat_refl_true _).
    simpl.
    intros_tele.
    simpl.
    refine (equiv_compose _ _).
    unfold telescope.
    intros_tele.
    refine (equiv_id _).
    refine (equiv_id _).

    simpl. rewrite noConfusion_nat_k3. simpl.
    unfold telescope. intros_tele.
    refine (equiv_unit _ _).
    simpl.

    pose (lower_solution A n).
    pose (inv_equiv e &(x & v)).
    simpl in e.
    pose (telei x n in v : telu A).
    pose (sol:=lifted_solution (tele (_ : A) (n' : nat) in vector A n')).
    simpl in sol.
    simpl in t0.
    unfold e, lower_solution, equiv, equiv_inv, inv_equiv in t0. simpl in t0.
    unfold e, lower_solution, equiv, equiv_inv, inv_equiv in t0. simpl in t0.
    set (solinst :=
           sigmaI (fun x => sigma nat (fun n => vector A n)) t0.1 &(t0.2.1 & t0.2.2.1)).
    specialize (sol solinst).
    specialize (sol &(y, n & v')).
    (* specialize (sol solinst). (*&(y, n & v')).*) *)
    specialize (sol (telv A n)).
    specialize (sol (inj nat)).
    simpl in e.
    specialize (sol (fun x => S x.2.1) (fun x => S n) eq_refl eq_refl). simpl in sol.
    specialize (sol e). subst e.
    simpl in sol.
    unfold solution_left in *.
    simpl in *.
    unfold inv_equiv in sol. unfold eq_points_equiv in sol. simpl in *.
    unfold equiv_inv in *. simpl in *.
    unfold cong in sol. simpl in *.

    refine (equiv_compose
              (C:=tele (e : x = y) in (v ={ (λ _ : A, inj (vector A n)); e} v'))
              _ sol).
    refine (equiv_tele_r _).
    intros.


  
  Lemma noConfusion_nat_k2 (x y : nat) (p q : noConf_nat x y) : p = q.
  Proof.
    induction x in y, p, q |- *; destruct y.
    destruct p, q. reflexivity.
    destruct p.
    destruct p.
    simpl in p, q.
    apply IHx.
  Defined.


  Lemma noConf_HProp (x y : nat) :  (forall p q : x = y, p = q).
  Proof.
    unshelve refine (apply_equiv_dom _ _ _).
    shelve.
    refine (equiv_sym (NoConfusionPackage_isequiv x y)).
    intros x0.
    unshelve refine (apply_equiv_dom _ _ _).
    shelve.
    refine (equiv_sym (NoConfusionPackage_isequiv x y)).
    revert x0.
    revert x y. fix 1.
    unfold equiv, equiv_inv, equiv_sym, inv_equiv, NoConfusionPackage_isequiv, NoConfusion.noConfusion_nat_obligation_1;
    simpl;
    unfold equiv, equiv_inv, equiv_sym, inv_equiv, NoConfusionPackage_isequiv, NoConfusion.noConfusion_nat_obligation_1;
    simpl.
    destruct x; destruct y;
    intros. destruct x0, x.
    reflexivity.
    destruct x0.
    destruct x0.
    change (cong S x0 = cong S x1).
    apply cong.
    simpl in x0, x1.


    intros.
    simpl in x0, x1.
    pose (equiv (NoConfusionPackage_isequiv x y) x0).
    pose (equiv (NoConfusionPackage_isequiv x y) x1).
    specialize (noConf_HProp _ _ n n0).
    simpl.
    subst n n0.
    change (
        @equiv (@NoConfusion nat NoConfusionPackage_nat x y) (@Logic.eq nat x y)
               (@equiv_sym (@Logic.eq nat x y) (@NoConfusion nat NoConfusionPackage_nat x y)
                           (@NoConfusionPackage_isequiv nat x y NoConfusionPackage_nat)))
      with (@inv_equiv _ _ (@NoConfusionPackage_isequiv nat x y NoConfusionPackage_nat)) in *.
    rewrite equiv_inv_equiv in noConf_HProp.
    rewrite equiv_inv_equiv in noConf_HProp.
    apply noConf_HProp.
  Defined.


  Eval compute in noConf_HProp.
  Lemma noConf_HProp : (forall x y : nat, NoConfusion_nat x y) <~> (forall x y : nat, forall p q : x = y, p = q).
  Proof.
    refine (equiv_compose _ _).
    refine (equiv_sym _).
    refine (apply_equiv_codom _).
    intros x. refine (apply_equiv_codom _).
    intros x0.
    refine (NoConfusionPackage_isequiv x x0).
    simpl.

    unshelve refine {| equiv f := fun x y p q => _ |}.
    pose (f x y).
    transitivity e.
    destruct p.



    unshelve refine {| equiv_inv f := fun x y => _ |}.
    refine (match f x y with
            | left p => p
            | right e => _
            end).

  
  Lemma noConf_K : (forall x y : nat, NoConfusion_nat x y) <~> (forall x y : nat, { x = y } + { x <> y }).
  Proof.
    refine (equiv_compose _ _).
    refine (equiv_sym _).
    refine (apply_equiv_codom _).
    intros x. refine (apply_equiv_codom _).
    intros x0.
    refine (NoConfusionPackage_isequiv x x0).
    simpl.

    unshelve refine {| equiv f := fun x y => left (f x y) |}.
    unshelve refine {| equiv_inv f := fun x y => _ |}.
    refine (match f x y with
            | left p => p
            | right e => _
            end).
