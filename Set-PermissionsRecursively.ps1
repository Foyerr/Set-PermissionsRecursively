# Define the directory path you want to apply permissions to
$directoryPath = "W:\"

# Define the administrators group
$administratorsGroup = "BUILTIN\Administrators"

# Define the output file path for errors
$errorLogFile = "C:\temp\ErrorLog.txt"

function Set-PermissionsRecursively {
    param (
        [string]$path,
        [string]$group
    )
    
    try {
   
        # Enumerate files and subdirectories separately to avoid loading all at once
        $files = Get-ChildItem -File -Force -Path $path
        $subdirectories = Get-ChildItem -Directory -Force -Path $path
        
        
        # Recursively apply permissions to subdirectories
        foreach ($subdirectory in ($subdirectories+$path)) {
            # Apply permissions to the current directory
            $acl = Get-Acl -Path $path
            if("$group" -notin (($acl).Access | select IdentityReference)){
                $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($group, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
                $acl.AddAccessRule($rule)
                Set-Acl -Path $path -AclObject $acl
            }
            Set-PermissionsRecursively -path $subdirectory.fullname -group $group
        }
        foreach($file in $files){
            # Apply permissions to the current directory
            $acl = Get-Acl -Path $file.FullName
            if("$group" -notin (($acl).Access | select IdentityReference)){
                $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($group, "FullControl", "None", "None", "Allow")
                $acl.AddAccessRule($rule)
                Set-Acl -Path $file.FullName -AclObject $acl
            }
        }

        return 
    }
    catch {
        # Log any errors to the error log file
        $_.Exception.Message + "$path $file" | Out-File -Append -FilePath $errorLogFile
    }
}
# Call the function to set permissions recursively
Set-PermissionsRecursively -path $directoryPath -group $administratorsGroup
