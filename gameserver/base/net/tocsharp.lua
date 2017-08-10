
--将协议格式转换成C#格式的协议文件，用于客户端
function Export(pto, root)
	root = root or "protocol/client"
	local dataTrans = {
		["bool"] = {
			name = "bool", 
			reader = "<mem_name> = br.ReadBoolean();", 
			writer = "bw.Write(<mem_name>);", 
			length = {1, ""},
		},
		["uint8"] = {
			name = "byte", 
			reader = "<mem_name> = br.ReadByte();", 
			writer = "bw.Write(<mem_name>);", 
			length = {1, ""},
		},
		["uint16"] = {
			name = "ushort", 
			reader = "<mem_name> = br.ReadUInt16();", 
			writer = "bw.Write(<mem_name>);", 
			length = {2, ""},
		},
		["uint32"] = {
			name = "uint", 
			reader = "<mem_name> = br.ReadUInt32();", 
			writer = "bw.Write(<mem_name>);", 
			length = {4, ""},
		},
		["uint64"] = {
			name = "ulong", 
			reader = "<mem_name> = br.ReadUInt64();", 
			writer = "bw.Write(<mem_name>);", 
			length = {8, ""},
		},
		["int8"] = {
			name = "sbyte", 
			reader = "<mem_name> = br.ReadSByte();", 
			writer = "bw.Write(<mem_name>);", 
			length = {1, ""},
		},
		["int16"] = {
			name = "short", 
			reader = "<mem_name> = br.ReadInt16();", 
			writer = "bw.Write(<mem_name>);", 
			length = {2, ""},
		},
		["int32"] = {
			name = "int", 
			reader = "<mem_name> = br.ReadInt32();", 
			writer = "bw.Write(<mem_name>);", 
			length = {4, ""},
		},
		["int64"] = {
			name = "long", 
			reader = "<mem_name> = br.ReadInt64();", 
			writer = "bw.Write(<mem_name>);", 
			length = {8, ""},
		},
		["string"] = {
			name = "string", 
			reader = "<mem_name> = br.ReadString();", 
			writer = "bw.Write(<mem_name>);",
			length = {1, "iLen += (ushort)(<mem_name>.Length);"},
		},
		["float"] = {
			name = "float", 
			reader = "<mem_name> = br.ReadSingle();", 
			writer = "bw.Write(<mem_name>);", 
			length = {4, ""},
		},
		["double"] = {
			name = "double", 
			reader = "<mem_name> = br.ReadDouble();", 
			writer = "bw.Write(<mem_name>);", 
			length = {8, ""},
		},
		["custom"] = {
			reader = "<mem_name> = new <mem_type>();\n<mem_name>.Read(br);",
			writer = "<mem_name>.Write(bw);",
			length = {0, "iLen += <mem_name>.Length();"},
		},
	}
	local typeFileBody = [[
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;

public class NetType
{
%s
}
]]
	local typeStructBody = [[
	//结构体序列化
	[System.Serializable]
	public struct <type_name>
	{
		<mem_list>

		public void Read(BinaryReader br)
		{
			<read_list>
		}

		public void Write(BinaryWriter bw)
		{
			<write_list>
		}

		public ushort Length()
		{
			ushort iLen = <len_static>;
			<len_dynamic>
			return iLen;
		}
	}
]]
	local listReader0 = [[<mem_name> = new List<<mem_type>>();
bySize = br.ReadUInt16();
for (byte i=0; i<bySize; i++)
{
	<read>
	<mem_name>.Add(item);
}]]
	local listReaderN = [[<mem_name> = new List<<mem_type>>();
for (byte i=0; i<<count>; i++)
{
	<read>
	<mem_name>.Add(item);
}]]
	local listWriter0 = [[bw.Write((ushort)(<mem_name>.Count));
foreach(<mem_type> item in <mem_name>)
{
	<write>
}]]
	local listWriterN = [[for (byte i=0; i<<count>; i++)
{
	<mem_type> item = <mem_name>[i];
	<write>
}]]
	local listLenDynamic = [[foreach(<mem_type> item in <mem_name>)
{
	<len>
}]]
	local ptoReaderFile = [[
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;

public class <file_name>
{
	public delegate void ProtoHandler(ref byte[] buffer);
	private Dictionary<ushort, ProtoHandler> m_Handlers;

	public <file_name>()
	{
		m_Handlers = new Dictionary<ushort, ProtoHandler>();
		<reg_list>
	}
	
    public void Process(CPacketData stPack)
    {
        if (stPack == null) return;
		if (!m_Handlers.ContainsKey(stPack.m_iProtoID)) return;
		m_Handlers[stPack.m_iProtoID](ref stPack.m_Data);
    }

	<def_list>
}]]
	local ptoReaderStruct = [[public struct ST_<pto_name>
	{
		<pto_args_list>
	}
	public void Handler_<pto_name>(ref byte[] buffer)
	{
		if (<pto_name> == null) return;
		ST_<pto_name> stPack = new ST_<pto_name>();
		using (BinaryReader br = new BinaryReader(new MemoryStream(buffer)))
		{
			<pto_read_list>
		}
		<pto_name>(ref stPack);
	}
	public delegate void Delegate_<pto_name>(ref ST_<pto_name> stPack);
	public Delegate_<pto_name> <pto_name>;
]]
	local ptoReaderReg = "m_Handlers[%d]\t= Handler_%s;"
	local ptoWriterFile = [[
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;

public class <file_name>
{
	public class CWriteBase
	{
		public string _Name;
	}
	public delegate byte[] ProtoHandler(ref CWriteBase stPack);
	private Dictionary<string, ushort> m_Name2ID;
	private Dictionary<ushort, ProtoHandler> m_Handlers;
	
	public <file_name>()
	{
		m_Name2ID = new Dictionary<string, ushort>();
		m_Handlers = new Dictionary<ushort, ProtoHandler>();
		<reg_list>
	}
	
	public byte[] Process(CWriteBase stPack)
	{
		if (!m_Name2ID.ContainsKey(stPack._Name)) return null;
        ushort iProtoID = m_Name2ID[stPack._Name];
		if (!m_Handlers.ContainsKey(iProtoID)) return null;
		byte[] buff = m_Handlers[iProtoID](ref stPack);
		if (buff == null) return null;
		return Packet.Pack(iProtoID, buff);
	}
	
	<def_list>
}]]
	local ptoWriterStruct = [[public class <name> : CWriteBase
	{
        <member_list><ctor>
        public ushort Length()
        {
			<len_code>
        }
	}
	private byte[] Handler_<name>(ref CWriteBase stData)
	{
		<name> stPack = (<name>)stData;
		byte[] buffer = new byte[stPack.Length()];
		using(BinaryWriter bw = new BinaryWriter(new MemoryStream(buffer)))
		{
			<write_list>
		}
		return buffer;
	}
]]
	local ptoWriterCtor = [[
public <name>()
{
	_Name = "<name>";
	<init_list>
}]]
	local ptoWriterReg = [[m_Name2ID["<pto_name>"] = <pto_id>;m_Handlers[<pto_id>] = Handler_<pto_name>;]]
	
	local function __SaveFile(path, code)
		local file, err = io.open(path, "w")
		assert(file)
		file:write(code)
		file:close()
	end
	
	local function __Replace(str, trans)
		local ret = str
		for _, v in ipairs(trans) do
			ret = string.gsub(ret, v[1], v[2])
		end
		return ret
	end
	
	local function __Indent(str, num)
		local ret = string.gsub(str, "\n", "\n" .. string.rep("\t", num))
		return ret
	end
	
	local function __ConvertType(isreader, name, args)
		local argname, argtype, argnum, trans, typecfg
		local code
		local memList = {}
		local readerList = {}
		local writerList = {}
		local lenDynamic = {}
		local lenStatic = 0
		local bHasList = false
		for _, v in ipairs(args) do
			argname, argtype, argnum = v[1], v[2], v[3]
			trans = dataTrans[argtype]
			if trans then
				typecfg = dataTrans[argtype]
				argtype = typecfg.name
			else
				typecfg = dataTrans["custom"]
				argtype = "ST_" .. argtype
			end
			if not argnum or argnum == 1 then
				table.insert(memList, string.format("public %s %s;", argtype, argname))
				code = __Replace(typecfg.reader, {{"<mem_name>",argname}, {"<mem_type>",argtype}})
				table.insert(readerList, __Indent(code, 3))
				code = __Replace(typecfg.writer, {{"<mem_name>",argname}, {"<mem_type>",argtype}})
				table.insert(writerList, __Indent(code, 3))
				if not trans or v[2] == "string" then
					code = __Replace(typecfg.length[2], {{"<mem_name>",argname}, {";",";\n"}})
					table.insert(lenDynamic, __Indent(code, 3))
				end
				lenStatic = lenStatic + (typecfg.length[1] or 0)
			else
				table.insert(memList, string.format("public List<%s> %s;", argtype, argname))
				code = "<mem_type> " .. typecfg.reader
				code = __Replace(code, {{"<mem_name>","item"}})--, {";",";\n\t"}})
				local tmpReader, tmpWriter
				if argnum > 1 then
					tmpReader = listReaderN
					tmpWriter = listWriterN
				else
					tmpReader = listReader0
					tmpWriter = listWriter0
					bHasList = true
				end
				code = __Replace(tmpReader, {{"<read>",code}, {"<mem_name>",argname}, {"<mem_type>",argtype}, {"<count>",argnum}})
				table.insert(readerList, __Indent(code, 2))
				code = __Replace(typecfg.writer, {{"<mem_name>","item"}})
				code = __Indent(code, 1)
				code = __Replace(tmpWriter, {{"<write>",code}, {"<mem_name>",argname}, {"<mem_type>",argtype}, {"<count>",argnum}})
				table.insert(writerList, __Indent(code, 2))
				lenStatic = lenStatic + 1
				if not trans then
					code = string.gsub(typecfg.length[2], "<mem_name>", "item")
				elseif v[2] == "string" then
					code = string.format("iLen += %d;\n\t%s", typecfg.length[1], typecfg.length[2])
					code = string.gsub(code, "<mem_name>", "item")
				else
					code = string.format("iLen += %d;", typecfg.length[1])
				end
				if not trans or v[2] == "string" then
					code = __Replace(listLenDynamic, {{"<len>",code}, {"<mem_name>",argname},{"<mem_type>",argtype}})
				elseif typecfg.length[1] > 1 then
					code = string.format("iLen += (ushort)(%s.Count * %s);\n", argname, typecfg.length[1])
				else
					code = string.format("iLen += (ushort)(%s.Count);\n", argname)
				end
				table.insert(lenDynamic, __Indent(code, 2))
			end
		end
		if bHasList then
			table.insert(readerList, 1, "ushort bySize = 0;")
		end
		return __Replace(typeStructBody, {
			{"<type_name>", "ST_" .. name},
			{"<mem_list>", table.concat(memList, "\n\t\t")},
			{"<read_list>", table.concat(readerList, "\n\t\t\t")},
			{"<write_list>", table.concat(writerList, "\n\t\t\t")},
			{"<len_static>", tostring(lenStatic)},
			{"<len_dynamic>", table.concat(lenDynamic)},
		})
	end
	
	local function __ConvertReader(name, args)
		local argname, argtype, argnum, trans, typecfg
		local code
		local memList = {}
		local readerList = {}
		local bHasList = false
		for _, v in ipairs(args) do
			argname, argtype, argnum = v[1], v[2], v[3]
			trans = dataTrans[argtype]
			if trans then
				typecfg = dataTrans[argtype]
				argtype = typecfg.name
			else
				typecfg = dataTrans["custom"]
				argtype = "NetType.ST_" .. argtype
			end
			if not argnum or argnum == 1 then
				table.insert(memList, string.format("public %s %s;", argtype, argname))
				code = __Replace(typecfg.reader, {{"<mem_name>","stPack."..argname}, {"<mem_type>",argtype}})
				table.insert(readerList, __Indent(code, 3))
			else
				table.insert(memList, string.format("public List<%s> %s;", argtype, argname))
				code = "<mem_type> " .. typecfg.reader
				code = __Replace(code, {{"<mem_name>","item"}})--, {";",";\n\t"}})
				local tmpReader
				if argnum > 1 then
					tmpReader = listReaderN
				else
					tmpReader = listReader0
					bHasList = true
				end
				code = __Replace(tmpReader, {{"<read>",code}, {"<mem_name>","stPack."..argname}, {"<mem_type>",argtype}, {"<count>",argnum}})
				table.insert(readerList, __Indent(code, 3))
			end
		end
		if bHasList then
			table.insert(readerList, 1, "ushort bySize = 0;")
		end
		return __Replace(ptoReaderStruct, {
			{"<pto_name>", name},
			{"<pto_args_list>", table.concat(memList, "\n\t\t")},
			{"<pto_read_list>", table.concat(readerList, "\n\t\t\t")},
		})
	end
	
	local function __ConvertWriter(name, args)
		local argname, argtype, argnum, trans, typecfg
		local code
		local memList = {}
		local initList = {}
		local writerList = {}
		local lenStatic = 0
		local lenDynamic = {}
		for _, v in ipairs(args) do
			argname, argtype, argnum = v[1], v[2], v[3]
			trans = dataTrans[argtype]
			if trans then
				typecfg = dataTrans[argtype]
				argtype = typecfg.name
			else
				typecfg = dataTrans["custom"]
				argtype = "NetType.ST_" .. argtype
			end
			if not argnum or argnum == 1 then
				table.insert(memList, string.format("public %s %s;", argtype, argname))
				if not trans then
					table.insert(initList, string.format("%s = %s;", argname, argtype))
				end
				code = __Replace(typecfg.writer, {{"<mem_name>", "stPack."..argname}})
				table.insert(writerList, __Indent(code, 3))
				if not trans or v[2] == "string" then
					code = __Replace(typecfg.length[2], {{"<mem_name>",argname}, {";",";\n"}})
					table.insert(lenDynamic, __Indent(code, 3))
				end
				lenStatic = lenStatic + (typecfg.length[1] or 0)
			else
				table.insert(memList, string.format("public List<%s> %s;", argtype, argname))
				table.insert(initList, string.format("%s = new List<%s>();", argname, argtype))
				local tmpWriter = argnum > 1 and listWriterN or listWriter0
				code = __Replace(typecfg.writer, {{"<mem_name>","item"}})
				code = __Indent(code, 1)
				code = __Replace(tmpWriter, {{"<write>",code}, {"<mem_name>","stPack."..argname}, {"<mem_type>",argtype}, {"<count>",argnum}})
				table.insert(writerList, __Indent(code, 3))
				lenStatic = lenStatic + 2
				if not trans then
					code = string.gsub(typecfg.length[2], "<mem_name>", "item")
				elseif v[2] == "string" then
					code = string.format("iLen += %d;\n\t%s", typecfg.length[1], typecfg.length[2])
					code = string.gsub(code, "<mem_name>", "item")
				else
					code = string.format("iLen += %d;", typecfg.length[1])
				end
				if not trans or v[2] == "string" then
					code = __Replace(listLenDynamic, {{"<len>",code}, {"<mem_name>",argname},{"<mem_type>",argtype}})
				elseif typecfg.length[1] > 1 then
					code = string.format("iLen += (ushort)(%s.Count * %s);\n", argname, typecfg.length[1])
				else
					code = string.format("iLen += (ushort)(%s.Count);\n", argname)
				end
				table.insert(lenDynamic, __Indent(code, 2))
			end
			
		end
		local initCode = ""
		if #initList > 0 then
			initCode = table.concat(initList, "\n")
			initCode = __Indent(initCode, 1)
		end
		initCode = __Replace(ptoWriterCtor, {{"<name>", name},{"<init_list>",initCode}})
		initCode = __Indent(initCode, 2)
		local lencode
		if #lenDynamic > 0 then
			lencode = string.format("ushort iLen = %s;\n\t\t\t%sreturn iLen;",
				tostring(lenStatic), table.concat(lenDynamic)
			)
		else
			lencode = string.format("return %s;", tostring(lenStatic))
		end
		
		local result = __Replace(ptoWriterStruct, {
			{"<name>", name},
			{"<ctor>", initCode},
			{"<write_list>", table.concat(writerList, "\n\t\t\t")},
			{"<len_code>", lencode},
		})
		if #memList > 0 then
			result = __Replace(result, {{"<member_list>", table.concat(memList, "\n\t\t").."\n\t\t"}})
		else
			result = string.gsub(result, "<member_list>", "")
		end
		return result
	end
	
	local code = ""
	for name, info in pairs(pto.NetType) do
		if type(info) == "table" then
			code = code .. __ConvertType(true, name, info.args)
		end
	end
	code = string.format(typeFileBody, code)
	__SaveFile(root.."/NetType.cs", code)
	
	--s2c
	local defList = {}
	local regList = {}
	for idx, info in ipairs(pto.NetS2C) do
		table.insert(defList, __ConvertReader(info.name, info.args))
		table.insert(regList, string.format(ptoReaderReg, idx, info.name))
	end
	code = __Replace(ptoReaderFile, {
		{"<file_name>", "NetReader"},
		{"<def_list>", table.concat(defList, "\n\t")},
		{"<reg_list>", table.concat(regList, "\n\t\t")},
	})
	__SaveFile(root.."/NetReader.cs", code)
	
	--c2s
	defList = {}
	regList = {}
	for idx, info in ipairs(pto.NetC2S) do
		table.insert(defList, __ConvertWriter(info.name, info.args))
		table.insert(regList, __Replace(ptoWriterReg, {{"<pto_id>",idx}, {"<pto_name>",info.name}}))
	end
	code = __Replace(ptoWriterFile, {
		{"<file_name>", "NetWriter"},
		{"<def_list>", table.concat(defList, "\n\t")},
		{"<reg_list>", table.concat(regList, "\n\t\t")},
	})
	__SaveFile(root.."/NetWriter.cs", code)
end