unit UMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtDlgs, StdCtrls, math,u_ftg2, ExtCtrls;

const
  MAXPTS=256;
  MAXPT2=MAXPTS DIV 2; // = MAXPTS/2
  MAXPT4=MAXPTS DIV 4; // = MAXPTS/4

type
  TForm1 = class(TForm)
    Button1: TButton;
    OPDLoad: TOpenPictureDialog;
    Button2: TButton;
    Label1: TLabel;
    ResImage: TImage;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
    Bmp1,Bmp2: TBitmap;
    img: array [0..MAXPTS-1,0..MAXPTS-1] of tcomplex; // contains the imagedata
    dom1,dom2: array [0..MAXPTS-1,0..MAXPTS-1] of tcomplex; // contains the fourier data
    //res: array [0..MAXPTS-1,0..MAXPTS-1] of tcomplex; // contains the resulting image
    function colcode(c:single):tcolor;
  public
    { Public declarations }
    procedure Autocorrelation(Image1, Image2: TBitmap; var dx,dy,corr: single);
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

function isval(c: single): byte;
begin
  if Round(c)=127 then result := 255 else result := 0;
end;

function conj(c: tcomplex):tcomplex;
begin
  result.r :=  c.r;
  result.i := -c.i;
end;

function TForm1.colcode(c:single):tcolor;
var r,g,b: byte;
begin
  if c<127 then b:=Round(255-c*2) else b:= 0;
  if c>127 then r:=Round((c-127)*2) else r:= 0;
  if c<127 then g:=255-b else g:=255-r;
  Result := RGB(r,g,b);
end;


procedure TForm1.Autocorrelation(Image1, Image2: TBitmap; var dx,dy,corr: single);
type
  TRGBValue = packed record
    Blue: Byte;
    Green: Byte;
    Red: Byte;
    reserved: Byte;
  end;
var x,y,dimx,dimy: integer;
    cin,cout: array [0..MAXPTS-1] of tComplex;
    c,csum,cmax: single;
    t: tcomplex;
    Pixel : ^TRGBValue;
begin
  dimx := MAXPTS;
  dimy := MAXPTS;
  // transfer image to array
  cmax := 255;
  for y:=0 to dimy-1 do
  begin
    for x:=0 to dimx-1 do
    begin
      img[x,y].r := GetGValue(Image1.Canvas.Pixels[x+320-MAXPT2,y+240-MAXPT2]); // just take green, needs to be optimized
      if img[x,y].r<cmax then cmax :=img[x,y].r;
      if (x<MAXPT4) or (x>MAXPTS-MAXPT4) or (y<MAXPT4) or (y>MAXPTS-MAXPT4) then img[x,y].r := 0;
      img[x,y].i := 0.0;
    end;
  end;

  // unbias
  if cmax>0 then
    for y:=0 to dimy-1 do
      for x:=0 to dimx-1 do
        img[x,y].r := img[x,y].r-cmax;

  // calculate rows
  for y:=0 to dimy-1 do
  begin
    for x:=0 to dimx-1 do cin[x] := img[x,y];
    CFTG(cin,cout,cin,dimx); // Forward FFT;
    for x:=0 to dimx-1 do img[x,y] := cout[x];
  end;

  // calculate columns
  for x:=0 to dimx-1 do
    begin
      for y:=0 to dimy-1 do cin[y] := img[x,y];
      CFTG(cin,cout,cin,dimy); // Forward FFT;
      for y:=0 to dimy-1 do dom1[x,y] := cout[y];
    end;

  // perform second image
  // transfer image to array
  cmax := 255;
  for y:=0 to dimy-1 do
    for x:=0 to dimx-1 do
    begin
      img[x,y].r := GetGValue(Image2.Canvas.Pixels[x+320-MAXPT2,y+240-MAXPT2])*10; // just take green, needs to be optimized
      if img[x,y].r<cmax then cmax :=img[x,y].r;
      if (x<MAXPT4) or (x>MAXPTS-MAXPT4) or (y<MAXPT4) or (y>MAXPTS-MAXPT4) then img[x,y].r := 0;
      img[x,y].i := 0.0;
    end;

  // unbias
  if cmax>0 then
    for y:=0 to dimy-1 do
      for x:=0 to dimx-1 do
        img[x,y].r := img[x,y].r-cmax;

  // calculate rows
  for y:=0 to dimy-1 do
  begin
    for x:=0 to dimx-1 do cin[x] := img[x,y];
    CFTG(cin,cout,cin,dimx); // Forward FFT;
    for x:=0 to dimx-1 do img[x,y] := cout[x];
  end;

  // calculate columns
  for x:=0 to dimx-1 do
    begin
      for y:=0 to dimy-1 do cin[y] := img[x,y];
      CFTG(cin,cout,cin,dimy); // Forward FFT;
      for y:=0 to dimy-1 do dom2[x,y] := cout[y];
    end;

  // conjugate
  for y:=0 to dimy-1 do
    for x:=0 to dimx-1 do
      dom2[x,y] := conj(dom2[x,y]);

  // multiply
  for y:=0 to dimy-1 do
    for x:=0 to dimx-1 do
    begin
      CxMpy(img[x,y],dom1[x,y],dom2[x,y]);
    end;

 {
    // inverse FFT routine

    // transfer resulting matrix to domain matrix
    for y:=0 to dimy-1 do
      for x:=0 to dimx-1 do
        dom2[x,y] := img[x,y];

    // calculate columns
    for x:=0 to dimx-1 do
    begin
      for y:=0 to dimy-1 do cin[y] := dom2[x,y];
      CFTG(cin,cout,cin,-dimy); // reverse FFT;
      for y:=0 to dimy-1 do dom2[x,y] := cout[y];
    end;

    // calculate rows
    for y:=0 to dimy-1 do
    begin
      for x:=0 to dimx-1 do cin[x] := dom2[x,y];
      CFTG(cin,cout,cin,-dimx); // reverse FFT;
      for x:=0 to dimx-1 do img[x,y] := cout[x];
    end;

}
  dx := 0; dy := 0; csum := 0; cmax := 0;
  Image2.Width := MAXPTS;
  Image2.Height := MAXPTS;
  for y:=0 to dimy-1 do
    for x:=0 to dimx-1 do
    begin
      c := sqrt(sqr(img[x,y].r)+sqr(img[x,y].i));
      if c>=cmax then
      begin
        dx := x;
        dy := y;
        cmax := c;
      end;
    end;
  for y:=0 to dimy-1 do
    for x:=0 to dimx-1 do
    begin
      c := sqrt(sqr(img[x,y].r)+sqr(img[x,y].i))*255/cmax;
      Image2.Canvas.Pixels[(x+MAXPT2) MOD MAXPTS,(y+MAXPT2) MOD MAXPTS]:= colcode(c);//RGB(Round(c),0,Round(255-c));
    end;
  if dx>MAXPT2 then dx := dx-MAXPTS;
  if dy>MAXPT2 then dy := dy-MAXPTS;
  Image2.SaveToFile('AutoCorr.bmp');
  ResImage.Picture.Bitmap.LoadFromFile('AutoCorr.bmp');
  ResImage.Canvas.FrameRect(Rect(MAXPT2+Round(dx)-8,MAXPT2+Round(dy)-8,MAXPT2+Round(dx)+8,MAXPT2+Round(dy)+8));
  corr := cmax;
end;

// *** Delphi Routines ***

procedure TForm1.FormCreate(Sender: TObject);
begin
  Bmp1 := TBitmap.Create;
  Bmp2 := TBitmap.Create;
  Bmp1.LoadFromFile('Bild1.bmp');
  Bmp2.LoadFromFile('Bild1.bmp');
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  Bmp1.Free;
  Bmp2.Free;
end;

procedure TForm1.Button2Click(Sender: TObject);
var x,y,c: single;
begin
  Label1.Caption := '...';
  Label1.Update;
  Autocorrelation(Bmp1,Bmp2,x,y,c);
  Label1.Caption := Format('%6.3f | %6.3f | %6.3f',[x,y,c]);
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  OPDLoad.Title := 'Select first image';
  if not OPDLoad.Execute then exit;
  Bmp1.LoadFromFile(OPDLoad.FileName);
  OPDLoad.Title := 'Select second image';
  if not OPDLoad.Execute then exit;
  Bmp2.LoadFromFile(OPDLoad.FileName);
  ResImage.Picture.Bitmap.LoadFromFile(OPDLoad.FileName);
  ResImage.Canvas.FrameRect(Rect(320-MAXPT2,240-MAXPT2,320+MAXPT2,240+MAXPT2));
end;

end.
