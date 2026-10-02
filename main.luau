if (not game:IsLoaded()) then
	game.Loaded:Wait() end;

if (not (...) or type(...) ~= "table") then
	warn("[*] Running with default options.") end;

getgenv().Config = (...) or {
	FormatUrls = true;
	SetUrlsToClipboard = true;
	UnhookAfterMS = 0;
	SaveOutputToFile = true;
	MaxStringLength = 95;
	StringPadding = string.rep(" ", 1);
	SkipDefaultHeaders = false;
	DefaultHeaders = {	
		["Host"] = true;
		["Accept"] = true;
		["User-Agent"] = true;
		["Roblox-Session-Id"] = true;
		["Roblox-Game-Id"] = true;
		["X-Amzn-Trace-Id"] = true;
		[`{table.pack(identifyexecutor())[1]}-User-Identifier`] = true;
		[`{table.pack(identifyexecutor())[1]}-Fingerprint`] = true;
	};
};

type Response = {
	Body: string;
	StatusCode: number;
	StatusMessage: string;
	Success: boolean;
	Headers: {};
}

type HttpRequest = {
	Url: string;
	Method: string;
	Body: string?;
	Headers: {}?;
	Cookies: {}?;
}

const Rep, Sub, Replace, Find, Lower, Upper, Format = string.rep, string.sub, string.gsub, string.find, string.lower, string.upper, string.format;
const Pack, Unpack, Clear = table.pack, table.unpack, table.clear;
const Type = typeof;

const Hash: string = crypt.hash(crypt.generatekey(), "md5");
const START_TIME_RUNTIME = tick();
const LogFile = `HTTP_{Hash}.log`;

if (not isfile(LogFile)) then
	writefile(LogFile, "") end;

const Log = {
	Output = (function(msg: any, ...: any): nil game:GetService("LogService"):Log(Enum.MessageType.MessageOutput, msg, ...); if (Config.SaveOutputToFile) then appendfile(LogFile, `{msg}\n`) end; return nil; end);
	Info = (function(msg: any, ...: any): nil game:GetService("LogService"):Log(Enum.MessageType.MessageInfo, msg, ...); if (Config.SaveOutputToFile) then appendfile(LogFile, `{msg}\n`) end; return nil; end);
	Warn = (function(msg: any, ...: any): nil game:GetService("LogService"):Log(Enum.MessageType.MessageWarning, msg, ...); if (Config.SaveOutputToFile) then appendfile(LogFile, `{msg}\n`) end; return nil; end);
	Error = (function(msg: any, ...: any): nil game:GetService("LogService"):Log(Enum.MessageType.MessageError, msg, ...); if (Config.SaveOutputToFile) then appendfile(LogFile, `{msg}\n`) end; return nil; end); 
};

const HTTPMethods: { [any]: string } = {
	HttpGet = "HttpGet";
	HttpGetAsync = "HttpGetAsync";
	HttpPost = "HttpPost";
	HttpPostAsync = "HttpPostAsync";
}; 

const WebFunctions: { [any]: (...any) -> ...any } = { 
	Request = request; 
	WebSocket = WebSocket.connect;
};

const Services = setmetatable({}, {__index = function(Self, Key)
    const Service = game:GetService(Key);

	if (not Service) then 
		return (nil) end;

	return (Service);
end})

function FormatString(Str: string?, AddedSize: number?): string
	if (Type(Str) ~= "string" or #tostring(Str) == 0) then
		return ("null (no-string)") end;
	if (not AddedSize) then
		AddedSize = 0 end;

	const MAX_STR_LEN: number = Config.MaxStringLength or 105 - AddedSize :: number;
	const MIN_STR_LEN: number = 0;

	local FinalString: string = tostring(Str);

	if (#FinalString  > MAX_STR_LEN) then
		FinalString = `{Sub(Str, MIN_STR_LEN, MAX_STR_LEN)}...`;
	end

	FinalString = Replace(FinalString, "\n", "");	
	FinalString = Replace(FinalString, "\t", " ");
	FinalString = Replace(FinalString, "    ", " ");

	return (FinalString);
end

function SerializeArguments(Tbl: {}): string
	local FinalStr: string = "";
	const ArgC: number = #Tbl;

	if (ArgC == 0) then
		return ("null (noargs)");
	end

	for Index, Arg in next, (Tbl) do
		if (Index == ArgC) then
			FinalStr ..= `{Arg}`;

			break;
		end

		FinalStr ..= `{Arg}, `;
	end

	return (FinalStr);
end

function RecurseTable(Tbl: { [any]: any }, Padding: string)
    if (Type(Tbl) ~= "table") then
        Log.Output(`{Config.StringPadding}[>] null (no-tbl)`); return end;
	if (not next(Tbl)) then
        Log.Output(`{Config.StringPadding}{Padding}[>] null (no-keys)\n`); return end;

	for Key, Value in next, (Tbl) do
		if (Config.SkipDefaultHeaders and Config.DefaultHeaders[Key]) then
			continue;
		end

		if (not next(Tbl, Key) and Type(Value) ~= "table") then
			Log.Output(`{Config.StringPadding}{Padding}[>] {Key}: {FormatString(tostring(Value), #tostring(Key))}\n`);
		else
			Log.Output(`{Config.StringPadding}{Padding}[>] {Key}: {FormatString(tostring(Value), #tostring(Key))}`);
		end

		if (Type(Value) == "table") then
			RecurseTable(Value, `{Padding}{Padding}`);
		end
	end
end

function IsJSON(Str: string): boolean
	local ok: boolean = pcall(function()
		return Services.HttpService:JSONDecode(Str);
	end)

	return ok;
end

Log.Info("[*] Started HTTP Spy.");

const HConsoleThread = task.spawn(function()
	repeat task.wait() until (Services.CoreGui:FindFirstChild("DevConsoleMaster"));

	const DevConsoleMaster: Instance? = Services.CoreGui:FindFirstChild("DevConsoleMaster");

	const function HandleInst(Inst: Instance): nil
		if (Inst:IsA("TextLabel") and Find(Inst.Text, "[!]", 1, true)) then
			const Parent: Instance? = Inst.Parent;

			if (Parent) then
				local ImageLabel: ImageLabel? = Parent:FindFirstChildOfClass("ImageLabel");

				if (ImageLabel) then
					ImageLabel:Destroy();
				end
			end	

			Inst.TextColor3 = Color3.fromHSV(0.333333, 1, 255);
		end

		return (nil);
	end

	if (DevConsoleMaster) then
		DevConsoleMaster.DescendantAdded:Connect(function(Inst: Instance)
			HandleInst(Inst);
		end)
	end

	return (nil);
end)

local OldHttpGet; OldHttpGet = hookmetamethod(game, "__namecall", newcclosure(function(Self: any, Url: string, ...): string
	local OtherArgs: {} = Pack(...);
	local Result: string = OldHttpGet(Self, Url, ...);

	const function HandleGetMethod(Method: string)
		const FormattedRes: string? = FormatString(tostring(Result));
		const Serialized: string = SerializeArguments(OtherArgs);
		const Padding: string = Config.StringPadding or Rep(" ", 2);
		local FormattedUrl: string? = Url;

		if (Config.FormatUrls) then
			FormattedUrl = FormatString(Url);
		end

		if (Config.SetUrlsToClipboard) then
			setclipboard(tostring(Url)); 
		end

		Log.Info(`[!] Intercepted HTTP GET Request.`);

		if (not Url) then
			Log.Error(`[X] Url not found. {Self}, {Url}, {Result}`);
		end

		Log.Info(`{Padding}[*] SENT`);
		Log.Output(`{Padding}{Padding}[>] Method: {Method}`);
		Log.Output(`{Padding}{Padding}[>] Args: {Serialized}`);
		Log.Output(`{Padding}{Padding}[>] Url: {FormattedUrl}\n`);
		
		Log.Info(`{Padding}[*] RECIEVED`);
		if (FormattedRes == "") then
			Log.Output(`{Padding}{Padding}[<] Response: nxdomain or 404 Not Found (guess)`);
			Log.Output(`{Padding}{Padding}[<] Res: null\n`);
		elseif (IsJSON(tostring(Result))) then
			RecurseTable(Services.HttpService:JSONDecode(tostring(Result)), Padding)
		else
			Log.Output(`{Padding}{Padding}[<] Response: 200 OK (guess)`);
			Log.Output(`{Padding}{Padding}[<] Res: {FormattedRes}\n`);
		end
	end

	if (getnamecallmethod() == HTTPMethods.HttpGet and checkcaller()) then
		HandleGetMethod(HTTPMethods.HttpGet);
	elseif (getnamecallmethod() == HTTPMethods.HttpGetAsync and checkcaller()) then
		HandleGetMethod(HTTPMethods.HttpGetAsync);
	end

	return (Result);
end))

local OldHttpPost; OldHttpPost = hookmetamethod(game, "__namecall", newcclosure(function(Self: any, Url: string, Data: string, ...)
	local Result: string = OldHttpPost(Self, Url, Data, ...);
	local Args: any = (...);

	const function HandlePostMethod(Method: string)
		local OtherArgs: {} = Pack(Args)
		const FormattedRes: string? = FormatString(tostring(Result));
		const Serialized: string = SerializeArguments(OtherArgs);
		const Padding: string = Config.StringPadding or Rep(" ", 2);
		local FormattedUrl: string? = FormatString(Url);
		const FormattedData: string = FormatString(Data);

		if (not Config.FormatUrls) then
			FormattedUrl = Url;
		end

		if (Config.SetUrlsToClipboard) then
			setclipboard(tostring(Url)); 
		end

		Log.Info(`[!] Intercepted HTTP POST Request.`);

		if (not Url) then
			Log.Error(`[X] Url not found {Self}, {Url}, {Result}`);
		end

		Log.Info(`{Padding}[*] SENT`);
		Log.Output(`{Padding}{Padding}[>] Method: {Method}`);
		Log.Output(`{Padding}{Padding}[>] Args: {Serialized}`);
		Log.Output(`{Padding}{Padding}[>] Url: {FormattedUrl}`);
		Log.Output(`{Padding}{Padding}[>] Data: {FormattedData}\n`)
		
		Log.Info(`{Padding}[*] RECIEVED`);
		if (FormattedRes == "") then
			Log.Output(`{Padding}{Padding}[<] Response: nxdomain or 404 Not Found (guess)`);
			Log.Output(`{Padding}{Padding}[<] Res: null\n`);
		elseif (IsJSON(tostring(Result))) then
			RecurseTable(Services.HttpService:JSONDecode(tostring(Result)), Padding)
		else
			Log.Output(`{Padding}{Padding}[<] Response: 200 OK (guess)`);
			Log.Output(`{Padding}{Padding}[<] Res: {FormattedRes}\n`);
		end
	end

	if (getnamecallmethod() == HTTPMethods.HttpPost and checkcaller()) then
		HandlePostMethod(HTTPMethods.HttpPost)
	elseif (getnamecallmethod() == HTTPMethods.HttpPostAsync and checkcaller()) then
		HandlePostMethod(HTTPMethods.HttpPostAsync)
	end

	return (Result);
end))

local OldRequest; OldRequest = hookfunction(WebFunctions.Request, newcclosure(function(Options: HttpRequest): ()
	const Result: Response = OldRequest(Options);
	local BodyDecoded: {} | string; 
	local SentBodyDecoded: {};

	if (Result.Body and IsJSON(Result.Body)) then
		BodyDecoded = Services.HttpService:JSONDecode(Result.Body)
	else
		BodyDecoded = Result.Body or "";
	end

	if (Options.Body) then
		SentBodyDecoded = Services.HttpService:JSONDecode(Options.Body or "{}")
	end

	const Padding: string = Config.StringPadding or Rep(" ", 2);
	local FormattedUrl: string? = Options.Url;

	if (Config.FormatUrls) then
		FormattedUrl = FormatString(Options.Url);
	end

	if (Config.SetUrlsToClipboard) then
		setclipboard(tostring(Options.Url)); 
	end

	Log.Info(`[!] Intercepted HTTP {Options.Method} Request. {Result.StatusCode} {Result.StatusMessage}`)

	if (not Options.Url) then
		Log.Error(`[x] Url is #gone. {Options.Url}, {Options.Body}, {Result}`)
	end

	Log.Info(`{Padding}[*] SENT`);
	Log.Output(`{Padding}{Padding}[>] Method: WebFunctions.Request`);
	Log.Output(`{Padding}{Padding}[>] Url: {FormattedUrl}\n`)

	if (Options.Body) then
		Log.Info(`{Padding}[*] Body`)

		RecurseTable(SentBodyDecoded, Padding);
	end

	if (Options.Headers) then
		Log.Info(`{Padding}[*] Headers`)

		RecurseTable(Options.Headers, Padding)
	end

	if (Options.Cookies) then
		Log.Info(`{Padding}[*] Cookies`)

		RecurseTable(Options.Cookies, Padding)
	end

	Log.Info(`{Padding}[*] RECEIEVED`);

	if (BodyDecoded and type(BodyDecoded) == "table") then
		RecurseTable(BodyDecoded, Padding)
	else
		Log.Output(`{Padding}{Padding}[>] Body: {FormatString(tostring(BodyDecoded))}\n`)
	end

	return (Result);
end))

Log.Info(`[*] Loaded HTTP Hooks in {Format("%.5f", tick() - START_TIME_RUNTIME)}.\n`)

if (Config.UnhookAfterMS and Config.UnhookAfterMS ~= 0) then
	task.delay(Config.UnhookAfterMS / 1000, function()
		const START_TIME_UNHOOK = tick();

		Log.Info("[~] Unhooking")
		
		hookfunction(WebFunctions.Request, OldRequest);
		hookmetamethod(game, "__namecall", OldHttpGet);
		task.cancel(HConsoleThread);
		Clear(Config); Config = nil;

		Log.Info(`[*] Unhooked in {Format("%.5f", tick() - START_TIME_UNHOOK)}. Total Runtime: {Format("%.5f", START_TIME_UNHOOK - START_TIME_RUNTIME)}\n`)
	end)
end
