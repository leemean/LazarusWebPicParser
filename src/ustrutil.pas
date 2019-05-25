unit uStrUtil;

{$MODE Delphi}

interface
uses System.SysUtils , dialogs , System.Classes;


//以下几个字符串参照PHP的同名函数命名
function strPos(const SubStr, Str: string; Offset: Integer = 1 ): Integer;  //查找字串位置，区分大小写， 系统自带的为shotStr,只能处理254字符数
function striPos(const SubStr, Str: string; Offset: Integer = 1 ): Integer;  //查找字串位置，不区分大小写
function strrPos(const ASubStr, s: string; ARightOffset: integer = 1): integer; //从后往前查找字符串，区分大小写
function strriPos(const ASubStr, s: string; ARightOffset: integer = 1): integer; //从后往前查找字符串，不区分大小写

//从前往后查找字符串位置，一般是用上面的四个函数
function leftPos(const SubStr, Str: string; Offset: Integer ; caseLess : Boolean): Integer;
function rightPos(const ASubStr, s: string; ARightOffset: integer ; caseLess : Boolean): integer;

function LoadTextFromFile(AFileName: string): string;

implementation


function strPos(const SubStr, Str: string; Offset: Integer = 1 ): Integer;
begin
  Result := leftpos(SubStr,str,Offset,False);
end;

function striPos(const SubStr, Str: string; Offset: Integer = 1 ): Integer;
begin
  Result := leftpos(SubStr,str,Offset,true);
end;



function strrPos(const ASubStr, s: string; ARightOffset: integer = 1): integer;
begin
  Result := rightPos(ASubStr,s,ARightOffset,False);
end;

function strriPos(const ASubStr, s: string; ARightOffset: integer = 1): integer;
begin
  Result := rightPos(ASubStr,s,ARightOffset,True);
end;


function leftPos(const SubStr, Str: string; Offset: Integer ; caseLess : Boolean): Integer;
var
  I, LIterCnt, L, J : Integer;
  PSubStr, PS: PChar;
  aBool : Boolean;
begin
  L := Length(SubStr);
  { Calculate the number of possible iterations. Not valid if Offset < 1. }
  LIterCnt := Length(Str) - Offset  - L + 1;

  { Only continue if the number of iterations is positive or zero (there is space to check) }
  if (Offset > 0) and (LIterCnt >= 0) and (L > 0) then
  begin
    PSubStr := PChar(SubStr);
    PS := PChar(Str);
    Inc(PS, Offset - 1);

    for I := 0 to LIterCnt  do
    begin
      J := 0;
      while (J >= 0) and (J < L ) do
      begin
        if caseLess then aBool := UpCase( (PS + i + J)^ )  =  UpCase ( (PSubStr + J)^ )
        else aBool :=  (PS + i + J)^   =  (PSubStr + J)^ ;

        if  abool then begin
          J := j+1;
        end
        else
          J := -1;
      end;
      if J >= L then
        Exit(I + Offset);
    end;
  end;

  Result := 0;
end;

function rightPos(const ASubStr, s: string; ARightOffset: integer ; caseLess : Boolean): integer;
var
  i, LIterCnt, L, LS, J: integer;
  PSubStr, PS: PChar;
  aBool : Boolean;
begin

  if ASubStr = '' then
    exit(0);

  LIterCnt := Length(s) - ARightOffset - Length(ASubStr) + 1;

  if (ARightOffset > 0) and (LIterCnt >= 0) then
  begin
    L := Length(ASubStr);
    LS := Length(s);

    PSubStr := PChar(ASubStr);
    Inc(PSubStr, L - 1);

    PS := PChar(s);
    Inc(PS, LS - ARightOffset);

    for i := 0 to LIterCnt do
    begin
      J := 0;
      while (J >= 0) and (J < L) do
      begin
        if caseLess then
          aBool := UpCase( (PS - i - J)^ ) = UpCase( (PSubStr - J)^ )
        else
          aBool := (PS - i - J)^ = (PSubStr - J)^;
        if aBool then
          Inc(J)
        else
          J := -1;
      end;
      if J >= L then
        exit(LS - i - (L - 1) - (ARightOffset - 1));
    end;
  end;

  Result := 0;
end;

function LoadTextFromFile(AFileName: string): string;
var
  M: TFileStream;
  B: TStringStream;
begin
  Result := '';
  if FileExists(AFileName) then
  begin
    M := TFileStream.Create(AFileName, fmOpenRead);
    B := TStringStream.Create;
    try
      B.LoadFromStream(M);
      Result := B.DataString;
    finally
      M.Free;
      B.Free;
    end;
  end;
end;

end.
