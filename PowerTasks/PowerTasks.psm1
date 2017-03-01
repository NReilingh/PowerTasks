function Get-RequiredPackagePath($packageId, $path) {
	$package = Get-PackageInfo $packageId $path
	if (!$package.Exists) {
		throw "$packageId is required in $path, but it is not installed. Please install $packageId in $path"
	}
	return $package.Path
}

function Remove-Directory($path) {
	Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
}

function Use-PowerTasks([string[]] $packageIdPatterns) {
	$packageIdPatterns = @("PowerTasks.Plugins.*") + $packageIdPatterns
	$packageIdPatterns |
		% { Get-PackageNames $_ . } | Select -Unique |
		% {	(Get-PackageInfo $_ .) } | Where { $_.Exists } |
		% {	Get-ChildItem "$($_.Path)\scripts\*.ps1" } |
		% { . $_ }
}

function Get-PackageNames($pattern, $path = ".") {
	if (!(Test-Path $path\packages.config)) {
		return @()
	}
	[xml]$packagesXml = Get-Content $path\packages.config
	return $packagesXml.packages.package | Where { $_.id -like $pattern } | Select -ExpandProperty id
}

function Get-PackageInfo($packageId, $path) {
	if (!(Test-Path "$path\packages.config")) {
		return New-Object PSObject -Property @{
			Exists = $false;
		}
	}
	
	[xml]$packagesXml = Get-Content "$path\packages.config"
	$package = $packagesXml.packages.package | Where { $_.id -eq $packageId }
	if (!$package) {
		return New-Object PSObject -Property @{
			Exists = $false;
		}
	}
	
	$versionComponents = $package.version.Split('.')
    [array]::Reverse($versionComponents)
		
	$numericalVersion = 0
	$modifier = 1
	
	foreach ($component in $versionComponents) {
		$numericalComponent = $component -as [int]
		if ($numericalComponent -eq $null) {
			continue
		}
		$numericalVersion = $numericalVersion + ([int]$numericalComponent * $modifier)
		$modifier = $modifier * 10
	}
	
	return New-Object PSObject -Property @{
		Exists = $true;
		Version = $package.version;
		Number = $numericalVersion;
		Id = $package.id;
		Path = "$packagesPath\$($package.id).$($package.version)"
	}
}
