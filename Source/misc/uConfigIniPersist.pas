unit uConfigIniPersist;
// MIT License
//
// Copyright (c) 2009 - Robert Love
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE
//

(*
 * Modified by David Cornelius of Retail Dimensions, Inc.
 * Used by permission from Kurt Beeken of RDi.
 *
 * Modified further by David Cornelius of Cornelius Concepts, LLC
 *)

{$TYPEINFO ON}

interface

uses
  SysUtils, Classes, Rtti, TypInfo, IniFiles;

type
  ///	<summary>
  ///	  An Attribute class that should be applied at the class level to define the "Config Section"
  ///	</summary>
  ///	<remarks>
  ///	  This attribute class defines the [Section] of the .INI file for the class; all the properties
  ///   get saved as NAME=VALUE pairs within this section; the property names become the value names.
  ///	  Only one instance of a class with IniClassAttribute can be used.
  ///	</remarks>
  IniClassAttribute = class(TCustomAttribute)
  private
    FIniKey: string;
  public
    ///	<summary>
    ///	  The constructor simply establishes the one field of the class.
    ///	</summary>
    ///	<param name="NewIniKey">
    ///	  <c>String. Required.</c> Establishes the [Section] of the .INI file for the class and its properties.
    ///	</param>
    constructor Create(const NewIniKey: string);
  published
    ///	<summary>
    ///	  The name of the [Section] in the .INI key for which this class is
    ///	  saved.
    ///	</summary>
    ///	<remarks>
    ///	  The property name should probably have been IniSection instead of
    ///	  IniKey.
    ///	</remarks>
    property IniKey: string read FIniKey write FIniKey;
  end;

  ///	<summary>
  ///	  This attribute class excludes a property from being loaded/saved.
  ///	</summary>
  /// <remarks>
  ///   This class doesn't have any properties or methods; it's mere existence in a class is a flag to the member
  /// </remarks>
  IniIgnoreAttribute = class(TCustomAttribute);

  ///	<summary>
  ///	  This attribute class provides an optional default value for a property
  ///	</summary>
  IniDefaultAttribute = class(TCustomAttribute)
  private
    FDefaultValue: string;
  public
    ///	<summary>
    ///	  The constructor method simply initializes the DefaultValue field.
    ///	</summary>
    ///	<param name="NewDefaultValue">
    ///	  <c>String. Required.</c> This is the new Default Value of the class member to which this attribute is applied.
    ///	</param>
    constructor Create(const NewDefaultValue: string);
  published
    ///	<summary>
    ///	  This field is used as a default value when reading a class member
    ///	  from an .Ini file.
    ///	</summary>
    property DefaultValue: string read FDefaultValue write FDefaultValue;
  end;

  ///	<summary>
  ///	  Special exception for use by the IniPersist class.
  ///	</summary>
  ///	<remarks>
  ///	  Simple descendant from the Exception class.
  ///	</remarks>
  EIniPersist = class(Exception);

  ///	<summary>
  ///	  Base class for classes that use attributes to load/save themselves. Descend from one of the descendants of this class.
  ///	</summary>
  TCfgPersist = class (TObject)
  private
    const
       CLASS_SECTION_MISSING = 'IniClass[SectionName] missing';
    procedure SetValue(aData : String;var aValue : TValue);
    function GetValue(var aValue : TValue) : String;
    function GetPropIgnoreAttribute(Obj: TRttiObject): IniIgnoreAttribute;
    function GetDefaultAttributeValue(Obj: TRttiObject): string;
    function GetClassAttribute(ObjTyp: TRttiType): IniClassAttribute;
  protected
    function GetClassSection(ClassType: TRttiType): string;
    function GetDataValue(const SectionName, ValueName, ValueDefault: string): string; virtual; abstract;
    procedure SetDataValue(const SectionName, ValueName, StrValue: string); virtual; abstract;
  end;

  ///	<summary>
  ///	  Descend your configuration classes from this class and define an IniClass attribute to define the section.
  ///   Then simply call load/save methods for very simple by loading and saving of all the property values of the class.
  ///	</summary>
  /// <example>
  ///  <code>
  ///  type
  ///    [MySection]
  ///    TMySettings = class(TIniPersist)
  ///      ...
  ///    end;
  ///  var MySettings: TMySettings;
  ///  MySettings := TMySettings.Create;
  ///  MySettings.Load(MyIniFilename);
  ///  </code>
  /// </example>
  TIniPersist = class (TCfgPersist)
  private
    var
      FIni : TIniFile;
  protected
    function GetDataValue(const SectionName, ValueName, ValueDefault: string): string; override;
    procedure SetDataValue(const SectionName, ValueName, StrValue: string); override;
  public
    ///	<summary>
    ///	  Load reads a configuration file and fills the given object with the
    ///	  settings found.
    ///	</summary>
    ///	<param name="FileName">
    ///	  <c>String. Required.</c> The name of the .INI file to read from.
    ///	</param>
    procedure Load(const FileName : String);
    ///	<summary>
    ///	  Save writes a configuration file using the settings from the given
    ///	  object.
    ///	</summary>
    ///	<param name="FileName">
    ///	  <c>String. Required.</c> The name of the .INI file to write.
    ///	</param>
    procedure Save(const FileName : String);
  end;

implementation


{ IniClassAttribute }

constructor IniClassAttribute.Create(const NewIniKey: string);
begin
  FIniKey := NewIniKey;
end;

{ IniDefaultAttribute }

constructor IniDefaultAttribute.Create(const NewDefaultValue: string);
begin
  FDefaultValue := NewDefaultValue;
end;

{ TCfgPersist }

function TCfgPersist.GetClassAttribute(ObjTyp: TRttiType): IniClassAttribute;
{ check to see if the IniClassAttribute is assigned }
var
  Attr: TCustomAttribute;
begin
  Result := nil;

  for Attr in ObjTyp.GetAttributes do
    if Attr is IniClassAttribute then begin
      Result := IniClassAttribute(Attr);
      Break;
    end;
end;

function TCfgPersist.GetClassSection(ClassType: TRttiType): string;
var
  IniClass: IniClassAttribute;
begin
  // ensure this class is using "class-level" keys
  IniClass := GetClassAttribute(ClassType);
  if Assigned(IniClass) then
    // if using class-level INI keys, this is the [INIKEY] for the class and the properties define themselves as Key Names
    Result := IniClass.IniKey
  else
    raise EIniPersist.Create(CLASS_SECTION_MISSING);
end;

function TCfgPersist.GetDefaultAttributeValue(Obj: TRttiObject): string;
{ check to see if the IniDefaultAttribute is assigned; if so, return the default string }
var
  Attr: TCustomAttribute;
begin
  Result := EmptyStr;

  for Attr in Obj.GetAttributes do
    if Attr is IniDefaultAttribute then begin
      Result := IniDefaultAttribute(Attr).DefaultValue;
      Break;
    end;
end;

function TCfgPersist.GetPropIgnoreAttribute(Obj: TRttiObject): IniIgnoreAttribute;
{ check to see if the IniIgnoreAttribute is assigned }
var
  Attr: TCustomAttribute;
begin
  Result := nil;

  for Attr in Obj.GetAttributes do
    if Attr is IniIgnoreAttribute then begin
      Result := IniIgnoreAttribute(Attr);
      Break;
    end;
end;

procedure TCfgPersist.SetValue(aData: String;var aValue: TValue);
var
  I: Integer;
  x: Double;
begin
  case aValue.Kind of
    tkWChar, tkLString, tkWString, tkString, tkChar, tkUString:
      aValue := aData;
    tkInteger, tkInt64: begin
      if not TryStrToInt(aData, i) then
        i := 0;
      aValue := i;
    end;
    tkFloat: begin
      if not TryStrToFloat(aData, x) then
        x := 0.0;
      aValue := x;
    end;
    tkEnumeration:
      aValue := TValue.FromOrdinal(aValue.TypeInfo,GetEnumValue(aValue.TypeInfo,aData));
    tkSet: begin
      i :=  StringToSet(aValue.TypeInfo,aData);
      TValue.Make(@i, aValue.TypeInfo, aValue);
    end;
  else
    raise EIniPersist.Create('SetValue - Type not supported');
  end;
end;

function TCfgPersist.GetValue(var aValue: TValue) : string;
begin
   if aValue.Kind in [tkWChar, tkLString, tkWString, tkString, tkChar, tkUString,
                      tkInteger, tkInt64, tkFloat, tkEnumeration, tkSet] then
     Result := aValue.ToString
   else
     raise EIniPersist.Create('GetValue - Type not supported');
end;

{ TIniPersist }

function TIniPersist.GetDataValue(const SectionName, ValueName, ValueDefault: string): string;
begin
  Result := FIni.ReadString(SectionName, ValueName, ValueDefault);
end;

procedure TIniPersist.SetDataValue(const SectionName, ValueName, StrValue: string);
begin
  FIni.WriteString(SectionName, ValueName, StrValue);
end;

procedure TIniPersist.Load(const FileName: String);
var
  ctx : TRttiContext;
  objType : TRttiType;
  Prop  : TRttiProperty;
  PropClass: TClass;
  Value : TValue;
  IniPropIgnore: IniIgnoreAttribute;
  Data : String;
  IniClassSection: string;
  IniDefault: string;
begin
  {$IFDEF UseCodeSite} CodeSite.EnterMethod('TIniPersist.Load');  {$ENDIF}
  {$IFDEF UseCodeSite} CodeSite.Send('filename', FileName); {$ENDIF}

  ctx := TRttiContext.Create;
  try
    FIni := TIniFile.Create(FileName);
    try
      objType := ctx.GetType(Self.ClassType);

      IniClassSection := GetClassSection(ObjType);

      // look at all the properties of the object
      for Prop in objType.GetProperties do begin
        // get the class to which the current property belongs
        PropClass := TRttiInstanceType(Prop.Parent).MetaclassType;

        // always ignore TInterfacedObject properties
        if PropClass <> TInterfacedObject then begin
          // look at each of the properties
          {$IFDEF UseCodeSite} CodeSite.Send(csmLevel1, 'checking property', Prop.Name); {$ENDIF}
          Data := EmptyStr;

          // check to see if this property is ignored in the INI file
          IniPropIgnore := GetPropIgnoreAttribute(Prop);
          if not Assigned(IniPropIgnore) then begin
            // not ignored, check to see if there's a default value
            IniDefault := GetDefaultAttributeValue(Prop);

            // finally, read the data using the property name as the value name
            Data := GetDataValue(IniClassSection, Prop.Name, IniDefault);
            {$IFDEF UseCodeSite} CodeSite.Send(Format('read "%s" from [%s] %s', [Data, IniClassSection, Prop.Name])); {$ENDIF}
          end;

          // if the data is available, we can now assign it
          if (not Data.IsEmpty) and prop.IsWritable then begin
            {$IFDEF UseCodeSite} CodeSite.Send(csmLevel2, 'data read from .INI file', Data); {$ENDIF}
            Value := Prop.GetValue(Self);
            SetValue(Data, Value);
            prop.SetValue(Self, Value);
          end;
        end;
      end;
    finally
      FIni.Free;
    end;
  finally
    ctx.Free;
  end;

  {$IFDEF UseCodeSite} CodeSite.ExitMethodCollapse('TIniPersist.Load'); {$ENDIF}
end;

procedure TIniPersist.Save(const FileName: String);
var
  ctx : TRttiContext;
  objType : TRttiType;
  Prop  : TRttiProperty;
  PropClass: TClass;
  Value : TValue;
  IniPropIgnore: IniIgnoreAttribute;
  Data : String;
  IniClassSection: string;
begin
  {$IFDEF UseCodeSite} CodeSite.EnterMethod('TIniPersist.Save'); {$ENDIF}
  {$IFDEF UseCodeSite} CodeSite.Send('filename', Filename); {$ENDIF}

  ctx := TRttiContext.Create;
  try
    FIni := TIniFile.Create(FileName);
    try
      objType := ctx.GetType(self.ClassInfo);

      IniClassSection := GetClassSection(ObjType);

      // look at all the properties of the object
      for Prop in objType.GetProperties do begin
        // get the class to which the current property belongs
        PropClass := TRttiInstanceType(Prop.Parent).MetaclassType;

        // always ignore TInterfacedObject properties
        if (PropClass <> TInterfacedObject) then begin
          {$IFDEF UseCodeSite} CodeSite.Send(csmLevel1, 'checking property', Prop.Name); {$ENDIF}
          // get the value to be saved
          Value := Prop.GetValue(Self);
          Data := GetValue(Value);

          // check to see if this property is ignored
          IniPropIgnore := GetPropIgnoreAttribute(Prop);
          if Assigned(IniPropIgnore) then
            continue
          else begin
            // not ignored and the IniClassSection is set, write out the data using property name as value name
            SetDataValue(IniClassSection, Prop.Name, Data);
            {$IFDEF UseCodeSite} CodeSite.Send(csmLevel2, 'data written to .INI file', Data); {$ENDIF}
          end;
        end;
      end;
    finally
      FIni.Free;
    end;
  finally
    ctx.Free;
  end;

  {$IFDEF UseCodeSite} CodeSite.ExitMethodCollapse('TIniPersist.Save');  {$ENDIF}
end;

end.

