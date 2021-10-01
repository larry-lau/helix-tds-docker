
$ports = @(443, 8079, 8984, 14330)

$results = $ports | % {
    $result = Test-NetConnection -ComputerName localhost -Port $_    
    if ($result.TcpTestSucceeded)
    {
        Write-Host "Port $_ is open" -ForegroundColor Red
    } else {
        Write-Host "Port $_ is close" -ForegroundColor Green
    }
}