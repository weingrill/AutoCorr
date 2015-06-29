UNIT U_FTG2;                           {Last mod by JFH on 03/18/96}

(* *****************************************************************************

 UNIT FOR PERFORMING GLASSMAN FFT AND INVERSE

 Note that with the Glassman FFT, the number of points does not have to be a
     power of 2.  Instead, the transform will take advantage of any factoring
     that can be done on the number of points.  Which means that if the number
     of points is prime, the transform will not be "fast" at all.

 Rev. 08/30/00 by JFH for Delphi-5 by going to dynamic arrays required no
     change other than the removal of tComplexArray.  Also fixed error in
     CAScale and removed unused variables in GFTInnerLoop.
 Rev. 03/18/96 by JFH for Delphi-2 by removing def of "PI" and going
     to open arrays.
 Pgm. 03/27/89 by J F Herbster

***************************************************************************** *)

INTERFACE

TYPE
  tComplex = record r,i: single end;
  tFactorArray = array [1..32] of integer;

Procedure CxAdd (var sum: tComplex; a,b: tComplex);

Procedure CxMpy (var prd: tComplex; a,b: tComplex);

Procedure CAScale
   (const Inp: array of tComplex; var aOut: array of tComplex;
    A: single; N: integer);

Procedure GetFactors
    (n: integer; var factors: tFactorArray; var nf: integer);

Procedure CFTG
   (const Cinp: array of tComplex; var Cout, CScr: array of tComplex;
    NC: integer);
{ returns a complex Fourier transform of the Cinp array into the Cout array.
  The CScr (scratch) array may be same as the input array. The transform will
  be from the time to the frequency domain if NC is positive of the number
  of complex points to be converted or from the frequency to the time domain
  if NC is the negative of the number of complex points.  The only difference
  between the two is just a divide by the number of points. }

IMPLEMENTATION {===============================================================}

Procedure CxAdd (var sum: tComplex; a,b: tComplex);
    begin sum.r:=a.r+b.r; sum.i:=a.i+b.i end;

Procedure CxMpy (var prd: tComplex; a,b: tComplex);
    begin prd.r:=a.r*b.r-a.i*b.i; prd.i:=a.i*b.r+a.r*b.i end;

Procedure CAScale
   (const Inp: array of tComplex; var aOut: array of tComplex;
    A: single; N: integer);
Var i: word;
Begin
  For i := N-1 {JFH, 08/30/00} downto 0 do
       begin aOut[i].r:=A*Inp[i].r; aOut[i].i:=A*Inp[i].i; end;
End;

Procedure GetFactors(n: integer; var factors: tFactorArray; var nf: integer);
{ Factor n into its nf primes in array factors[]. }
  Var nr,tf,q: word;
Begin
  nr:=n; q:=nr; tf:=2; nf:=1;
  While tf<q do begin
      q:=nr div tf;
      if q*tf=nr
        then begin factors[nf]:=tf; Inc(nf); nr:=q end
        else Inc(tf);
    end{while};
    factors[nf]:=nr;
  End;

Procedure GFTInnerLoop
   (const Inp: array of tComplex; var aOut: array of tComplex;
    NC: integer; X, S: integer);
Var WDL1,WD,CTemp,CTemp2: tComplex;  N,L1,L,K,D,I,U,H: word; a: single;
Begin
  N:=abs(NC); D:=N div S; I:=0;
  a:=(-(2*Pi)*D)/NC; WD.r:=cos(a); WD.i:=sin(a);
  For L1:=1 to S do
    begin
      If L1=1
        then begin WDL1.r := 1.0; WDL1.i := 0.0 end
        else CxMpy(WDL1,WDL1,WD);
      For L:=1 to D do
        begin
          K:= (L+(L1-1)*D*X) mod N;
          U:=K+(X-1)*D;
          CTemp:=Inp[U-1];
          For H:=2 to X do
            begin
              CxMpy (CTemp,CTemp,WDL1);
              U:=U-D; CTemp2:=Inp[U-1];
              CxAdd (CTemp,CTemp,CTemp2);
            end;
          aOut[i]:=CTemp;
          Inc(I);
        end{L-loop};
    end{L1-loop};
End;

Procedure CFTG
   (const Cinp: array of tComplex; var Cout, CScr: array of tComplex;
    NC: integer);
{ CScr array may be same as the Cinp array.}
Var  a: single; j,n,x,s,nf: integer; r: tFactorArray;
Begin

{ Let n be the number of complex elements in the array.}
  n:=abs(NC);
  If n=0
    then exit;

  GetFactors(n,r,nf);          { Factor n into its primes.}

{ Now do the transformation.}
  s:=1;
  For j:=1 to nf do
    begin
      x:=r[j]; s:=s*x;
      If j=1
        then GFTInnerLoop (CInp, COut, NC, X, S)
        else if Odd(j)
          then GFTInnerLoop (CScr, COut, NC, X, S)
          else GFTInnerLoop (COut, CScr, NC, X, S);
    end{j-loop};

{ Finally, check for the required scaling and that data is in out array.}
  If nc < 0 then a:=1.0 else a:=1.0/n;
  If not Odd(nf)
    then CAScale({in}CScr, {out}COut, a, N)
    else if a<>1
      then CAScale(COut, COut, a, N);

End;

END.

