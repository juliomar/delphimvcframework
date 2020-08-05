unit TestServerControllerJSONRPCU;

interface

uses
  MVCFramework, MVCFramework.Commons, MVCFramework.JSONRPC, JsonDataObjects;

type
  TTestJSONRPCController = class(TMVCJSONRPCController)
  public
    function Subtract(Value1, Value2: Int64): Integer;
    procedure MyNotify;
    function Add(Value1, Value2, Value3: Int64): TJsonObject;
    function GetListFromTo(aFrom, aTo: Int64): TJsonArray;
    function MultiplyString(aString: string; Multiplier: Int64): string;
  end;

  TTestJSONRPCClass = class(TObject)
  public
    function Subtract(Value1, Value2: Int64): Integer;
    procedure MyNotify;
    function Add(Value1, Value2, Value3: Int64): TJsonObject;
    function GetListFromTo(aFrom, aTo: Int64): TJsonArray;
    function MultiplyString(aString: string; Multiplier: Int64): string;
    function AddTimeToDateTime(aDateTime: TDateTime; aTime: TTime): TDateTime;
  end;

  TTestJSONRPCHookClass = class(TObject)
  private
    fJSONReq: TJsonObject;
    fHistory: string;
    fJSONRPCKind: TJSONRPCRequestType;
  public
    procedure OnBeforeRoutingHook(const Context: TWebContext; const JSON: TJsonObject);
    procedure OnBeforeCallHook(const Context: TWebContext; const JSON: TJsonObject);
    procedure OnAfterCallHook(const Context: TWebContext; const JSON: TJsonObject);
    function error_OnBeforeRoutingHook: Boolean;
    function error_OnBeforeCallHook: Boolean;
    function error_OnAfterCallHook: Boolean;

    procedure Notif1;
    function Request1: string;
    function RequestWithError: string;
  end;

implementation

uses
  System.SysUtils, MVCFramework.Logger, System.StrUtils;

{ TTestJSONRPCController }

function TTestJSONRPCController.Add(Value1, Value2, Value3: Int64): TJsonObject;
begin
  Result := TJsonObject.Create;
  Result.I['res'] := Value1 + Value2 + Value3;
end;

function TTestJSONRPCController.GetListFromTo(aFrom, aTo: Int64): TJsonArray;
var
  I: Cardinal;
begin
  Result := TJsonArray.Create;
  for I := aFrom to aTo do
    Result.Add(I);
end;

function TTestJSONRPCController.MultiplyString(aString: string;
  Multiplier: Int64): string;
var
  I: Integer;
begin
  Result := aString;
  for I := 2 to Multiplier do
  begin
    Result := Result + aString;
  end;
end;

procedure TTestJSONRPCController.MyNotify;
begin
  // this is a notify with no parameters and no result code
  Self.ClassName;
end;

function TTestJSONRPCController.Subtract(Value1, Value2: Int64): Integer;
begin
  Result := Value1 - Value2;
end;

{ TTestJSONRPCClass }

function TTestJSONRPCClass.Add(Value1, Value2, Value3: Int64): TJsonObject;
begin
  Result := TJsonObject.Create;
  Result.I['res'] := Value1 + Value2 + Value3;
end;

function TTestJSONRPCClass.AddTimeToDateTime(aDateTime: TDateTime;
  aTime: TTime): TDateTime;
begin
  Result := aDateTime + aTime;
end;

function TTestJSONRPCClass.GetListFromTo(aFrom, aTo: Int64): TJsonArray;
var
  I: Cardinal;
begin
  Result := TJsonArray.Create;
  for I := aFrom to aTo do
    Result.Add(I);
end;

function TTestJSONRPCClass.MultiplyString(aString: string;
  Multiplier: Int64): string;
var
  I: Integer;
begin
  Result := aString;
  for I := 2 to Multiplier do
  begin
    Result := Result + aString;
  end;
end;

procedure TTestJSONRPCClass.MyNotify;
begin
  // this is a notify with no parameters and no result code
  Self.ClassName;
end;

function TTestJSONRPCClass.Subtract(Value1, Value2: Int64): Integer;
begin
  Result := Value1 - Value2;
end;

{ TTestJSONRPCHookClass }

function TTestJSONRPCHookClass.error_OnAfterCallHook: Boolean;
begin
  // do nothing
end;

function TTestJSONRPCHookClass.error_OnBeforeCallHook: Boolean;
begin
  // do nothing
end;

function TTestJSONRPCHookClass.error_OnBeforeRoutingHook: Boolean;
begin
  // do nothing
end;

procedure TTestJSONRPCHookClass.Notif1;
begin
  // do nothing
end;

procedure TTestJSONRPCHookClass.OnAfterCallHook(const Context: TWebContext; const JSON: TJsonObject);
begin
  if SameText(fJSONReq.S['method'], 'error_OnAfterCallHook') then
    raise Exception.Create('error_OnAfterCallHook');

  fHistory := fHistory + '|OnAfterCallHook';

  if JSON.Contains('error') then
    fHistory := fHistory + '|error';

  // do nothing
  if fJSONRPCKind = TJSONRPCRequestType.Request then
  begin
    Assert(Assigned(JSON));
    LogD('TTestJSONRPCHookClass.OnAfterCallHook: ' + JSON.ToJSON());
  end
  else
  begin
    Assert(not Assigned(JSON));
    LogD('TTestJSONRPCHookClass.OnAfterCallHook: Param is nil');
  end;
  Context.Response.CustomHeaders.Values['x-history'] := fHistory;
  FreeAndNil(fJSONReq);
end;

procedure TTestJSONRPCHookClass.OnBeforeCallHook(const Context: TWebContext; const JSON: TJsonObject);
begin
  if SameText(JSON.S['method'], 'error_OnBeforeCallHook') then
    raise Exception.Create('error_OnBeforeCallHook');

  fHistory := fHistory + '|OnBeforeCallHook';
  Assert(Assigned(JSON), 'JSON not assigned in OnBeforeCallHook');
  LogD('TTestJSONRPCHookClass.OnBeforeCallHook: ' + JSON.ToJSON());
end;

procedure TTestJSONRPCHookClass.OnBeforeRoutingHook(const Context: TWebContext; const JSON: TJsonObject);
begin
  fJSONReq := JSON.Clone;

  if SameText(JSON.S['method'], 'error_OnBeforeRoutingHook') then
    raise Exception.Create('error_OnBeforeRoutingHook');

  fHistory := 'OnBeforeRoutingHook';
  // do nothing
  Assert(Assigned(JSON), 'JSON not assigned in OnBeforeRoutingHook');
  LogD('TTestJSONRPCHookClass.OnBeforeRoutingHook: ' + JSON.ToJSON());
  if JSON.Contains('id') then
    fJSONRPCKind := TJSONRPCRequestType.Request
  else
    fJSONRPCKind := TJSONRPCRequestType.Notification;
end;

function TTestJSONRPCHookClass.Request1: string;
begin
  Result := 'empty';
end;

function TTestJSONRPCHookClass.RequestWithError: string;
begin
  raise Exception.Create('BOOM');
end;

end.
