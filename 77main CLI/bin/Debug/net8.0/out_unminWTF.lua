

local Byte,Char,Sub,Concat,LDExp,GetFEnv,Setmetatable,Select,Unpack,ToNumber,Next = string.byte,string.char,string.sub,table.concat,math.ldexp,getfenv or function() return _ENV end,setmetatable,select,unpack,tonumber,next;
local decompress = function(b)local c,d,e="","",{}local f=256;local g={}for h=0,f-1 do g[h]=Char(h)end;local i=1;local function k()local l=ToNumber(Sub(b, i,i),36)i=i+1;local m=ToNumber(Sub(b, i,i+l-1),36)i=i+l;return m end;c=Char(k())e[1]=c;while i<#b do local n=k()if g[n]then d=g[n]else d=c..Sub(c, 1,1)end;g[f]=c..Sub(d, 1,1)e[#e+1],c,f=d,d,f+1 end;return Concat(e)end;local ByteString=decompress(ByteString_Full);
local BitXOR = function(a, b)
    local p, c = 1, 0
    while a > 0 and b > 0 do
        local ra, rb = a % 2, b % 2
        if ra ~= rb then
            c = c + p
        end
        a, b, p = (a - ra) / 2, (b - rb) / 2, p * 2
    end
    if a < b then
        a = b
    end
    while a > 0 do
        local ra = a % 2
        if ra > 0 then
            c = c + p
        end
        a, p = (a - ra) / 2, p * 2
    end
    return c
end
local function gBit(Bit, Start, End)
    if End then
        local Res = (Bit / 2 ^ (Start - 1)) % 2 ^ ((End - 1) - (Start - 1) + 1);
        return Res - Res % 1;
    else
        local Plc = 2 ^ (Start - 1);
        return (Bit % (Plc + Plc) >= Plc) and 1 or 0;
    end;
end;
local Pos = 1;
local XOR_KEY_REPLACE = XOR_KEY
local function gBits32()
    local W, X, Y, Z = Byte(ByteString, Pos, Pos + 3);
    W = BitXOR(W, XOR_KEY_REPLACE)
    X = BitXOR(X, XOR_KEY_REPLACE)
    Y = BitXOR(Y, XOR_KEY_REPLACE)
    Z = BitXOR(Z, XOR_KEY_REPLACE)
    Pos = Pos + 4;
    return (Z * 16777216) + (Y * 65536) + (X * 256) + W;
end;
local function gBits8()
    local F = BitXOR(Byte(ByteString, Pos, Pos), XOR_KEY_REPLACE);
    Pos = Pos + 1;
    return F;
end;
local function gFloat()
    local Left, Right = gBits32(), gBits32();
    if Left == 0 and Right == 0 then
        return 0;
    end;
    local IsNormal = 1;
    local Mantissa = (gBit(Right, 1, 20) * (2 ^ 32)) + Left;
    local Exponent = gBit(Right, 21, 31);
    local Sign = ((-1) ^ gBit(Right, 32));
    if (Exponent == 0) then
        if (Mantissa == 0) then
            return Sign * 0; -- +-0
        else
            Exponent = 1;
            IsNormal = 0;
        end;
    elseif (Exponent == 2047) then
        if (Mantissa == 0) then
            return Sign * (1 / 0); -- +-Inf
        else
            return Sign * (0 / 0); -- +-Q/Nan
        end;
    end;
    -- sign * 2**e-1023 * isNormal.mantissa
    return Sign * 2 ^ (Exponent - 1023) * (IsNormal + (Mantissa / (2 ^ 52)))
end;
local gSizet = gBits32;
local function gString(Len)
    local Str;
    Len = gSizet();
    if (Len == 0) then
        return '';
    end;
    Str = Sub(ByteString, Pos, Pos + Len - 1);
    Pos = Pos + Len;
    local FStr = {}
    for Idx = 1, #Str do
        FStr[Idx] = Char(BitXOR(Byte(Sub(Str, Idx, Idx)), XOR_KEY_REPLACE))
    end
    return Concat(FStr);
end;
local gInt = gBits32;
local function _R(...)
    return { ... }, Select('#', ...)
end
local function gCrashConstant()
    return Setmetatable({}, {
        ['\95\95\105\110\100\101\120'] = function()
            while true do
            end
        end,
        ['\95\95\110\101\119\105\110\100\101\120'] = function()
            while true do
            end
        end,
        ['\95\95\116\111\115\116\114\105\110\103'] = function()
            while true do
            end
        end,
        ['\95\95\105\116\101\114'] = function()
            while true do
            end
        end,
    })
end
local function Deserialize()
    local Chunk = {--Instrs,
    --nil,
    --Functions,
    --nil,
    --Lines
};
Chunk[PARAMS_CHUNK] = gBits8();
								local ConstCount = gBits32()
    							local Consts = {};

								for Idx=1,ConstCount do 
									local Type=gBits8();
	
									if(Type==1) then 
										Consts[Idx]=(gBits8() ~= 0);
									elseif(Type==3) then 
										Consts[Idx] = gFloat();
									elseif(Type==0) then 
										if gBits8() == 1 then 
											Consts[Idx] = gCrashConstant() 
										else 
											Consts[Idx]=gString() 
										end;
									end;
									
								end;
								Chunk[CONST_CHUNK] = Consts;
								Chunk[PROTO_CHUNK] = {};for Idx=1,gBits32() do Chunk[PROTO_CHUNK][Idx-1]=Deserialize();end;Chunk[INSTR_CHUNK] = {};
								for Idx=1,gBits32() do 
									local Data1=BitXOR(gBits32(),3);
									local Data2=BitXOR(gBits32(),96); 

									local Type=gBit(Data1,1,2);
									local Opco=gBit(Data2,1,11);
									
									local Inst=
									{
										[OP_ENUM] = Opco,
										[OP_A] = gBit(Data1,3,11),
										nil,
										nil,
										[OP_DATA] = Data2
									};

									if (Type == 0) then 
										Inst[OP_B]=gBit(Data1,12,20);
										Inst[OP_C]=gBit(Data1,21,29);
									elseif(Type == 1) then 
										Inst[OP_B]=gBit(Data2,12,33);
									elseif(Type == 2) then 
										Inst[OP_B]=gBit(Data2,12,32)-1048575;
									elseif(Type == 3) then 
										Inst[OP_B]=gBit(Data2,12,32)-1048575;
										Inst[OP_C]=gBit(Data1,21,29);
									end;
									
									Chunk[INSTR_CHUNK][Idx]=Inst;end;return Chunk;end;