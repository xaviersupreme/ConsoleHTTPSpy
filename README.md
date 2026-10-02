# ConsoleHTTPSpy
Luau HTTP Spy

### Hooks:
- game:HttpGet (And it's asynchronous version),
- game:HttpPost (And it's asynchronous version),
- request()
- May add websocket hooks soon

### Loader
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/xaviersupreme/ConsoleHTTPSpy/refs/heads/main/main.luau"))({
    FormatUrls = true;
    SetUrlsToClipboard = true;
    UnhookAfterMS = 10000; --/* 0 = disabled */
    SaveOutputToFile = true;
    MaxStringLength = 90; --/* Controls what the max string length can be in the 'FormatString' function  */
    StringPadding = string.rep(" ", 1); --/* Padding for the output messages */
    SkipDefaultHeaders = true;
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
})
```
---
<img width="1251" height="566" alt="Screenshot 2026-10-02 013510" src="https://github.com/user-attachments/assets/199e09df-f34a-4095-a176-e28515e69516" />
