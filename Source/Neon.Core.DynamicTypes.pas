{******************************************************************************}
{                                                                              }
{  Neon: JSON Serialization library for Delphi                                 }
{  Copyright (c) 2018  Paolo Rossi                                             }
{  https://github.com/paolo-rossi/delphi-neon                                  }
{                                                                              }
{******************************************************************************}
{                                                                              }
{  Licensed under the Apache License, Version 2.0 (the "License");             }
{  you may not use this file except in compliance with the License.            }
{  You may obtain a copy of the License at                                     }
{                                                                              }
{      http://www.apache.org/licenses/LICENSE-2.0                              }
{                                                                              }
{  Unless required by applicable law or agreed to in writing, software         }
{  distributed under the License is distributed on an "AS IS" BASIS,           }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    }
{  See the License for the specific language governing permissions and         }
{  limitations under the License.                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Core.DynamicTypes;

{$I Neon.inc}

interface

uses
  System.Classes,
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
  System.Generics.Collections;

type
  IDynamicType = interface(IInterface)
    ['{DD163E75-134C-4035-809C-D9E1EEEC4225}']
  end;

  IDynamicStream = interface(IDynamicType)
    ['{968D03E7-273F-4E94-A3EA-ECB7A73F0715}']
    procedure LoadFromStream(AStream: TStream);
    procedure SaveToStream(AStream: TStream);
  end;

  IDynamicList = interface(IDynamicType)
    ['{9F4A2D72-078B-4EA2-B86E-068206AD0F16}']
    function NewItem: TValue;
    function GetItemType: TRttiType;
    procedure Add(AItem: TValue);
    procedure Clear;
    function Count: Integer;
    // Enumerator functions
    function Current: TValue;
    function MoveNext: Boolean;
  end;

  IDynamicMap = interface(IDynamicType)
    ['{89E60A06-C1A9-4D70-83B8-85D9B29510DB}']
    function NewKey: TValue;
    function NewValue: TValue;
    function GetKeyType: TRttiType;
    function GetValueType: TRttiType;
    procedure Add(const AKey, AValue: TValue);
    procedure Clear;
    function Count: Integer;
    // Enumerator functions
    function CurrentKey: TValue;
    function CurrentValue: TValue;
    function MoveNext: Boolean;
    // Key-related functions
    function KeyIsString: Boolean;
    function KeyToString(const AKey: TValue): string;
    procedure KeyFromString(const AKey: TValue; const AStringVal: string);
  end;

  IDynamicNullable = interface(IDynamicType)
    ['{B1F7F5F0-223B-4ADF-9845-40278D57F62C}']
    function HasValue: Boolean;
    function GetValue: TValue;
    function GetValueType: PTypeInfo;
    procedure SetValue(const AValue: TValue);
  end;

  TDynamicStream = class sealed(TInterfacedObject, IDynamicStream)
  strict private
    FInstance: TObject;
    FLoadMethod: TRttiMethod;
    FSaveMethod: TRttiMethod;
    constructor Create(AInstance: TObject; ALoadMethod, ASaveMethod: TRttiMethod);
    procedure LoadFromStream(AStream: TStream);
    procedure SaveToStream(AStream: TStream);
  public
    class function GuessType(AInstance: TObject): IDynamicStream;
  end;

  TDynamicList = class sealed(TInterfacedObject, IDynamicList)
  strict private
    FInstance: TObject;
    FEnumInstance: TObject;
    FItemType: TRttiType;
    FAddMethod: TRttiMethod;
    FClearMethod: TRttiMethod;
    FMoveNextMethod: TRttiMethod;
    FCurrentProperty: TRttiProperty;
    FCountProperty: TRttiProperty;
    constructor Create(AInstance, AEnumInstance: TObject; AItemType: TRttiType; AAddMethod, AClearMethod, AMoveNextMethod: TRttiMethod; ACurrentProperty,
        ACountProperty: TRttiProperty);
    destructor Destroy; override;
    function NewItem: TValue;
    function GetItemType: TRttiType;
    procedure Add(AItem: TValue);
    procedure Clear;
    function Count: Integer;
    function Current: TValue;
    function MoveNext: Boolean;
  public
    class function GuessType(AInstance: TObject): IDynamicList;
  end;

  TDynamicMap = class sealed(TInterfacedObject, IDynamicMap)
  public
  type
    TEnumerator = class sealed(TObject)
    strict private
    const
      CURRENT_PROP = 'Current';
      MOVENEXT_METH = 'MoveNext';
    var
      FInstance: TObject;
      FMoveNextMethod: TRttiMethod;
      FCurrentProperty: TRttiProperty;
    public
      constructor Create(AMethod: TRttiMethod; AInstance: TObject);
      destructor Destroy; override;
      function Current: TValue;
      function MoveNext: Boolean;
    end;
  strict private
    FInstance: TObject;
    FKeyType: TRttiType;
    FValueType: TRttiType;
    FAddMethod: TRttiMethod;
    FClearMethod: TRttiMethod;
    FKeyEnum: TDynamicMap.TEnumerator;
    FValueEnum: TDynamicMap.TEnumerator;
    FCountProp: TRttiProperty;
    FToStringMethod: TRttiMethod;
    FFromStringMethod: TRttiMethod;
    constructor Create(AInstance: TObject; AKeyType, AValueType: TRttiType; AAddMethod, AClearMethod: TRttiMethod; ACountProp: TRttiProperty; AKeyEnum, AValueEnum:
        TDynamicMap.TEnumerator; AToStringMethod, AFromStringMethod: TRttiMethod);
  public
    class function GuessType(AInstance: TObject): IDynamicMap;
    destructor Destroy; override;
    function NewKey: TValue;
    function NewValue: TValue;
    function GetKeyType: TRttiType;
    function GetValueType: TRttiType;
    procedure Add(const AKey, AValue: TValue);
    procedure Clear;
    function Count: Integer;
    // Enumerator functions
    function CurrentKey: TValue;
    function CurrentValue: TValue;
    function MoveNext: Boolean;
    // Key-related functions
    function KeyIsString: Boolean;
    function KeyToString(const AKey: TValue): string;
    procedure KeyFromString(const AKey: TValue; const AStringVal: string);
  end;

  TDynamicNullable = class sealed(TInterfacedObject, IDynamicNullable)
  strict private
    FInstance: TValue;
    FTypeInfoMethod: TRttiMethod;
    FHasValueMethod: TRttiMethod;
    FGetValueMethod: TRttiMethod;
    FSetValueMethod: TRttiMethod;
    constructor Create(AInstance: TValue; ATypeInfoMethod, AHasValueMethod, AGetValueMethod, ASetValueMethod: TRttiMethod);
  public
    class function GuessType(AInstance: TValue): IDynamicNullable;
    // Interface IDynamicNullable
    function HasValue: Boolean;
    function GetValue: TValue;
    function GetValueType: PTypeInfo;
    procedure SetValue(const AValue: TValue);
  end;

implementation

uses
  Neon.Core.Types,
  Neon.Core.Utils;

constructor TDynamicStream.Create(AInstance: TObject; ALoadMethod, ASaveMethod: TRttiMethod);
begin
  FInstance := AInstance;
  FLoadMethod := ALoadMethod;
  FSaveMethod := ASaveMethod;
end;

class function TDynamicStream.GuessType(AInstance: TObject): IDynamicStream;
begin
  if not Assigned(AInstance) then
    Exit(nil);

  var LType := TRttiUtils.Context.GetType(AInstance.ClassType);

  if not Assigned(LType) then
    Exit(nil);

  var LLoadMethod := LType.GetMethod('LoadFromStream');

  if Assigned(LLoadMethod) then
  begin
    if Length(LLoadMethod.GetParameters) <> 1 then

      Exit(nil);
  end
  else
    Exit(nil);

  var LSaveMethod := LType.GetMethod('SaveToStream');

  if Assigned(LSaveMethod) then
  begin
   if Length(LSaveMethod.GetParameters) <> 1 then
      Exit(nil);
  end
  else
    Exit(nil);

  Result := Self.Create(AInstance, LLoadMethod, LSaveMethod);
end;

procedure TDynamicStream.LoadFromStream(AStream: TStream);
begin
  FLoadMethod.Invoke(FInstance, [AStream]);
end;

procedure TDynamicStream.SaveToStream(AStream: TStream);
begin
  FSaveMethod.Invoke(FInstance, [AStream]);
end;

procedure TDynamicList.Add(AItem: TValue);
begin
  FAddMethod.Invoke(FInstance, [AItem]);
end;

procedure TDynamicList.Clear;
begin
  FClearMethod.Invoke(FInstance, []);
end;

function TDynamicList.Count: Integer;
begin
  Result := FCountProperty.GetValue(FInstance).AsInteger;
end;

constructor TDynamicList.Create(AInstance, AEnumInstance: TObject; AItemType: TRttiType; AAddMethod, AClearMethod, AMoveNextMethod: TRttiMethod;
    ACurrentProperty, ACountProperty: TRttiProperty);
begin
  FInstance := AInstance;
  FEnumInstance := AEnumInstance;
  FItemType := AItemType;
  FAddMethod := AAddMethod;
  FClearMethod := AClearMethod;
  FMoveNextMethod := AMoveNextMethod;
  FCurrentProperty := ACurrentProperty;
  FCountProperty := ACountProperty;
end;

function TDynamicList.Current: TValue;
begin
  Result := FCurrentProperty.GetValue(FEnumInstance);
end;

destructor TDynamicList.Destroy;
begin
  FEnumInstance.Free;
  inherited;
end;

function TDynamicList.GetItemType: TRttiType;
begin
  Result := FItemType;
end;

class function TDynamicList.GuessType(AInstance: TObject): IDynamicList;
begin
  Result := nil;

  if not Assigned(AInstance) then
    Exit;

  var LListType := TRttiUtils.Context.GetType(AInstance.ClassType);
  var LMethodGetEnumerator := LListType.GetMethod('GetEnumerator');

  if not Assigned(LMethodGetEnumerator) or
    (LMethodGetEnumerator.MethodKind <> mkFunction) or
    (LMethodGetEnumerator.ReturnType.Handle.Kind <> tkClass)
  then
    Exit;

  var LMethodClear := LListType.GetMethod('Clear');

  if not Assigned(LMethodClear) then
    Exit;

  var LMethodAdd := LListType.GetMethod('Add');

  if not Assigned(LMethodAdd) or
     (Length(LMethodAdd.GetParameters) <> 1) then
    Exit;

  var LItemType := LMethodAdd.GetParameters[0].ParamType;
  var LCountProp := LListType.GetProperty('Count');

  if not Assigned(LCountProp) then
    Exit;

  var LEnumInstance := LMethodGetEnumerator.Invoke(AInstance, []).AsObject;

  if not Assigned(LEnumInstance) then
    Exit;

  var LEnumType := TRttiUtils.Context.GetType(LEnumInstance.ClassType);
  var LCurrentProp := LEnumType.GetProperty('Current');

  if not Assigned(LCurrentProp) then
    Exit;

  var LMethodMoveNext := LEnumType.GetMethod('MoveNext');

  if not Assigned(LMethodMoveNext) or
    (Length(LMethodMoveNext.GetParameters) <> 0) or
    (LMethodMoveNext.MethodKind <> mkFunction) or
    (LMethodMoveNext.ReturnType.Handle <> TypeInfo(Boolean))
  then
    Exit;

  Result := TDynamicList.Create(AInstance, LEnumInstance, LItemType, LMethodAdd, LMethodClear, LMethodMoveNext, LCurrentProp, LCountProp);
end;

function TDynamicList.MoveNext: Boolean;
begin
  Result := FMoveNextMethod.Invoke(FEnumInstance, []).AsBoolean;
end;

function TDynamicList.NewItem: TValue;
begin
  Result := TRttiUtils.CreateNewValue(FItemType);
end;

procedure TDynamicMap.Add(const AKey, AValue: TValue);
begin
  FAddMethod.Invoke(FInstance, [AKey, AValue]);
end;

procedure TDynamicMap.Clear;
begin
  FClearMethod.Invoke(FInstance, []);
end;

function TDynamicMap.Count: Integer;
begin
  Result := FCountProp.GetValue(FInstance).AsInteger;
end;

constructor TDynamicMap.Create(AInstance: TObject; AKeyType, AValueType: TRttiType; AAddMethod, AClearMethod: TRttiMethod; ACountProp: TRttiProperty; AKeyEnum,
    AValueEnum: TDynamicMap.TEnumerator; AToStringMethod, AFromStringMethod: TRttiMethod);
begin
  FInstance := AInstance;
  FKeyType := AKeyType;
  FValueType := AValueType;
  FAddMethod := AAddMethod;
  FClearMethod := AClearMethod;
  FKeyEnum := AKeyEnum;
  FValueEnum := AValueEnum;
  FCountProp := ACountProp;
  FToStringMethod := AToStringMethod;
  FFromStringMethod := AFromStringMethod;
end;

function TDynamicMap.CurrentKey: TValue;
begin
  Result := FKeyEnum.Current;
end;

function TDynamicMap.CurrentValue: TValue;
begin
  Result := FValueEnum.Current;
end;

destructor TDynamicMap.Destroy;
begin
  FKeyEnum.Free;
  FValueEnum.Free;
  inherited;
end;

procedure TDynamicMap.KeyFromString(const AKey: TValue; const AStringVal: string);
begin
  if Assigned(FFromStringMethod) then
    FFromStringMethod.Invoke(AKey.AsObject, [AStringVal]);
end;

function TDynamicMap.GetKeyType: TRttiType;
begin
  Result := FKeyType;
end;

function TDynamicMap.GetValueType: TRttiType;
begin
  Result := FValueType;
end;

class function TDynamicMap.GuessType(AInstance: TObject): IDynamicMap;
begin
  Result := nil;

  if not Assigned(AInstance) then
    Exit;

  var LMapType := TRttiUtils.Context.GetType(AInstance.ClassType);
  // Keys & Values Enumerator
  var LKeyProp := LMapType.GetProperty('Keys');

  if not Assigned(LKeyProp) then
    Exit;

  var LValProp := LMapType.GetProperty('Values');

  if not Assigned(LValProp) then
    Exit;

  var LKeyEnumObject := LKeyProp.GetValue(AInstance).AsObject;
  var LValEnumObject := LValProp.GetValue(AInstance).AsObject;
  var LKeyEnumMethod := TRttiUtils.Context.GetType(LKeyEnumObject.ClassInfo).GetMethod('GetEnumerator');
  var LValEnumMethod := TRttiUtils.Context.GetType(LValEnumObject.ClassInfo).GetMethod('GetEnumerator');
  var LKeyEnum := TDynamicMap.TEnumerator.Create(LKeyEnumMethod, LKeyEnumObject);
  var LValEnum := TDynamicMap.TEnumerator.Create(LValEnumMethod, LValEnumObject);
  // End Keys & Values Enumerator

  var LClearMethod := LMapType.GetMethod('Clear');

  if not Assigned(LClearMethod) then
    Exit;

  var LAddMethod := LMapType.GetMethod('Add');

  if not Assigned(LAddMethod) or
     (Length(LAddMethod.GetParameters) <> 2) then
    Exit;

  var LKeyType := LAddMethod.GetParameters[0].ParamType;
  var LValType := LAddMethod.GetParameters[1].ParamType;
  var LCountProp := LMapType.GetProperty('Count');

  if not Assigned(LCountProp) then
    Exit;

  var LToStringMethod: TRttiMethod := nil;
  var LFromStringMethod: TRttiMethod := nil;

  // Optional methods (on Key object)
  case LKeyType.TypeKind of
    tkClass:
      begin
        LToStringMethod := LKeyType.GetMethod('ToString');
        LFromStringMethod := LKeyType.GetMethod('FromString');
      end;
  end;

  Result := TDynamicMap.Create(AInstance, LKeyType, LValType, LAddMethod, LClearMethod, LCountProp, LKeyEnum, LValEnum, LToStringMethod, LFromStringMethod);
end;

function TDynamicMap.MoveNext: Boolean;
begin
  Result := (FKeyEnum.MoveNext and FValueEnum.MoveNext);
end;

function TDynamicMap.NewKey: TValue;
begin
  Result := TRttiUtils.CreateNewValue(FKeyType);
end;

function TDynamicMap.NewValue: TValue;
begin
  Result := TRttiUtils.CreateNewValue(FValueType);
end;

function TDynamicMap.KeyIsString: Boolean;
begin
  Result := Assigned(FToStringMethod) and Assigned(FFromStringMethod);
end;

function TDynamicMap.KeyToString(const AKey: TValue): string;
begin
  if Assigned(FToStringMethod) then
    Result := FToStringMethod.Invoke(AKey.AsObject, []).AsString
  else
    Result := '';
end;

constructor TDynamicMap.TEnumerator.Create(AMethod: TRttiMethod; AInstance: TObject);
begin
  // Memory creation, must destroy the object
  FInstance := AMethod.Invoke(AInstance, []).AsObject;
  FCurrentProperty := TRttiUtils.Context.GetType(FInstance.ClassInfo).GetProperty(CURRENT_PROP);

  if not Assigned(FCurrentProperty) then
    raise ENeonException.CreateFmt('Property [%s] not found', [CURRENT_PROP]);

  FMoveNextMethod := TRttiUtils.Context.GetType(FInstance.ClassInfo).GetMethod(MOVENEXT_METH);

  if not Assigned(FMoveNextMethod) then
    raise ENeonException.CreateFmt('Method [%s] not found', [MOVENEXT_METH]);
end;

function TDynamicMap.TEnumerator.Current: TValue;
begin
  Result := FCurrentProperty.GetValue(FInstance);
end;

destructor TDynamicMap.TEnumerator.Destroy;
begin
  FInstance.Free;
  inherited;
end;

function TDynamicMap.TEnumerator.MoveNext: Boolean;
begin
  Result := FMoveNextMethod.Invoke(FInstance, []).AsBoolean;
end;

constructor TDynamicNullable.Create(AInstance: TValue; ATypeInfoMethod, AHasValueMethod, AGetValueMethod, ASetValueMethod: TRttiMethod);
begin
  FInstance := AInstance;
  FTypeInfoMethod := ATypeInfoMethod;
  FHasValueMethod := AHasValueMethod;
  FGetValueMethod := AGetValueMethod;
  FSetValueMethod := ASetValueMethod;
end;

class function TDynamicNullable.GuessType(AInstance: TValue): IDynamicNullable;
begin
  if AInstance.IsEmpty then
    Exit(nil);

  var LType := TRttiUtils.Context.GetType(AInstance.TypeInfo);

  if not Assigned(LType) then
    Exit(nil);

  var LTypeInfoMethod := LType.GetMethod('GetValueType');

  if not Assigned(LTypeInfoMethod) then
    Exit(nil);

  var LContainedType := LTypeInfoMethod.Invoke(AInstance, []).AsType<PTypeInfo>;

  if LContainedType = nil then
    raise ENeonException.Create('Nullable contains type with no RTTI');

  var LHasValueMethod := LType.GetMethod('GetHasValue');

  if not Assigned(LHasValueMethod) then
    Exit(nil);

  var LGetValueMethod := LType.GetMethod('GetValue');

  if not Assigned(LGetValueMethod) then
    Exit(nil);

  var LSetValueMethod := LType.GetMethod('SetValue');

  if not Assigned(LSetValueMethod) then
    Exit(nil);

  Result := Self.Create(AInstance, LTypeInfoMethod, LHasValueMethod, LGetValueMethod, LSetValueMethod);
end;

function TDynamicNullable.HasValue: Boolean;
begin
  Result := FHasValueMethod.Invoke(FInstance, []).AsBoolean;
end;

procedure TDynamicNullable.SetValue(const AValue: TValue);
begin
  FSetValueMethod.Invoke(FInstance, [AValue]);
end;

function TDynamicNullable.GetValue: TValue;
begin
  Result := FGetValueMethod.Invoke(FInstance, []);
end;

function TDynamicNullable.GetValueType: PTypeInfo;
begin
  Result := FTypeInfoMethod.Invoke(FInstance, []).AsType<PTypeInfo>;
end;

end.
