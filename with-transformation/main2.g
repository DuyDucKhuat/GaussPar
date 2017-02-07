### TODO ###
## rename variables, e.g.:
## t -> ListOfPivotColumns
### TODO ###
###############################
# function ClearColumn
# Input:
#   f - Field
#   H - Input matrix
#   t - Bitlist of pivot columns positions
#   R - Residue of above block after echolonization
#
# Output:
#   [ R, t, T ]
#   R - ??
#   t - ??
#   T - ??
###############################
ClearColumn := function( f, H, t, R, Q )
    local tmp, Chi, ct, HH, QQ, Q1,Q2,Q3, tt, RR, ttt, RRR, i, RRn, A, AA, T, M, K, E, s, u;
   
   # if not Length(t) = DimensionsMat(H)[2] then
   #     Error( "Length of bitlist t does not match dimensions of H!" );
   # fi;

    #### INITIALIZATION ####
    ## Residue R was empty. Thus matrix above has full column-rank.
    if not IsEmpty(t) and IsEmpty( R ) then
        A := H;
        M := [];
        E := [];
        K := [];
        s := [];
        RR := [];
        tt := [];
        ttt := t;
        QQ := A*Q;
        u := 0 * t;
        T:=[A, M, E, K, s, u];
        return [RR, ttt, T, Q, QQ];
    fi;

    ## First step (i=1,  i block row) or all matrices above have rank 0
    if IsEmpty( t ) then
        # A is empty iff this case happens, Q is empty then aswell
        A := [];
        HH := H;
    else
        # Column Extraction
        tmp := CEX( f, BitstringToCharFct(t), H );
        A := tmp[1]; AA := tmp[2];
        # Reduce H to (0|HH)
        # Mult Add
        HH := AA + A*R;
    fi;
    if IsEmpty( A ) then
        # A is empty iff this case happens, Q is empty then aswell
        QQ := [];
    else
        QQ := A*Q;
    fi;
 
 
    #### END INITIALIZATION ####

    # Echelonization
    tmp := ECH( f, HH );
    M:=tmp[1];K:=tmp[2];RR:=tmp[3];s:=tmp[4];tt:=tmp[5];
    #Error( "Break Point - echel" );

    # TODO complement then extend?
    if IsEmpty(t) then Chi := tt;
    else
     Chi := 0*[1..DimensionsMat(H)[2]];ct:=1;
     if not tt=[] then
        for i in [1..Length(Chi)] do
            if t[i]=0 then
                if tt[ct]=1 then Chi[i] := 1; fi;
                ct:= ct+1;
            fi;
        od;
     fi;
    fi;

    ## Are we running into any special cases, where return values
    ## of the above echelonization are empty?
    # The case K empty is handled by UpdateRow.
    #
    # The following are equivalent:
    # s is empty
    # tt is empty
    # M is empty
    #
    # This only happens when A*R + AA = 0
    if ForAny( [ M, s, tt ], IsEmpty ) then
        M := [];
        E := [];
        K := [];
        s := [];
        RR := R; # Residue does not change
        ttt := t;
        u := 0 * t;
        T:=[A, M, E, K, s, u];
        return [RR, ttt, T, Q, QQ];
    fi;
    # If RR is empty, but tt is not, then the bitstring tt, representing
    # the positions of the new pivot columns, is AllOne.
    # In this case, there is nothing to be done here.

    #Error( "Break Point - before CEX new residue" );
    tmp := CEX( f, BitstringToCharFct(tt), R );
    E:=tmp[1];RRn:=tmp[2];
    ## Update the residue and the pivot column bitstring
    tmp := PVC( BitstringToCharFct(t), BitstringToCharFct(Chi) );
    ttt:=CharFctToBitstring(DimensionsMat(H)[2], tmp[1]); u:=tmp[2];
    # Error( "Break Point - after CEX new residue" );
    
    T:=[A, M, E, K, s, u];

    ## Did column extraction return empty values?
    if IsEmpty(E) then ## if the above was all zero but we got new pivots in the current iteration
        
        Q := M;
        QQ := K;
        return [RR, ttt, T, Q, QQ];
    fi;

    ## RRn is empty, iff. the new pivot columns completely
    ## annihilate the old residue.
    if IsEmpty(RRn) then
        RR := [];
    else
        RRR:=RRn+E*RR;
        RR := RRF( RRR, RR, u );
    fi;
     
    tmp := REX( f,BitstringToCharFct(s),QQ );
    Q1:=tmp[1];Q2:=tmp[2];

    Q3 := M* Q1;
    Q := Q + E*Q3;
    QQ := Concatenation(TransposedMat(K*Q1+Q2),TransposedMat(K) );
    QQ := TransposedMat(QQ);

    Q := RRF( TransposedMat(Concatenation(TransposedMat(Q),TransposedMat(E*M) )),TransposedMat(Concatenation(TransposedMat(Q3),TransposedMat(M) )),u );

   # Q := RRF( TransposedMat(RRF(TransposedMat(Q),TransposedMat(E*M) ,u)),TransposedMat(RRF(TransposedMat(Q3),TransposedMat(M),u )),u );
    return [RR, ttt, T, Q, QQ ];
end;

UpdateRow := function( f, T, H, Bjk )
 local A, E, M, K, s, u,  tmp, Z, V, X, W, S, B;
 B := Bjk;
 A:=T[1];M:=T[2];E:=T[3];K:=T[4];s:=T[5];u:=T[6];
 
 ###
 # If A is empty, there are no rowoperations form above to consider
 ###
 if IsEmpty(A) then
  Z := H;
 else 
  Z := A*B+H;
 fi;

 tmp := REX( f, BitstringToCharFct(s), Z );
 V:=tmp[1];W:=tmp[2];
 ###
 # If V is empty, then there where no operations exept from A
 # in this case there is nothing more to update
 ###
 if IsEmpty(V) then
  return [Z,B]; 
 else 
  X:=M*V;
 fi;

 S:= E*X+B;
 B:=RRF( S, X, u );
 
 ###
 # if K is empty, then s is the all-one-bitstring and there are no non-pivot rows
 # which would change according to K. So K should be empty and there is nothing more to update
 ###
 if not IsEmpty(K) then
  # s is neither empty nor all-one at this point
  H := K*V+W;
 else
  H := W;
 fi;
 

 return [H, B];
end;

UpdateTrafo := function( f, T, H, Bjk )
 local A, E, M, K, s, u,  tmp, Z, V, X, W, S, B;
 B := Bjk;
 A:=T[1];M:=T[2];E:=T[3];K:=T[4];s:=T[5];u:=T[6];
 
 ###
 # If A is empty, there are no rowoperations form above to consider
 ###
 if IsEmpty(B) then
  Z := H;
 else 
  Z := A*B+H;
 fi;

 tmp := REX( f, BitstringToCharFct(s), Z );
 V:=tmp[1];W:=tmp[2];
 ###
 # If V is empty, then there where no operations exept from A
 # in this case there is nothing more to update
 ###
 if IsEmpty(V) then
  return [Z,B]; 
 else 
  X:=M*V;
 fi;

 S:= E*X+B;
 B:=RRF( S, X, u );
 
 ###
 # if K is empty, then s is the all-one-bitstring and there are no non-pivot rows
 # which would change according to K. So K should be empty and there is nothing more to update
 ###
 if not IsEmpty(K) then
  # s is neither empty nor all-one at this point
  H := K*V+W;
 else
  H := W;
 fi;

 return [H, B];
end;

Step1 := function( A,n )
 local S,C, cur,f, nrr, Pivots, tmp,K,rct,   i, j, k, B,Q,Qj, T, Rj, H, tj, V, W;
 f := DefaultFieldOfMatrix( A );
 C := ChopMatrix( n, A );
 nrr := DimensionsMat(A)[1];
 B := [];S:=0*[1..DimensionsMat(A)[1] ]; K:=[]; Q:=[]; #Init B as nxn; S remembers the extraction of pivotrows
 for i in [1..n] do
  B[i] :=[]; K[i]:=[]; Q[i]:=[]; 
  for j in [1..n] do
   B[i][j]:=[];
   Q[i][j]:=[];
   K[i][j]:=[];
  od;
 od;
 Rj := [];
 tj := [];
 Qj := [];
 rct := 1;

 for i in [1..n] do
  Pivots := [1..nrr/n];
  for j in [1..n] do
   cur := 1;
   H := C[i][j];

   if i = 1 then
    tj[j] := [];
    Rj[j] := [];
    Qj[j] := []; 
   fi;
  
   if IsEmpty(H) then continue; fi;
   tmp := ClearColumn( f, H, tj[j], Rj[j], Qj[j] );
   Rj[j] := tmp[1];
   tj[j] := tmp[2];
   T := tmp[3];
   Qj[j] := tmp[4];
   K[i][j] := tmp[5];
   
   for k in [ 1 .. Length(T[5]) ] do
  # Error( "Break Point - after ClearCol new residue" );
       if  T[5][k]=1 then
          S[ (i-1)*nrr/n + Pivots[cur]  ] := j;
          Remove(Pivots,cur); 
       else
          cur := cur + 1;
       fi;
   od;
   

   #Error( "Break Point - after ClearCol new residue" );
   for k in [j+1..n] do
    if i = 1 then
      B[j][k]:=[];
    fi; 
    
    tmp := UpdateRow( f, T, C[i][k], B[j][k] );
    C[i][k] := tmp[1];
    B[j][k] := tmp[2];
   od;
   
   for k in [1..j-1] do 
    if i = 1 then
      Q[j][k]:=[];
    fi; 

    tmp := UpdateTrafo( f, T, K[i][k], Q[j][k] );
    K[i][k] := tmp[1];
    Q[j][k] := tmp[2];
   
    #Error( "Break Point - before CEX new residue" );
   od;
  od;
 od;

 return [ C, B, Rj, tj, K, Qj, Q,S ];
end;

BackClean := function( f,k,n,B,t,C,M )
 local tmp,i,j,X,m;
 
 for i in [1..n] do
  for j in [1..n] do
   C[i][j] := MutableCopyMat(C[i][j]);
   M[i][j] := MutableCopyMat(M[i][j]);
  od;
 od;
 for j in [1..k-1] do
  tmp := CEX( f,BitstringToCharFct( t ),B[j][k] );
  X := tmp[1]; C[j][k] := tmp[2];
  for m in [k..n] do
   if not IsEmpty( C[k][m] ) then
    C[j][m] := C[j][m] + X*C[k][m];
   fi;
  od;
  for m in [1..n] do
   if not IsEmpty( M[k][m] ) then
    M[j][m] := M[j][m] + X*M[k][m];
   fi;
  od;
 od; 
 
 return [C,M];
end;

InsertBlock := function( f,X,t,R,C,i,j,ct,n,rct )
 local k,l,newct,B,Rct;
 newct:=0; Rct:=1; B := MutableCopyMat(X);
 if i=j then
  #if IsEmpty(R[j]) then return [B,ct]; fi;
 
  for k in [1..Length(t[j])] do
   if t[j][k] = 1 then
    B[ct+newct][Length(t[j])*(j-1)+k] := -One(f);
    newct := newct+1;
   else
    for l in [1..DimensionsMat(R[j])[1]] do
     B[ct-1+l][Length(t[j])*(j-1)+k] := R[j][l][Rct];
    od;
    Rct := Rct+1;
   fi;
  od;
 fi;
 
 if not i=j then
  if IsEmpty(C[i][j]) then return [B,ct]; fi;
  for k in [1..DimensionsMat(C[i][j])[1] ] do
   newct := 0;
   for l in [1..DimensionsMat(C[i][j])[2] ] do
    if not IsEmpty(t[j]) then
     while t[j][l+newct] = 1 do newct := newct+1; od;
    fi;
    B[rct-1+k][ (DimensionsMat(X)[2]/n)*(j-1)+l+newct ] := C[i][j][k][l];
   od;
  od;
  newct := 0;
 fi;

 return [B,ct+newct];
end;

BuildRowPerm := function( f,t )
 local S,Id,i;
 Id := IdentityMat(Length(t),f);
 S:=[];
 for i in [1..Length(t)] do
  S[i]:=Id[t[i]];
 od;
 
 return S;
end;

Step2 := function( f,n,nrows,ncols,returnList )
 local M,Mj,MM,KK,shift,K,list,rank,i,j,S,s,current,Id,rct,ct,C,B,t,R,tmp, k,T;
 C := returnList[1];
 B := returnList[2];
 t := returnList[4];
 R := returnList[3];
 M := returnList[7];
 Mj := returnList[6];
 K := returnList[5];
 T := [];
 S := returnList[8];

 for k in [1..n] do
  if not IsEmpty(t[k]) then
   T := Concatenation( T,t[k] ); 
  else 
   T := Concatenation( T,0*[1..ncols/n] );
  fi;
  C[k][k] := R[k];
  M[k][k] := Mj[k];
 od;
s:=[];

 for k in [1..n] do
  tmp := BackClean( f,n-k+1,n,B,t[n-k+1],C,M );
  C := tmp[1]; M:=tmp[2];
 od;
 
 #Error( "After BackClean" );
 ###
 # We now rearrange the results so that we can return the gauss normal form
 ### 
 rank := 0;
 for k in [1..Length(T)] do
  if T[k] = 1 then rank := rank +1; fi;
 od;
 
 B := MutableCopyMat(NullMat( rank,ncols,f ));
 MM := MutableCopyMat(NullMat( rank,rank, f ));
 KK := MutableCopyMat(NullMat( nrows-rank,rank,f ));
 Id := IdentityMat( rank, f );

 ## Build echelonform
 ct := 1;
 for k in [1..n] do
  rct := ct;
  for i in [k..n] do
   tmp := InsertBlock( f,B,t,R,C,k,i,ct,n,rct );
   B := tmp[1]; ct := tmp[2];
  od;
 od;

 ## Build M
 ct :=1; rct:=1;
 for i in [1..n] do
  ct := 1;
  for k in [1..n] do
   if IsEmpty(M[i][k]) then
    if not IsEmpty(M[k][k]) then
        ct := ct + DimensionsMat(M[k][k])[2];
    fi; continue; fi;
   MM{[rct..rct+DimensionsMat(M[i][k])[1]-1]}{[ct..ct+DimensionsMat(M[i][k])[2]-1]} := M[i][k];
  ct := ct + DimensionsMat(M[k][k])[2];
  od;
  if not IsEmpty(M[i][i]) then 
   rct := rct + DimensionsMat(M[i][i])[1];
  fi;
 od;
 #Error("somethings wrong"); 
 ## Build K 
 ct :=1; rct:=1; tmp := 0;
 for i in [1..n] do
  ct :=1; tmp := 0;
  for k in [1..n] do
   if k=1 then
     if IsEmpty(K[i][k]) then
       if S[rct]=0 and rct < Length(S) then
         tmp := 1;
         if IsEmpty(M[i][k]) then
           if not IsEmpty(M[i][i]) then
            tmp := DimensionsMat(M[i][i])[1];
           fi;
         else
            tmp := DimensionsMat(M[i][i])[1] - DimensionsMat(M[i][k])[1];
         fi;
       fi;
     fi;
   fi; 
   if IsEmpty(K[i][k]) then 
    if not IsEmpty(M[k][k]) then
        ct := ct + DimensionsMat(M[k][k])[2];
    fi; continue; fi;
   KK{[rct..rct+DimensionsMat(K[i][k])[1]-1]}{[ct..ct+DimensionsMat(K[i][k])[2]-1]} := K[i][k];
  ct := ct + DimensionsMat(K[i][k])[2];
  tmp := DimensionsMat(K[i][k])[1];
  od;
  rct := rct +tmp;
 od;

 if  not rank = nrows then
    Id := IdentityMat( nrows-rank,f );
    K := NullMat( nrows-rank,rank,f );
    K := TransposedMat( Concatenation( TransposedMat(MM),K ) );
    Id := TransposedMat( Concatenation( TransposedMat(KK),Id ) );
    KK := Concatenation( K,Id );
 else
    KK := MM;
 fi;  
 return [B,BuildPermutationMat( f,T ),MM,KK,s,S];

end;

CompletionOfRowPerm := function( P )
 local Id, rank,f,nr,nc,i;
 f := DefaultFieldOfMatrix( P );
 rank := DimensionsMat( P );
 nr := rank[1]; nc := rank[2];
 rank := Rank( P );
 Id := IdentityMat( nc,f );
 for i in [ 1 .. nc] do
    if TransposedMat(P)[i] = TransposedMat( P )[i]*Zero(f) then
        Add(P,Id[i]);
    fi;       
 od;

 return P;
end;

GaussParallel := function( A )
 local i,ct,k,f,n,l,rank,nrows,ncols, S,M,K,pivotsList;
 f := DefaultFieldOfMatrix( A );
 nrows := DimensionsMat(A)[1];
 ncols := DimensionsMat(A)[2];
 n := Gcd( nrows, ncols );
 pivotsList := [];
 for i in [ 1 .. n+1 ] do
     pivotsList[i] := [];
 od;
 
# Error( "Break Point - before Step1" );
 l := Step2( f,n,nrows,ncols, Step1( A,n ));
 # It remains to reorder M and K according to S
 for i in [ 1 .. nrows ] do
     if l[6][i] = 0 then
         Add(pivotsList[n+1],i);
     else
         Add(pivotsList[l[6][i]],i);
     fi;
 od;
 ct := 1;
 M := [];
 rank := nrows - Length(pivotsList[n+1]);
 for i in [ 1 .. n+1 ] do
     for k in [ 1 .. Length(pivotsList[i]) ] do
        M[pivotsList[i][k]] := TransposedMat(l[4])[ct];
        ct := ct + 1;
     od;
 od;
 #Error ("look at results");
 S := TransposedMat(M);
 M := S{[1..rank]}{[1..nrows]};
 if not rank = nrows then
    K := S{[rank+1..nrows]}{[1..nrows]};
 else
    K := [];
 fi;

 #S := CompletionOfRowPerm( l[5] );
 return rec(vectors := -l[1],coeffs := -M,relations := K,
columnPermutation := l[2] );
end;

TestGaussParallel := function( nr,nc,iter )
 local i,test,A,bools,gap;
 
 bools:=[]; 
 for i in [1..iter] do
  A := RandomMat(3*nr,nc,GF(5));
  A[1] := Zero(GF(5))*A[1];
  A := RandomMat(nc,2*nr,GF(5)) * A;
  
  test := GaussParallel( A );
  gap := EchelonMatTransformation(A);

  bools[i] := test.vectors = gap.vectors
  and test.coeffs = gap.coeffs
  and test.relations = gap.relations;
  if bools[i] = false then
    return A; 
  fi;
 od;
 return true;
end;
 




