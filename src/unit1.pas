unit unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Buttons, IdHTTP, IdSSLOpenSSL, BCButton, BCMaterialDesignButton, BCListBox,
  BCPanel, htmlparser,windows;

type

  { TForm1 }

  TForm1 = class(TForm)
    BCPanel1: TBCPanel;
    Memo1: TMemo;
    topPanel: TBCPaperPanel;
    rightPanel: TBCPaperPanel;
    leftPanel: TBCPaperPanel;
    btnDownload: TBCMaterialDesignButton;
    Edit1: TEdit;
    IdHTTP1: TIdHTTP;
    IdSSLIOHandlerSocketOpenSSL1: TIdSSLIOHandlerSocketOpenSSL;
    Image1: TImage;
    procedure btnDownloadClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure HtmlParser;
    //function DecodeUtf8Str(const S: UTF8String): WideString;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.btnDownloadClick(Sender: TObject);
var
  imagestream:TMemoryStream;
  Buffer:Word;
  jpg:TJpegImage;
begin
   HtmlParser;
  //if Edit1.Text <> '' then
  //begin
  //  Image1.Picture.Graphic := nil;
  //  imagestream := TMemoryStream.Create;
  //  try
  //    IdHTTP1.Request.Accept := '*/*';
  //    IdHTTP1.Request.AcceptLanguage := 'zh-cn';
  //    IdHTTP1.Request.UserAgent:='Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1)';
  //    IdHTTP1.Request.Connection := 'Keep-Alive';
  //    IdHTTP1.HTTPOptions:=IdHTTP1.HTTPOptions+[hoKeepOrigProtocol];
  //    IdHTTP1.ProtocolVersion:=pv1_1;
  //     try
  //       IdHTTP1.IOHandler := IdSSLIOHandlerSocketOpenSSL1;
  //       IdHTTP1.Get(Edit1.Text,imagestream);
  //     except
  //       showmessage('连接失败！');
  //       exit;
  //     end;
  //
  //     imagestream.Position:= 0;
  //     if imagestream.Size = 0 then
  //     begin
  //       imagestream.Free;
  //       ShowMessage('错误');
  //       Exit;
  //     end;
  //
  //     imagestream.ReadBuffer(Buffer,2);
  //     imagestream.Position := 0;
  //
  //     if Buffer = $4D42 then //BMP
  //     begin
  //       image1.Picture.bitmap.LoadFromStream(imagestream);
  //     end
  //     else if Buffer = $D8FF then //JPG
  //     begin
  //       jpg:=TJpegImage.Create;
  //       jpg.LoadFromStream(imagestream);
  //       image1.Picture.Assign(jpg);
  //       jpg.free;
  //     end
  //     else if Buffer=$050A then
  //     begin
  //         ShowMessage('PCX');
  //     end
  //       else if Buffer=$5089 then
  //     begin
  //         ShowMessage('PNG');
  //     end
  //     else if Buffer=$4238 then
  //     begin
  //          ShowMessage('PSD');
  //     end
  //     else if Buffer=$A659 then
  //     begin
  //       ShowMessage('RAS');
  //     end
  //     else if Buffer=$DA01 then
  //     begin
  //       ShowMessage('SGI');
  //     end
  //     else if Buffer=$4949 then
  //     begin
  //       ShowMessage('TIFF');
  //     end
  //     else
  //     begin
  //       ShowMessage('ERROR');
  //     end;
  //
  //  finally
  //    imagestream.Free;
  //  end;
  //end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
   Edit1.Text := 'http://www.raysoftware.cn/?p=370';//'https://img.ivsky.com/img/tupian/pre/201811/01/miaoxingren.jpg';
end;

procedure TForm1.HtmlParser;
var
  url:string;
  s:string;
  ss:TStringStream;
begin
  url:=Edit1.Text;
  if(lowercase(copy(url,1,length('http://')))<> 'http://')then
  begin
    url:='http://'+url;
  end;
  IdHTTP1.Request.Accept := '*/*';
  IdHTTP1.Request.AcceptLanguage := 'zh-cn';
  IdHTTP1.Request.UserAgent:='Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1)';
  IdHTTP1.Request.Connection := 'Keep-Alive';
  IdHTTP1.HTTPOptions:=IdHTTP1.HTTPOptions+[hoKeepOrigProtocol];
  IdHTTP1.ProtocolVersion:=pv1_1;
  IdHTTP1.Response.CharSet := 'UTF-8';
   try
     { 指定gb2312的中文代码页，或者54936（gb18030）更好些 utf8 对应 65001}
     ss := TStringStream.Create('');
     IdHTTP1.IOHandler := IdSSLIOHandlerSocketOpenSSL1;
     IdHTTP1.Get(url,ss);
     s:=ss.DataString;
     {$IFDEF UNICODE}
       Memo1.Lines.Text := s;
     {$ELSE}
       Memo1.Lines.Text := s;
     {$ENDIF}
   except
     showmessage('连接失败！');
     exit;
   end;
end;

//function TForm1.DecodeUtf8Str(const S: UTF8String): WideString;
//var lenSrc, lenDst  : Integer;
//begin
//  lenSrc  := Length(S);
//  if(lenSrc=0)then Exit;
//  lenDst  := MultiByteToWideChar(CP_UTF8, 0, Pointer(S), lenSrc, nil, 0);
//  SetLength(Result, lenDst);
//  MultiByteToWideChar(CP_UTF8, 0, Pointer(S), lenSrc, Pointer(Result), lenDst);
//end;
























end.

