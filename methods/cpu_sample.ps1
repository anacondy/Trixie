$csv = "cpu_sample.csv"; "utc,chrome_cpu,brave_cpu,edge_cpu,firefox_cpu,net_rx_bytes_per_s" | Out-File $csv
$prev = @{}; $prevNet = (Get-NetAdapterStatistics | Measure-Object ReceivedBytes -Sum).Sum; $prevT = Get-Date
while ($true) {
  Start-Sleep -Seconds 2
  $now = Get-Date; $dt = ($now - $prevT).TotalSeconds; $prevT = $now
  $line = @((Get-Date -AsUTC).ToString("yyyy-MM-ddTHH:mm:ssZ"))
  foreach ($n in "chrome","brave","msedge","firefox") {
    $cs = (Get-Process -Name $n -ErrorAction SilentlyContinue | Measure-Object CPU -Sum).Sum
    $d = if ($prev[$n]) { [math]::Round((($cs - $prev[$n]) / $dt) * 100 / [Environment]::ProcessorCount,1) } else { 0 }
    $prev[$n] = $cs; $line += "$d"
  }
  $net = (Get-NetAdapterStatistics | Measure-Object ReceivedBytes -Sum).Sum
  $line += [math]::Round(($net - $prevNet) / $dt,0); $prevNet = $net
  ($line -join ",") | Out-File $csv -Append
}
