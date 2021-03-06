:- [general].
my_retract(X):-retractall(signal(in(_,X),_)),retract(signal(output(X),_)).
my_fulladder_retract(X):-retractall(signal(in(_,X),_)),retract(signal(output1(X),_)),retract(signal(output2(X),_)).
my_xor(X):-my_connect(in(1,X),in(1,a1)),my_connect(in(1,X),in(1,a4)),my_connect(in(2,X),in(1,a2))
			,my_connect(in(2,X),in(1,a3)),my_not(a1),my_not(a3),my_connect(output(a1),in(2,a2)),
			my_connect(output(a3),in(2,a4)),my_and(a2),my_and(a4),my_connect(output(a2),in(1,a5)),
			my_connect(output(a4),in(2,a5)),my_or(a5),my_connect(output(a5),output(X)),
			my_retract(a1),my_retract(a2),my_retract(a3),my_retract(a4),my_retract(a5),!.
my_xor(X):- assert(signal(output(X),0)),!.

my_fulladder(X):- my_connect(in(1,X),in(1,b1)),my_connect(in(2,X),in(2,b1)),my_xor(b1),my_connect(output(b1),in(1,b2)),
				  my_connect(in(3,X),in(2,b2)),my_xor(b2),signal(output(b2),X1),my_connect(in(1,X),in(1,b3)),
				  my_connect(in(1,X),in(1,b4)),my_connect(in(2,X),in(2,b3)),my_connect(in(2,X),in(1,b5)),
				  my_connect(in(3,X),in(2,b4)),my_connect(in(3,X),in(2,b5)),my_and(b3),my_and(b4),my_and(b5),
				  my_connect(output(b3),in(1,b6)),my_connect(output(b4),in(2,b6)),my_or(b6),
				  my_connect(output(b6),in(1,b7)),my_connect(output(b5),in(2,b7)),my_or(b7),signal(output(b7),X2),
				  assert(signal(output1(X),X1)),assert(signal(output2(X),X2)),my_retract(b1),my_retract(b2),
				  my_retract(b3),my_retract(b4),my_retract(b5),my_retract(b6),my_retract(b7),!.
my_fulladder(X):- assert(signal(output1(X),0)),assert(signal(output1(X),0)),!.

assign_inputs([],_,_).
assign_inputs([H|T],G,V) :- assert(signal(in(V,G),H)),V1 is V+1,assign_inputs(T,G,V1).
verify(G,L,O):- G = and,assign_inputs(L,t1,1),my_and(t1),signal(output(t1),X1),my_retract(t1),!,O is X1.
verify(G,L,O):- G = or,assign_inputs(L,t2,1),my_or(t2),signal(output(t2),X1),my_retract(t2),!,O is X1.
verify(G,L,O):- G = xor,assign_inputs(L,t3,1),my_xor(t3),signal(output(t3),X1),my_retract(t3),!,O is X1.
verify(G,L,O):- G = fulladder,assign_inputs(L,t4,1),my_fulladder(t4),
						signal(output1(t4),X1),signal(output2(t4),X2),my_fulladder_retract(t4),!, O = [X1,X2].
verify(_,_,_).

automated_checker(A) :- A = fulladder,!, fulladder_truthtable([P,Q,R],[X,Y]), verify(fulladder, [P,Q,R], O), O = [X,Y].
automated_checker(A) :- A = xor,!, xor_truthtable([P,Q],X), verify(xor, [P,Q], O), O is X.

addone([0],0,[1]).
addone([1],1,[0]).
addone([H|T],B,C):-addone(T,B1,C1),B1 = 1, H = 1 ,B is 1,C = [0|C1].
addone([H|T],B,C):-addone(T,B1,C1),B1 = 1, H = 0 ,B is 0,C = [1|C1].
addone([H|T],B,C):-addone(T,B1,C1),B1 = 0,B is 0,C = [H|C1]. 
allones([]).
allones([1|T]):- allones(T).
changetozeros([],[]).
changetozeros([1|T],[0|X]):-changetozeros(T,X).
nextsequence([],[]).
nextsequence([0],[1]).
nextsequence(A,Y):- addone(A,0,T1),Y = T1.


my_append(L,[],L).
my_append([H|L2],[H|T],L1) :- my_append(L2,T,L1),!.

my_flatten([], []).
my_flatten([H|L],P) :- is_list(H),my_flatten(L,L1),my_flatten(H,H1),!,my_append(P,H1,L1).
my_flatten([H|L],P)	:- my_flatten(L,L1),!,my_append(P,[H],L1).

%expected

expected(P,X,A):-allones(X),truthtable(P,X,A1),A = [A1],!.
expected(P,X,A):-nextsequence(X,Y),expected(P,Y,A1),truthtable(P,X,A2),A=[A2|A1].

%endexpected

%calculate
calculate(P,X,A):-allones(X),verify(P,X,A1),A = [A1],!.
calculate(P,X,A):-nextsequence(X,Y),calculate(P,Y,A1),verify(P,X,A2),A=[A2|A1].
%endcalculate

calculate_out(P,A):-P =xor,calculate(P,[0,0],A).
calculate_out(P,A):-P =fulladder,calculate(P,[0,0,0],A1),my_flatten(A1,A).
calculate_out(_,_).
expected_out(P,A):- P = xor,expected(P,[0,0],A).
expected_out(P,A):- P = fulladder,expected(P,[0,0,0],A1),my_flatten(A1,A).
expected_out(_,_).

checkfault(P):- calculate_out(P,A),expected_out(P,B),A \= B,write('Gate is fault').
checkfault(_):- write('Gate is alright').