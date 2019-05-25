{
此类是以牺牲部分性能来解决易用性的
如果网页比较大，并且比较复杂，那会有相当多的变量，并且，每个变量的内存空间都会相当可观
所以，如果调用完成，请及时释放内存
}
unit uSimpleHTML;

{$MODE Delphi}

interface

uses Classes  , SysUtils, StrUtils , contnrs,
    dialogs;//, Winapi.Windows,  PerlRegEx;  , Collections


type
  THTMLElement = class;

   //HTML元素集合
  TElementCollections = class(TObjectList<THTMLElement>)
  end;

//获取元素操作的主要类
TSimpleHTML = class
  protected
    allElements : TObjectList; //保存所有创建的标签，在最后destroy的时候释放
    FHTML : string;
  public
    docHTML : string;  //用来查找父标签时候用，如果是通过本类自动产生的HTMLElement，会自动设置这个值，如果是手动建立的，请务必确认先设置好，再调用parent

    constructor Create(html : string );
    Destructor destroy ; override;

    function getElementByid(aId : string) : THTMLElement ;
    //当网页比较大，并且很多标签没有结束的时候，可能会比较慢
    function getElementsByTagName(aTag : string) : TElementCollections;
    //如果加多一个标识符，速度不止快一点
    //aFlag 可以是标签内的任何属性或者属性值，即<div class="abc
    function getElementByTagNameAndFlag(aTag , aFlag : string ) : TElementCollections;
    //只对class进行了左侧匹配，即如果查找class=abc  如果标签为class=abcdef也是会匹配的
    Function getElementsByClassName(aClassName : string) : TElementCollections;
    {根据已经查到的标签首位置，查找结束标识，并返回标签的outerHTML
    }
    Function findTagHtml(aTag : string; posStart: Integer) : string;

end;


//单个元素，继承simpleHtml，是想在单个标签里，可以简单的继续查找下级的元素
THTMLElement = class  (TSimpleHTML)
  private
    FId : String;
    FClassName : string;
    FTag : String;
    //FHTML : String;       //标签的HTML，相当于outerHTML, 每个标签获取后，只存该值，其他值等需要时再取
    FTagHTML : string;   //标签内的HTML，如<div class="className" id="aid">
    //FInnerText : String;
    FInnerHTML : string;
    FOuterHTML : string;
    FText : String;    //没明白innerText和outerText有什么不一样，用同一个吧
    FValue : String;
    FParent : THTMLElement;

    function GetID : string;
    function getClassName : String;
    function getTagHTML : String;
    function getInnerText : String;
    function GetInnerHTML : string;
    function GetOuterHTML : string;
    function getOuterTEXT : String;
    function getValue : string;
    function getTagName : String;
    function getParent : THTMLElement;


  public
    constructor Create(html : string ); overload;
    Destructor destroy ; override;

    function getAttr( AttrName : string ) : String;

    class function clearBlanks( str : string ) : string;  //把连续的非打印字符变成一个空格

    class function removeTags( aHtml:String ) : String;   //去掉所有的标签，得到的相当于 innerTEXT
    class Function UniCodeDecode(s : String) : String;    //{把UNICODE编码的中文，解析成中文字符,诸如：&#26085; 这样的字符}
  published
    //只是分析网页，并不能操作网页，所以write直接将网页分析的结果赋值过来就可以了
    property id : String   read Getid write Fid;
    property tagName : String read getTagName write Ftag;
    property className : String read getClassName write FClassName;
    property tagHTML : string read getTagHTML write FTagHTML;
    property innerText : string   read getInnerText write FText;
    property innerHTML : string  read GetInnerHTML write FInnerHTML;
    property outerText : String read getOuterTEXT write FText;
    property outerHTML : String read GetOuterHTML write FOuterHTML;
    property value : String read getValue write FValue;
    property parent : THTMLElement read getParent;
end;


implementation
uses uStrUtil  ;


constructor TSimpleHTML.Create(html : string);
begin
  //简单粗爆，因为程序在查找标签时，面对js里存在标签的情况相当不好处理，直接加进来就把所有的JS去掉
  with TPerlRegEx.Create do
  begin
    try
      Subject := html;
      Options := [preCaseLess,preSingleLine];
      RegEx := '<script.*?</script>';
      ReplaceAll;
      html := Subject;
    finally
      free;
    end;
  end;
  allElements := TObjectList.Create();
  FHTML := html;
end;

Destructor TSimpleHTML.Destroy;
begin
  allElements.Free;
end;

function TSimpleHTML.getElementByid(aId: string) : THTMLElement;
var
  reg : TPerlRegEx;
  tagHTML : String;
  tick : Cardinal;
begin
  //tick := GetTickCount;
  Result := nil;
  reg := TPerlRegEx.Create;
  try
    reg.Subject := FHTML;
    reg.Options := [preCaseLess,preSingleLine]; //不区分大小写，单行处理
    reg.RegEx := '<([\w]*)[^>]*?\sid[\s]*=[''" ]*'+aid+'[^>]*>';
    if reg.Match then
    begin
      tagHTML := findTagHtml(reg.Groups[1],Pos(reg.MatchedText,FHTML,1) );
      if tagHTML = '' then
        tagHTML := reg.MatchedText;
      Result := THTMLElement.Create(tagHTML);
      Result.tagName := reg.Groups[1];
      Result.tagHTML := reg.MatchedText;
      Result.docHTML := FHTML;
      allElements.Add(Result);
    end;


  finally
    reg.Free;
  end;
   //ShowMessage( ' 用时：'+ IntToStr(GetTickCount-tick));

end;

function TSimpleHTML.getElementsByTagName(aTag: string) : TElementCollections;
var
  elements : TElementCollections;
  element : THTMLElement;
  posStart , posEnd: Integer;
  aHtml : String;
  aChar : string ;
  tick : Cardinal;
begin
  //tick := GetTickCount;
  elements := TElementCollections.Create(true);
  allElements.Add(elements);
  posStart := 1;

  while posStart > 0 do
  begin
    posStart := stripos('<'+aTag, FHTML, posStart +1);
    if posStart = 0 then Break; //没找到，不折腾

    aChar := FHTML[ posStart+ Length(aTag) + 1];
    //如果标签结果的下一个字符不为空格或者>，那说明这个标签找错了
    //比如 <a  那之后必定是连着空格的
    if ( aChar <> ' ' ) and (aChar <> '>') then Continue;

    ahtml := findTagHtml(aTag,posStart);
    if aHtml <> '' then
    begin
      element := THTMLElement.Create(aHtml);
    end else begin
      //处理那些并没有关闭标签的，如<img><input>
      posEnd := strPos('>',FHTML,posStart);
      if posEnd > 0 then
      begin
        aHtml := Copy(FHTML,posStart, posEnd-posStart +1);
        element := THTMLElement.Create(aHtml);
      end;
    end;

    if element <> nil then
    begin
      element.docHTML := FHTML;
      element.tagName := aTag;
      elements.Add(element) ;
      element := nil;
    end;

  end;

  //ShowMessage('找到<'+atag + '>'+ IntToStr(elements.Count) + '个； 用时：'+ IntToStr(GetTickCount-tick));
  Result := elements;
end;


function TSimpleHTML.getElementByTagNameAndFlag(aTag , aFlag : string ) : TElementCollections;
var
  elements : TElementCollections;
  element : THTMLElement;
  posStart : Integer;
  aHtml : String;
  tick : Cardinal;
  reg1 : TPerlRegEx;
begin
  //tick := GetTickCount;
  elements := TElementCollections.Create(true);
  allElements.Add(elements);
  posStart := 1;
  reg1 := TPerlRegEx.Create;
  try
    reg1.Subject := FHTML;
    reg1.Options := [preCaseLess,preSingleLine];
    reg1.RegEx := '<'+aTag+' [^>]*?'+aFlag+'[^>]*?>';
    if reg1.Match then
    begin
      repeat
        posStart := striPos(reg1.Groups[0],FHTML,posStart);
        aHtml := findTagHtml(aTag, posStart) ;
        if aHtml <> '' then element := THTMLElement.Create(aHtml)
        else element := THTMLElement.Create(reg1.Groups[0]) ;
        element.docHTML := FHTML;
        element.tagName := aTag;
        elements.Add(element);
      until (not reg1.MatchAgain);
    end;
  finally
    reg1.Free;
  end;

  //ShowMessage('用时：'+ IntToStr(GetTickCount-tick));
  Result := elements;
end;

function TSimpleHTML.getElementsByClassName(aClassName: string) : TElementCollections;
var
  elements : TElementCollections;
  element : THTMLElement;
  posStart : Integer;
  aHtml : String;
  tick : Cardinal;
  reg1 : TPerlRegEx;
begin
  //tick := GetTickCount;
  elements := TElementCollections.Create(true);
  allElements.Add(elements);
  posStart := 1;
  reg1 := TPerlRegEx.Create;
  try
    reg1.Subject := FHTML;
    reg1.Options := [preCaseLess,preSingleLine];
    reg1.RegEx := '<([\w]*) [^>]*?class=[ ''"]*'+aClassName+'[^>]*?>';
    if reg1.Match then
    begin
      repeat
        posStart := striPos(reg1.Groups[0],FHTML,posStart);
        aHtml := findTagHtml(reg1.Groups[1], posStart) ;
        if aHtml <> '' then element := THTMLElement.Create(aHtml)
        else element := THTMLElement.Create(reg1.Groups[0]) ;
        element.docHTML := FHTML;
        element.tagName := reg1.Groups[1];
        element.tagHTML := reg1.Groups[0];
        elements.Add(element);
      until (not reg1.MatchAgain);
    end;
  finally
    reg1.Free;
  end;

  //ShowMessage('用时：'+ IntToStr(GetTickCount-tick));
  Result := elements;
end;


function TSimpleHTML.findTagHtml(aTag : string; posStart: Integer) : string;
  function countTagBegin(ahtml :string) : Integer; //统计开始标签的个数
  var
    posBegin : Integer;
    NextChar : String;
  begin
    //ShowMessage(ahtml);
    Result := 0;
    posBegin := 0;
    repeat
        posBegin := striPos('<'+aTag,ahtml,posBegin + 1);
        if posBegin > 0 then
        begin
          NextChar := ahtml[posBegin + Length(aTag) + 1];
          //只有当下一个字符为空格或者>才能真的认为是正确的标签
          if ( NextChar = ' ') or (NextChar = '>') then
            inc(Result);
        end;
    until posBegin = 0;
    //ShowMessage(IntToStr(Result));
  end ;
var
  tagEnd : String;
  sHTML ,temHTML: String;
  tagEndCount ,tagBeginCount: Integer;
  endPos , lastCountEndPos: Integer;
  tagEndLen : Integer;
begin
  tagEnd := '</'+aTag + '>';
  tagEndLen := Length(tagEnd);
  tagEndCount := 0;
  tagBeginCount := 0;
  endPos := 0;
  temHTML := '';
  //上次统计过开始标签的结束标签位置，
  //比如 <div1><div2><div3></div3>  这时候统计过出现了三个<div>记录</div3>的位置，
  //下次从这里继续统计增加了多少开始标签；
  lastCountEndPos := 1;

  sHTML := Copy( FHTML, posStart , Length(FHTML));
  while True do
  begin
    endPos := striPos( tagEnd, sHTML , endPos+1  );
    if endPos =0  then
    begin
      //ShowMessage('not match');
      break;  //没找到结束标识，直接退出
    end;

    inc(tagEndCount); //找到了，则增加一次结束标识

    //结束符比开始符少，肯定还没有找到，继续找
    if tagEndCount < tagBeginCount then Continue ;

    //结束符等于开始符时，统计有没有增加开始符
    tagBeginCount := tagBeginCount + countTagBegin( Copy(sHTML,lastCountEndPos , endPos - lastCountEndPos) );
    //ShowMessage('tagBeginCount=' + IntToStr(tagBeginCount) + '; tagEndCount=' + IntToStr(tagEndCount));
    //如果仍然少，则表示有新增了开始标签，继续找结束符
    if tagEndCount < tagBeginCount then
    begin
      lastCountEndPos := endPos;
      Continue;
    end;

    //ShowMessage('tagBeginCount=' + IntToStr(tagBeginCount) + '; tagEndCount=' + IntToStr(tagEndCount));
    //剩下的情况，就只有是开始和结束符相等了，不要再等了
    temHTML := Copy( sHTML,1,endPos + tagEndLen -1);
    //ShowMessage(temHTML);
    break;

  end;
  Result := temHTML;;
end;



{THTMLElement}

constructor THTMLElement.Create(html: string);
begin
  inherited Create(html);
  FHTML := html;
end;

Destructor THTMLElement.Destroy;
begin
  if Fparent <> nil then Fparent.Free;
  inherited;
end;

function THTMLElement.GetID : string;
begin
  if FId = '' then
    FId := getAttr('id');
  Result := FId;
end;

function THTMLElement.getParent : THTMLElement;
var
  findingPos , docLen , offset: Integer;
  reg1 : TPerlRegEx;
  temHTML ,aHtml: string;
begin
  if FParent = nil then
  begin
    docLen := Length(docHTML);
    offset := docLen - strPos(FHTML,docHTML) +2;
    reg1 := TPerlRegEx.Create;
    temHTML := FHTML;
    FHTML := docHTML;  // 将docHTML设置为标签HTML，以便在findTagHtml中使用
    try
      while True do
      begin
        findingPos := strrPos('<',docHTML,offset);  //< 在出现的前一次的位置
        if findingPos = 0 then Break;

        reg1.Subject := Copy(docHTML, findingPos, 20);

        reg1.RegEx := '^<(\w{1,9}?)[ >]';  //标签名有9位够了吧
        if reg1.Match then
        begin
          aHtml := findTagHtml(reg1.Groups[1],findingPos);
          //标签不为空，也不等于自己，并且包含了自己，则认为是父标签
          if (aHtml <> '') and (aHtml <> temHTML)  and  (Pos(temHTML ,aHtml) > 0)  then
          begin
            Fparent := THTMLElement.Create(aHtml);
            FParent.docHTML := FHTML;
            FParent.tagName := reg1.Groups[1];
            Break;
          end;
        end;

        offset := docLen - findingPos +2;
      end;
    finally
      reg1.Free;
      FHTML := temHTML;  //把标签内的HTML设置回原来的
    end;
  end;

  Result := FParent;
end;


function THTMLElement.getTagName : String;
begin
  if FTag = '' then
  begin
    with TPerlRegEx.Create do
    begin
      try
        Subject := FTagHTML;
        Options := [preCaseLess];
        RegEx := '^<(\w*)[^>]*>';
        if Match then begin
          FTag := Groups[1];
          //顺手的事，一起做了
          if FTagHTML = '' then FTagHTML := MatchedText;
        end;

      finally
        free;
      end;
    end;
  end;
  Result := FTag;
end;

function THTMLElement.getClassName : String;
begin
  if FClassName = '' then
    FClassName := getAttr('class');

  Result := FClassName;

end;


function THTMLElement.getValue : string;
begin
  if FValue = '' then
  begin
    FValue := getAttr('value');
  end;

  Result := FValue;
end;

function THTMLElement.getAttr(AttrName: string) : String;
begin
with TPerlRegEx.Create do
  begin
    try
      Subject := tagHTML;
      Options := [preCaseLess];
      RegEx := AttrName+'=[''" ]([ \w\.-]*?)[''"]';   //带引号的情况
      if Match then Result := Groups[1]
      else begin
        RegEx := AttrName + '=\s*([\w\.-]*?)[\s>]';  //分开没有引号处理，是有点担心有引号时，中间出现空格的情况
        if Match then Result := Groups[1];
      end;

    finally
      free;
    end;
  end;

end;

function THTMLElement.getTagHTML : string;
begin
  if FTagHTML = '' then
  begin
    FTagHTML := Copy(FHTML,1,Pos('>' , FHTML)  );
  end;

  Result := FTagHTML;
end;

function THTMLElement.getInnerText : String;
begin
  Result := getOuterTEXT;
end;

function THTMLElement.GetInnerHTML : String;
var
  startPos,endPos : Integer;
begin
  if FInnerHTML = '' then
  begin
    endPos := strriPos('</'+tagName,FHTML);
    if endPos > 0 then
    begin
      FInnerHTML := Copy(FHTML,Length(tagHTML)+1,endPos - Length(tagHTML) -1);
    end;
  end;
  Result := FInnerHTML;
end;

function THTMLElement.GetOuterHTML : string;
begin
  Result := FHTML;
end;

function THTMLElement.getOuterTEXT : String;
begin
  if FText = '' then
  begin
    FText := removeTags(FHTML);
    FText := UniCodeDecode(FText);
    FText := clearBlanks(FText);
  end;
  Result := FText;
end;


class function THTMLElement.removeTags(aHtml: string) : String;
begin
  Result := aHtml;
  with TPerlRegEx.Create do
  begin
    try
      Subject := aHtml;
      Options := [preCaseLess,preSingleLine];

      //转换特殊标识
      regEx := '&nbsp;';
      Replacement := ' ';
      ReplaceAll;
      regEx := '&amp;';
      Replacement := '&';
      ReplaceAll;
      RegEx := '&lt;';
      Replacement := '<';
      ReplaceAll;
      regEx := '&gt;';
      Replacement := '>';
      ReplaceAll;
      RegEx := '&quot;';
      Replacement := '"';
      ReplaceAll;
      RegEx := '&middot;';
      Replacement := '·';
      ReplaceAll;

      Replacement := '';
      //去掉script
      RegEx := '<script.*?</script>';
      ReplaceAll;

      //去掉style
      RegEx := '<style.*?</style>';
      ReplaceAll;

      //去掉注释
      RegEx := '<!--.*?-->';
      ReplaceAll;

      //去掉所有的标签
      Replacement := '';
      RegEx := '<[^<>]+?>';
      ReplaceAll;
      ReplaceAll;   //没有写重复，执行两次是因为，有的标签里面包括js，如<input onclick="javascript:document.write('<div>hellow word</div>);";

      Result := trim( subject );
    finally
      free;
    end;
  end;

end;


{把UNICODE编码的中文，解析成中文字符,诸如：&#26085; 这样的字符}
class Function THTMLElement.UniCodeDecode (s : String) : String;
var
  reg1 : TPerlRegEx;
begin
  reg1 := TPerlRegEx.Create;

  Result := s;
  try
    try
      reg1.Subject := s;
      reg1.RegEx := '&#([0-9]{5});';
      while reg1.MatchAgain do
      begin
        Result := stringReplace( result , reg1.MatchedText, Char(StrToInt(reg1.Groups[1])) , [rfReplaceAll]);
      end;

      //16进制保存的情况
      reg1.RegEx := '&#[xX]([0-9a-fA-F]{4});';
      if reg1.Match then
      begin
        repeat
          Result := StringReplace(Result , reg1.MatchedText,Char(StrToInt('$'+reg1.Groups[1])) , [rfReplaceAll] );
        until (not reg1.MatchAgain);
      end;

    except
      Result := s;
    end;
  finally
    reg1.Free;
  end;

end;



class function THTMLElement.clearBlanks(str: string) : string;
begin
  Result := str;
  with TPerlRegEx.Create do
  begin
    try
      Subject := str;
      RegEx := '\s+';
      Replacement := ' ';
      ReplaceAll;
      Result := Subject;
    finally
      free;
    end;
  end;
end;


end.


{
晓不得  写的字符串转换函数原型，备查
procedure TForm1.Button1Click(Sender: TObject);
var
  s : string;
  i,n : Integer;
  c,e : string;
  p : PChar ;
  x : Integer;
begin
  s := '&#35797;&#25351;&#23450;&#25945;&#26448;&#31995;';
  n :=Length(s) div 8;
  SetLength( e, n);
  p := PChar( @e[1] );
  for i := 0 to n-1 do
    begin
      c := Copy(s, i * 8 + 3, 5);
      Memo2.Lines.Add(c);
      x := StrToInt( c );
      p^ := Char(x);
      inc(p);
    end;
  Memo2.Lines.Add(e);
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  i , n : Integer;
  s, c, e : string;
  b,d : PChar;
  p : PChar; //e的指针
begin
  s := '&#x534E;&#x6CFD;&#x4F1A;&#x8BA1;&#x8003;&#x8BD5;&#x6307;&#x5B9A;&#x6559;&#x6750;';
  n := Length(s) div 8; //共有多少字符
  SetLength(e,n);
  SetLength(c,5);
  c[1] := '$';
  p := pchar( @e[1] );  //把e的首地址给p
  b := @s[4]; //e的第四位，即数据开始部分传给b
  d := @c[2];
  for i := 0 to n -1  do
    begin
      CopyMemory(d , b , 8); //从b复制到d   为什么是8位？
      Memo2.Lines.Add(c);   // d是从c的第二位开始，所以，这里的c结果就是 $d
      p^ := Char(StrToInt(c)); //把当前的字符替换成$d, 对第一个字符来讲就是：$534E
      inc(p); //准备操作下个字符
      inc(b,8);
    end;
  Memo2.Lines.Add(e);
end;
}
