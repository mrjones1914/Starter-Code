Get-WmiObject Win32_logicaldisk -ComputerName LocalHost `
| Format-Table DeviceID, MediaType, `
@{Name="Size(GB)";Expression={[decimal]("{0:N0}" -f($_.size/1gb))}}, `
@{Name="Free Space(GB)";Expression={[decimal]("{0:N0}" -f($_.freespace/1gb))}}, `
@{Name="Free (%)";Expression={"{0,6:P0}" -f(($_.freespace/1gb) / ($_.size/1gb))}} `
-AutoSize