
<#
	.SYNOPSIS
	PowerCLI Script to Configure NTP on ESXi Hosts
	.EXAMPLE
	Set_HostNtp.ps1 
	PowerCLI Session must be connected to vCenter Server using Connect-VIServer
	
	.NOTES
	raoconnor 01/10/15
	Acknowledgement: http://www.vhersey.com/2013/10/setting-esxi-dns-and-ntp-using-powercli/
	Acknowledgement: http://www.simonlong.co.uk/blog/2010/03/09/powercli-reconfiguring-ntp-servers-on-esx-hosts/
	Acknowledgement: http://www.virtu-al.net/2013/08/19/simple-host-time-information/
#>

# Intro
Write-Host "This script is for reconfiguring NTP on esx hosts" -ForegroundColor Yellow


# cluster option: select hosts based on folder
# unmark to use this option

# Create array to select the cluster
     
    # Getting Cluster info   
    $Cluster = Get-Cluster  
    $countCL = 0   
    Write-Output " "  
    Write-Output "Clusters: "  
    Write-Output " "  
    foreach($oC in $Cluster){   
        Write-Output "[$countCL] $oc"  
        $countCL = $countCL+1  
        }  
	Write-Output " "  	
    $choice = Read-Host "On which cluster do you want to set NTP ?" 
    $cluster = get-cluster $cluster[$choice] 

	Write-Output "$cluster `n`n" 
	

$esxHosts = Get-Cluster $cluster | Get-VMHost


<#
#Folder option: select hosts based on folder
# unmark to use this option


#Prompt for ESXi folder 
Get-folder
$folder = read-host " what is the folder name where hosts are located "
$esxHosts = Get-folder $folder | Get-VMHost

#>



#Prompt for NTP Servers

$ntpNew1 = read-host "Enter new NTP Server One"
$ntpNew2 = read-host "Enter new NTP Server Two"

foreach ($esx in $esxHosts) {

	Write-Host "..................................................................................." -ForegroundColor DarkGray
   
	#Remove existing NTP servers
	#$allNTPList = Get-VMHostNtpServer -VMHost $esx
	#Remove-VMHostNtpServer -VMHost $esx -NtpServer $allNTPList -Confirm:$false | out-null 
	#Write-Host "All NTP Servers from $esxHost have been removed"  -ForegroundColor DarkYellow
	#Write-Host ""
  
  	#Remove existing NTP servers, ignore if previous value is NULL
	$allNTPList = Get-VMHostNtpServer -VMHost $esx
	Remove-VMHostNtpServer -VMHost $esx -NtpServer $allNTPList -Confirm:$false -ErrorAction SilentlyContinue	
	
	#Add new NTP servers  
	Write-Host "Add new NTP Servers on $esx" -ForegroundColor DarkYellow
	Add-VMHostNTPServer -NtpServer $ntpNew1 , $ntpNew2 -VMHost $esx -Confirm:$false

	#Set ntpd service policy to on
	Write-Host "Configuring NTP Client Policy on $esx" -ForegroundColor DarkYellow
	Get-VMHostService -VMHost $esx | where{$_.Key -eq "ntpd"} | Set-VMHostService -policy "on" -Confirm:$false

	#Restart ntpd service
	Write-Host "Restarting NTP Client on $esx" -ForegroundColor DarkYellow
	Get-VMHostService -VMHost $esx | where{$_.Key -eq "ntpd"} | Restart-VMHostService -Confirm:$false
	

}

Write-Host "...................................................................................`n " -ForegroundColor DarkGray
Write-Host "Done!" `n -ForegroundColor Yellow



#Print output of ntp setting
Write-Host "New ntp settings"  -ForegroundColor DarkYellow
Get-Cluster $cluster | Get-VMHost | Sort Name | Select Name, @{N="NTP";E={Get-VMHostNtpServer $_}} | ft

#Print output of current time
Write-Host "Current time" -ForegroundColor DarkYellow

Get-Cluster $cluster | Get-VMHost | Sort Name | Select Name, Timezone, `
   @{N="CurrentTime";E={(Get-View $_.ExtensionData.ConfigManager.DateTimeSystem) | Foreach {$_.QueryDateTime().ToLocalTime()}}}, `
   @{N="ServiceRunning";E={(Get-VmHostService -VMHost $_ |Where-Object {$_.key-eq "ntpd"}).Running}} `
   | Format-Table -AutoSize
   
   
